param(
  [string]$OutputDirectory = 'C:/Users/Public/siqi-temp/minicpm-les-source',
  [string]$SeedDirectory = 'C:/Users/Public/siqi-temp/llama-b10333-source/llama.cpp-b10333',
  [switch]$CpuRuntimeOnly,
  # Fetch only the pinned Vulkan backend; preserve any local CPU/LES patches.
  [switch]$VulkanSourcesOnly
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$revision = '0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2'
$apiRoot = 'https://api.github.com/repos/OpenBMB/llama.cpp-omni'
$rawRoot = "https://raw.githubusercontent.com/OpenBMB/llama.cpp-omni/$revision"
$targetRoot = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

function Get-BlobHash([byte[]]$Bytes) {
  $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
  $sha = [Security.Cryptography.SHA1]::Create()
  try {
    $all = New-Object byte[] ($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $all, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $all, $header.Length, $Bytes.Length)
    return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace('-', '').ToLowerInvariant()
  } finally { $sha.Dispose() }
}

function Get-Tree([string]$Sha, [bool]$Recursive = $false) {
  $query = if ($Recursive) { '?recursive=1' } else { '' }
  $result = Invoke-RestMethod "$apiRoot/git/trees/$Sha$query" -TimeoutSec 45
  if ($result.truncated) { throw 'Refusing a truncated source tree.' }
  return $result.tree
}

function Get-VerifiedSource([string]$RelativePath, [string]$ExpectedHash) {
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    $response = $null
    $buffer = $null
    $downloadTemp = $null
    try {
      if ($attempt -eq 2) {
        # Some raw-host paths can stall even when the Git data API works.
        # Its base64 blob is checked against the same pinned Git SHA below.
        $blob = Invoke-RestMethod "$apiRoot/git/blobs/$ExpectedHash" -TimeoutSec 20
        if ($blob.encoding -ne 'base64') { throw 'Unsupported Git blob encoding.' }
        $bytes = [Convert]::FromBase64String($blob.content)
        if ((Get-BlobHash $bytes) -ne $ExpectedHash) {
          throw "Source hash mismatch: $RelativePath"
        }
        return ,$bytes
      }
      if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        # Download bytes to a private temporary file: PowerShell's pipeline
        # must not decode a binary Git blob into text. curl also avoids stalled
        # HttpWebRequest pooled connections seen with this host on Windows.
        $downloadTemp = [IO.Path]::Combine($targetRoot, ".source-$([Guid]::NewGuid().ToString('N')).part")
        & curl.exe --fail --location --silent --show-error --connect-timeout 8 --max-time 20 --output $downloadTemp "$rawRoot/$RelativePath"
        if ($LASTEXITCODE -ne 0) { throw "Source download failed: $RelativePath" }
        $bytes = [IO.File]::ReadAllBytes($downloadTemp)
      } else {
        $request = [Net.HttpWebRequest]::Create("$rawRoot/$RelativePath")
        $request.Timeout = 20000
        $request.ReadWriteTimeout = 20000
        $request.KeepAlive = $false
        $request.UserAgent = 'SIQI-native-source-preparation'
        $response = $request.GetResponse()
        $buffer = New-Object IO.MemoryStream
        $response.GetResponseStream().CopyTo($buffer)
        $bytes = $buffer.ToArray()
      }
      if ((Get-BlobHash $bytes) -ne $ExpectedHash) {
        throw "Source hash mismatch: $RelativePath"
      }
      return ,$bytes
    } catch {
      if ($attempt -eq 3) { throw }
      Write-Warning "Retrying verified source $RelativePath ($attempt/3): $($_.Exception.GetType().Name)"
    } finally {
      if ($null -ne $buffer) { $buffer.Dispose() }
      if ($null -ne $response) { $response.Dispose() }
      if ($null -ne $downloadTemp -and [IO.File]::Exists($downloadTemp)) {
        [IO.File]::Delete($downloadTemp)
      }
    }
  }
}

$rootEntries = @(Get-Tree $revision)
if ($CpuRuntimeOnly -and $VulkanSourcesOnly) { throw 'Choose CPU preparation or Vulkan-only restoration, not both.' }
$files = @($rootEntries | Where-Object {
  $_.type -eq 'blob' -and (!$CpuRuntimeOnly -or $_.path -in @('CMakeLists.txt', 'LICENSE', 'AUTHORS'))
})
if ($VulkanSourcesOnly) { $files = @() }
$subtrees = if ($VulkanSourcesOnly) {
  @('ggml')
} elseif ($CpuRuntimeOnly) {
  @('src', 'include', 'ggml', 'cmake', 'vendor', 'tools', 'gguf-py')
} else {
  @('src', 'include', 'ggml', 'common', 'cmake', 'vendor', 'tools')
}
foreach ($name in $subtrees) {
  $entry = $rootEntries | Where-Object { $_.path -eq $name }
  if (!$entry) { throw "Missing upstream source subtree: $name" }
  foreach ($file in @(Get-Tree $entry.sha $true)) {
    if ($file.type -ne 'blob') { continue }
    if ($VulkanSourcesOnly -and $file.path -notmatch '^src/ggml-vulkan/') { continue }
    if ($CpuRuntimeOnly) {
      if ($name -eq 'tools' -and !$file.path.StartsWith('moe/')) { continue }
      if ($name -eq 'ggml' -and $file.path -match '^src/ggml-[^/]+/' -and
          $file.path -notmatch '^src/ggml-cpu/') { continue }
    }
    $files += [PSCustomObject]@{ path = "$name/$($file.path)"; sha = $file.sha; type = 'blob' }
  }
}
$downloaded = 0
$reused = 0
foreach ($file in $files) {
  $path = [IO.Path]::GetFullPath([IO.Path]::Combine($targetRoot, $file.path))
  if (!$path.StartsWith($targetRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe upstream path: $($file.path)"
  }
  if ([IO.File]::Exists($path) -and (Get-BlobHash ([IO.File]::ReadAllBytes($path))) -eq $file.sha) {
    $reused++
    continue
  }
  if ([IO.File]::Exists($path)) {
    throw "Refusing to overwrite a changed source file: $path. Use a fresh output directory to restore the pinned baseline."
  }
  $seed = [IO.Path]::Combine($SeedDirectory, $file.path)
  $bytes = if ([IO.File]::Exists($seed)) { [IO.File]::ReadAllBytes($seed) } else { $null }
  if ($null -ne $bytes -and (Get-BlobHash $bytes) -eq $file.sha) {
    $reused++
  } else {
    $bytes = Get-VerifiedSource $file.path $file.sha
    $downloaded++
    Write-Output "Downloaded verified source: $($file.path)"
  }
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
  # These are byte-exact third-party downloads, never generated source edits.
  [IO.File]::WriteAllBytes($path, $bytes)
}
Write-Output "Pinned source ready: $revision; downloaded=$downloaded; reused=$reused; cpuRuntimeOnly=$CpuRuntimeOnly; vulkanSourcesOnly=$VulkanSourcesOnly"
