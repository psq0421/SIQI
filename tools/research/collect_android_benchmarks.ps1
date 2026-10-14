param(
  [string]$Adb = 'C:/Users/Public/android-sdk/platform-tools/adb.exe',
  [string]$DeviceSerial = '57e2a7e4',
  [string]$OutputFile = 'C:/Users/Public/siqi-qa/beta4/device-benchmarks-before-journal-fix.jsonl'
)
$ErrorActionPreference = 'Stop'
if ($DeviceSerial -notmatch '^[A-Za-z0-9._:-]+$') { throw 'Invalid device serial.' }
$outputPath = [IO.Path]::GetFullPath($OutputFile)
if ([IO.File]::Exists($outputPath)) { throw 'Refusing to overwrite existing evidence.' }
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath)) | Out-Null
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = $Adb
$info.Arguments = "-s $DeviceSerial exec-out run-as com.psq.siqi cat files/benchmarks/beta4.jsonl"
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$process = New-Object Diagnostics.Process
$process.StartInfo = $info
$stream = $null
try {
  if (!$process.Start()) { throw 'Failed to start ADB.' }
  $stderr = $process.StandardError.ReadToEndAsync()
  $stream = [IO.File]::Open($outputPath, [IO.FileMode]::CreateNew)
  # Byte-exact capture of generated device records, not source-file editing.
  $process.StandardOutput.BaseStream.CopyTo($stream)
  $stream.Dispose()
  $stream = $null
  $process.WaitForExit()
  if ($process.ExitCode -ne 0) {
    throw "ADB could not read the benchmark journal: $($stderr.GetAwaiter().GetResult())"
  }
  Write-Output "Captured device benchmark journal: $outputPath"
  Get-FileHash -LiteralPath $outputPath -Algorithm SHA256
} finally {
  if ($null -ne $stream) { $stream.Dispose() }
  $process.Dispose()
}
