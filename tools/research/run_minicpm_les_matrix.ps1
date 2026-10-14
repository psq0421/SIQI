param(
  [string]$Adb = 'C:/Users/Public/android-sdk/platform-tools/adb.exe',
  [string]$DeviceSerial = '57e2a7e4',
  [string]$PackedDirectory = '/sdcard/Android/data/com.psq.siqi/cache/siqi-les-bench/packed',
  [string]$Probe = '/data/local/tmp/siqi-minicpm-cpu-probe',
  [string]$OutputDirectory = '',
  [string]$PromptFile = '',
  [int]$RepeatPrefetchDepth = 0,
  [switch]$AdaptiveThreads,
  [ValidateRange(-1,100)][int]$ThreadPoll = -1,
  [ValidateRange(1,64)][int]$LongMicroBatchSize = 16,
  [ValidateRange(128,4096)][int]$LongSlotBank = 256,
  [int[]]$LongTokenCounts = @(1024,4096),
  [ValidateSet('smoke', 'sweep', 'long', 'hybrid', 'tune', 'adreno', 'mapped', 'repeat', 'ab', 'real-long', 'mapped-tune', 'prefill-tune')][string]$Suite = 'smoke',
  [int]$TimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
if ($DeviceSerial -notmatch '^[A-Za-z0-9._:-]+$') { throw 'Invalid serial.' }
foreach ($path in @($PackedDirectory, $Probe) + @($PromptFile | Where-Object {$_})) {
  if ($path -notmatch '^/[A-Za-z0-9_./-]+$' -or $path.Contains('..')) { throw 'Unsafe device path.' }
}
if ($TimeoutSeconds -lt 10 -or $TimeoutSeconds -gt 7200) { throw 'Invalid timeout.' }
if (!$OutputDirectory) {
  $OutputDirectory = Join-Path $env:TEMP ('siqi-les-' + [Guid]::NewGuid().ToString('N'))
}
$destination = [IO.Path]::GetFullPath($OutputDirectory)
if ([IO.Directory]::Exists($destination)) { throw 'Refusing to overwrite an existing evidence directory.' }
[IO.Directory]::CreateDirectory($destination) | Out-Null
$encoding = New-Object Text.UTF8Encoding($false)

function Run-Adb([string]$RemoteCommand, [string]$LogFile) {
  $info = New-Object Diagnostics.ProcessStartInfo
  $info.FileName = $Adb
  $info.Arguments = "-s $DeviceSerial shell `"$RemoteCommand`""
  $info.UseShellExecute = $false
  $info.CreateNoWindow = $true
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $info.StandardOutputEncoding = $encoding
  $info.StandardErrorEncoding = $encoding
  $process = New-Object Diagnostics.Process
  $process.StartInfo = $info
  $logStream = $null
  try {
    if (!$process.Start()) { throw 'Failed to start adb.' }
    # Stream generated UTF-8 evidence to disk immediately. A long prefill no
    # longer hides all progress until process exit; a crash retains its prefix.
    $logStream = New-Object IO.FileStream($LogFile, [IO.FileMode]::CreateNew,
      [IO.FileAccess]::Write, [IO.FileShare]::Read, 1, [IO.FileOptions]::Asynchronous)
    $stdout = $process.StandardOutput.BaseStream.CopyToAsync($logStream)
    $stderr = $process.StandardError.ReadToEndAsync()
    # Device-side timeout terminates only this probe. No app force-stop, root,
    # drop_caches, model removal, or unrelated process termination occurs.
    if (!$process.WaitForExit(($TimeoutSeconds + 20) * 1000)) {
      $process.Kill()
      $process.WaitForExit()
      $stdout.GetAwaiter().GetResult()
      throw 'ADB transport timeout; device result is inconclusive.'
    }
    $stdout.GetAwaiter().GetResult()
    $logStream.Dispose()
    $logStream = $null
    $output = [IO.File]::ReadAllText($LogFile, $encoding)
    $errors = $stderr.GetAwaiter().GetResult()
    [IO.File]::AppendAllText($LogFile, $errors, $encoding)
    return @{ exitCode = $process.ExitCode; output = $output; errors = $errors }
  } finally {
    if ($null -ne $logStream) { $logStream.Dispose() }
    $process.Dispose()
  }
}

$profiles = switch ($Suite) {
  'smoke' {
    @(
      @{ id='baseline-io4'; io=4; threads=4; window=64; depth=8; output=32; warmup=8 },
      @{ id='io8'; io=8; threads=4; window=64; depth=8; output=32; warmup=8 },
      @{ id='io8-no-prefetch'; io=8; threads=4; window=64; depth=0; output=32; warmup=8 }
    )
  }
  'sweep' {
    @(
      @{ id='io1'; io=1; threads=4; window=64; depth=0 },
      @{ id='io2'; io=2; threads=4; window=64; depth=0 },
      @{ id='io4'; io=4; threads=4; window=64; depth=0 },
      @{ id='io8'; io=8; threads=4; window=64; depth=0 },
      @{ id='io8-pf4'; io=8; threads=4; window=64; depth=4 },
      @{ id='io8-pf8'; io=8; threads=4; window=64; depth=8 },
      @{ id='io8-w128'; io=8; threads=4; window=128; depth=0 },
      @{ id='io8-w32'; io=8; threads=4; window=32; depth=0 },
      @{ id='threads6'; io=8; threads=6; window=64; depth=0 },
      @{ id='threads8'; io=8; threads=8; window=64; depth=0 }
    )
  }
  'long' {
    @(1024, 4096, 16384, 32768, 131008) | ForEach-Object {
      @{ id="populated-$_"; io=8; threads=4; window=64; depth=0; prompt=$_;
        context=if ($_ -gt 32768) {131072} else {[Math]::Max(2048, $_ + 256)};
        output=16; warmup=0 }
    }
  }
  'hybrid' {
    @(0, 4, 12, 40, 41) | ForEach-Object {
      @{ id="gpu-layers-$_"; io=4; threads=4; window=64; depth=8;
        gpu=$_; output=32; warmup=8 }
    }
  }
  'adreno' {
    @(
      @{ id='adreno-compatible-4'; io=4; threads=4; window=64; depth=0;
        gpu=4; output=32; warmup=8; cpuQ6=1; mapped=1 }
    )
  }
  'mapped' {
    @(
      @{ id='mapped-w64'; io=4; threads=4; window=64; depth=0; output=64; warmup=8; mapped=1 },
      @{ id='mapped-w96'; io=4; threads=4; window=96; depth=0; output=64; warmup=8; mapped=1 },
      @{ id='mapped-w128'; io=4; threads=4; window=128; depth=0; output=64; warmup=8; mapped=1 }
    )
  }
  'repeat' {
    @(1..5) | ForEach-Object {
      @{ id="mapped-w64-repeat-$_"; io=4; threads=4; window=64; depth=$RepeatPrefetchDepth; output=64; warmup=8; mapped=1 }
    }
  }
  'mapped-tune' {
    @(
      @{ id='mapped-big-cores'; io=4; threads=4; window=64; depth=0; output=64; warmup=8; mapped=1; mask=240 },
      @{ id='mapped-split-cores'; io=4; threads=4; window=64; depth=0; output=64; warmup=8; mapped=1; mask=240; ioMask=15 },
      @{ id='mapped-pf4'; io=4; threads=4; window=64; depth=4; output=64; warmup=8; mapped=1 },
      @{ id='mapped-pf8'; io=4; threads=4; window=64; depth=8; output=64; warmup=8; mapped=1 }
    )
  }
  'ab' {
    @(0,1,1,0) | ForEach-Object -Begin {$siqiIndex=0} -Process {
      $siqiIndex++
      @{ id="mapped-ab-$siqiIndex-$_"; io=4; threads=4; window=64; depth=0; output=64; warmup=8; mapped=$_ }
    }
  }
  'real-long' {
    if (!$PromptFile) { throw 'real-long requires a public document file on the device.' }
    $LongTokenCounts | ForEach-Object {
      @{ id="document-populated-$_"; io=4; threads=4; window=64;
        prompt=$_; context=[Math]::Min(131072,[Math]::Max(2048,$_+256)); output=64; warmup=8; mapped=1; depth=4;
        ubatch=$LongMicroBatchSize; bank=$LongSlotBank }
    }
  }
  'prefill-tune' {
    if (!$PromptFile) { throw 'prefill-tune requires a public document file.' }
    @(
      @{ id='prefill-ub16-bank128'; io=4; threads=4; window=64; depth=4; output=64; warmup=8; mapped=1; prompt=256; ubatch=16; bank=128 },
      @{ id='prefill-ub32-bank256'; io=4; threads=4; window=64; depth=4; output=64; warmup=8; mapped=1; prompt=256; ubatch=32; bank=256 },
      @{ id='adaptive-poll0'; io=4; threads=4; window=64; depth=4; output=64; warmup=8; mapped=1; poll=0; adaptive=1; prompt=256 },
      @{ id='adaptive-big-poll0'; io=4; threads=4; window=64; depth=4; output=64; warmup=8; mapped=1; poll=0; adaptive=1; mask=240; prompt=256 }
    )
  }
  'tune' {
    @(
      @{ id='big-cores'; io=4; threads=4; window=64; depth=8; mask=240; output=64; warmup=8 },
      @{ id='w96'; io=4; threads=4; window=96; depth=8; output=64; warmup=8 },
      @{ id='w128'; io=4; threads=4; window=128; depth=8; output=64; warmup=8 },
      @{ id='w64-pf4'; io=4; threads=4; window=64; depth=4; output=64; warmup=8 },
      @{ id='w64-pf0'; io=4; threads=4; window=64; depth=0; output=64; warmup=8 }
    )
  }
}

$journal = Join-Path $destination 'results.jsonl'
$device = Run-Adb 'getprop ro.product.model; getprop ro.soc.model; getprop ro.build.version.sdk; cat /proc/meminfo; cat /sys/devices/system/cpu/online' (Join-Path $destination 'device.txt')
$records = @()
foreach ($profile in $profiles) {
  $outputTokens = if ($profile.ContainsKey('output')) {$profile.output} else {16}
  $warmup = if ($profile.ContainsKey('warmup')) {$profile.warmup} else {4}
  $context = if ($profile.ContainsKey('context')) {$profile.context} else {2048}
  $prompt = if ($profile.ContainsKey('prompt')) {$profile.prompt} else {0}
  $gpu = if ($profile.ContainsKey('gpu')) {$profile.gpu} else {0}
  $mask = if ($profile.ContainsKey('mask')) {$profile.mask} else {0}
  $bank = if ($profile.ContainsKey('bank')) {$profile.bank} else {128}
  $ubatch = if ($profile.ContainsKey('ubatch')) {$profile.ubatch} else {8}
  $settings = @(
    "SIQI_PROBE_OUTPUT_TOKENS=$outputTokens", "SIQI_PROBE_WARMUP_TOKENS=$warmup",
    "SIQI_PROBE_CONTEXT=$context", "SIQI_PROBE_PROMPT_TOKENS=$prompt",
    "SIQI_PROBE_THREADS=$($profile.threads)", "SIQI_PROBE_THREADS_BATCH=$($profile.threads)",
    "SIQI_PROBE_IO_THREADS=$($profile.io)", "SIQI_PROBE_DECODE_WINDOW=$($profile.window)",
    "SIQI_PROBE_PREFETCH_DEPTH=$($profile.depth)", "SIQI_PROBE_SLOT_BANK=$bank", "SIQI_PROBE_UBATCH=$ubatch",
    'SIQI_PROBE_RSS_LIMIT_BYTES=0', 'SIQI_PROBE_KV_TYPE=q4_0', 'SIQI_PROBE_FLASH_ATTN=1',
    "SIQI_PROBE_GPU_LAYERS=$gpu", "SIQI_PROBE_CPU_MASK=$mask",
    "SIQI_PROBE_PHASE=$($profile.id)"
  )
  if ($profile.ContainsKey('disableMmvq')) { $settings += 'GGML_VK_DISABLE_MMVQ=1' }
  if ($profile.ContainsKey('mapped')) { $settings += "SIQI_MOE_MMAP_SLOTS=$($profile.mapped)" }
  if ($profile.ContainsKey('cpuQ6')) { $settings += 'SIQI_VK_CPU_QUANT=1' }
  if ($profile.ContainsKey('ioMask')) { $settings += "SIQI_MOE_IO_CPU_MASK=$($profile.ioMask)" }
  if ($profile.ContainsKey('poll')) { $settings += "SIQI_PROBE_THREAD_POLL=$($profile.poll)" }
  if ($profile.ContainsKey('adaptive')) { $settings += "SIQI_PROBE_ADAPTIVE_THREADS=$($profile.adaptive)" }
  if ($AdaptiveThreads -and !$profile.ContainsKey('adaptive')) { $settings += 'SIQI_PROBE_ADAPTIVE_THREADS=1' }
  if ($ThreadPoll -ge 0 -and !$profile.ContainsKey('poll')) { $settings += "SIQI_PROBE_THREAD_POLL=$ThreadPoll" }
  if ($PromptFile) { $settings += "SIQI_PROBE_PROMPT_FILE=$PromptFile" }
  $command = "timeout -s TERM $TimeoutSeconds env $($settings -join ' ') $Probe bench $PackedDirectory/base.gguf $PackedDirectory/manifest.json"
  Write-Output "Running $($profile.id): context=$context, prompt=$prompt, output=$outputTokens"
  Run-Adb 'dumpsys thermalservice; cat /proc/meminfo' (Join-Path $destination ($profile.id + '-before.txt')) | Out-Null
  $result = Run-Adb $command (Join-Path $destination ($profile.id + '.log'))
  Run-Adb 'dumpsys thermalservice; cat /proc/meminfo' (Join-Path $destination ($profile.id + '-after.txt')) | Out-Null
  $events = @()
  foreach ($line in (($result.output + $result.errors) -split '\r?\n')) {
    if ($line.StartsWith('{')) {
      try { $events += ($line | ConvertFrom-Json) } catch { }
    }
  }
  $completed = @($events | Where-Object {$_.event -eq 'benchmark-completed'})
  $status = if ($result.exitCode -eq 0 -and $completed.Count -gt 0) {'completed'} elseif ($result.exitCode -eq 124) {'timeout'} else {'failed'}
  $record = [ordered]@{
    timestampUtc=[DateTime]::UtcNow.ToString('o'); suite=$Suite; profile=$profile;
    scope='standalone probe, not APK'; cacheState='uncontrolled, no privileged cache flush';
    exitCode=$result.exitCode; status=$status; events=$events
  }
  [IO.File]::AppendAllText($journal, ($record | ConvertTo-Json -Depth 30 -Compress) + "`n", $encoding)
  $records += $record
  if ($completed.Count -gt 0) { Write-Output ($completed[-1] | ConvertTo-Json -Depth 10 -Compress) }
  else { Write-Output "$($profile.id): $status (exit $($result.exitCode))" }
  # No automatic long sweep after a timeout: retain failure and let a developer
  # choose the next duration instead of saturating storage for hours.
  if ($Suite -in @('long','real-long') -and $status -ne 'completed') { break }
}
Write-Output "Evidence saved: $destination"
