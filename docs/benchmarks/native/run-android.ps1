param(
  [string]$Serial = '57e2a7e4',
  [string]$Model = '/sdcard/Android/data/com.psq.siqi/files/Models/local-gpt-oss-20b-q4km/local-gpt-oss-20b-q4km.gguf',
  [int]$Threads = 4,
  [int]$Tokens = 256
)

$ErrorActionPreference = 'Stop'
$adb = 'C:\Users\彭思齐\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$remote = '/data/local/tmp/siqi-repack'
$command = "SIQI_REPACK_CACHE_DIR=$remote $remote/siqi-bench $Model $remote $Threads 0 $Tokens q8 1 1"
& $adb -s $Serial shell $command 2>&1 | Tee-Object -FilePath "build/native-$Threads-$Tokens.log"

