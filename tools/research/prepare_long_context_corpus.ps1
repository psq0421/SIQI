param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$destination = [IO.Path]::GetFullPath($OutputDirectory)
if ([IO.Directory]::Exists($destination)) { throw 'Refusing to overwrite an evidence corpus.' }
[IO.Directory]::CreateDirectory($destination) | Out-Null
$encoding = New-Object Text.UTF8Encoding($false)
$relativePaths = @('README.md','README_EN.md') + @(& rg --files docs lib -g '*.md' -g '*.dart' -g '!app_localizations*.dart' -g '!*.g.dart')
$records = @()
$text = New-Object Text.StringBuilder
foreach ($relative in $relativePaths) {
  $path = [IO.Path]::GetFullPath((Join-Path $repository $relative))
  if (!$path.StartsWith($repository + [IO.Path]::DirectorySeparatorChar)) { throw 'Corpus path outside repository.' }
  [void]$text.AppendLine("`n===== $relative =====")
  [void]$text.AppendLine([IO.File]::ReadAllText($path, $encoding))
  $records += @{path=$relative;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$corpus = Join-Path $destination 'siqi-public-repository.txt'
[IO.File]::WriteAllText($corpus, $text.ToString(), $encoding)
[IO.File]::WriteAllText((Join-Path $destination 'corpus-manifest.json'), ([ordered]@{
  schema=1; scope='Non-repeated repository code and documentation; input/quality tests are separate';
  license='MIT (SIQI source), referenced upstream material retains its own license';
  corpusSha256=(Get-FileHash -LiteralPath $corpus -Algorithm SHA256).Hash.ToLowerInvariant();
  sources=$records
} | ConvertTo-Json -Depth 5), $encoding)
Write-Output "Prepared public repository corpus: $corpus"
