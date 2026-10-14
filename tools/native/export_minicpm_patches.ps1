param(
  [string]$SourceDirectory = 'C:/Users/Public/siqi-temp/minicpm-les-source',
  [string]$OutputDirectory = "$PSScriptRoot/patches"
)
$ErrorActionPreference = 'Stop'
$revision = '0b74404c9b3dfe2c6b11aebe0dd58fc23f133ee2'
$source = [IO.Path]::GetFullPath($SourceDirectory)
$baseline = Join-Path ([IO.Path]::GetTempPath()) ('siqi-patch-baseline-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($baseline) | Out-Null
$encoding = New-Object Text.UTF8Encoding($false)
$definitions = [ordered]@{
  'android-les-io.patch' = @('src/llama-moe-slot.cpp')
  'cpu-expert-slots.patch' = @('src/llama-model.cpp', 'ggml/src/ggml-cpu/ggml-cpu.cpp')
  'android-cooperative-barrier.patch' = @('ggml/src/ggml-cpu/ggml-cpu.c')
  'vulkan-driver-failure.patch' = @('ggml/src/ggml-vulkan/ggml-vulkan.cpp')
}
function Blob-Hash([byte[]]$bytes) {
  $prefix = [Text.Encoding]::ASCII.GetBytes("blob $($bytes.Length)`0")
  $blob = New-Object byte[] ($prefix.Length + $bytes.Length)
  [Array]::Copy($prefix, 0, $blob, 0, $prefix.Length)
  [Array]::Copy($bytes, 0, $blob, $prefix.Length, $bytes.Length)
  $sha = [Security.Cryptography.SHA1]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash($blob))).Replace('-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
$tree = Invoke-RestMethod "https://api.github.com/repos/OpenBMB/llama.cpp-omni/git/trees/$revision`?recursive=1" -TimeoutSec 45
if ($tree.truncated) { throw 'Refusing truncated source tree.' }
foreach ($patchName in $definitions.Keys) {
  $sections = @()
  foreach ($relative in $definitions[$patchName]) {
    $entry = @($tree.tree | Where-Object {$_.path -eq $relative -and $_.type -eq 'blob'})
    if ($entry.Count -ne 1) { throw "Missing upstream source: $relative" }
    $file = Join-Path $baseline $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file)) | Out-Null
    & curl.exe --fail --location --silent --show-error --connect-timeout 8 --max-time 20 --output $file "https://raw.githubusercontent.com/OpenBMB/llama.cpp-omni/$revision/$relative"
    if ($LASTEXITCODE -ne 0 -or (Blob-Hash ([IO.File]::ReadAllBytes($file))) -ne $entry[0].sha) {
      $blob = Invoke-RestMethod "https://api.github.com/repos/OpenBMB/llama.cpp-omni/git/blobs/$($entry[0].sha)" -TimeoutSec 30
      if ($blob.encoding -ne 'base64') { throw 'Unsupported Git blob encoding.' }
      $bytes = [Convert]::FromBase64String($blob.content)
      if ((Blob-Hash $bytes) -ne $entry[0].sha) { throw "Baseline hash mismatch: $relative" }
      [IO.File]::WriteAllBytes($file, $bytes)
    }
    $modified = Join-Path $source $relative
    $lines = & git -c core.autocrlf=false diff --no-index --no-prefix -- $file $modified
    if ($LASTEXITCODE -notin @(0,1)) { throw 'Diff generation failed.' }
    # A mechanical export of existing edits; normalize only diff file labels.
    $normalized = @($lines | ForEach-Object {
      if ($_ -like 'diff --git *') { "diff --git a/$relative b/$relative" }
      elseif ($_ -like '--- *') { "--- a/$relative" }
      elseif ($_ -like '+++ *') { "+++ b/$relative" }
      else { $_ }
    }) -join "`n"
    $sections += $normalized
  }
  [IO.File]::WriteAllText((Join-Path $OutputDirectory $patchName), ($sections -join "`n") + "`n", $encoding)
  Push-Location $baseline
  try {
    & git apply --check (Join-Path $OutputDirectory $patchName)
    if ($LASTEXITCODE -ne 0) { throw "Baseline patch validation failed: $patchName" }
  } finally { Pop-Location }
  Push-Location $source
  try {
    & git apply --reverse --check (Join-Path $OutputDirectory $patchName)
    if ($LASTEXITCODE -ne 0) { throw "Reverse patch validation failed: $patchName" }
  } finally { Pop-Location }
  Write-Output "Exported and checked: $patchName"
}
Write-Output "Pinned pristine baseline retained for review: $baseline"
