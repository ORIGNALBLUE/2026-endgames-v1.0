param(
  [string]$GameFolder = '',
  [string]$OutputDirectory = '',
  [switch]$OpenFolder
)
$ErrorActionPreference='SilentlyContinue'
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if(!$OutputDirectory){$OutputDirectory=Join-Path $Root 'SupportBundles'}
New-Item -ItemType Directory -Force -Path $OutputDirectory|Out-Null
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$work=Join-Path $env:TEMP "AetherScalerSupport-$stamp"
New-Item -ItemType Directory -Force -Path $work|Out-Null

function Redact([string]$s){
  if($null -eq $s){return ''}
  if($env:USERNAME){$s=$s -replace [regex]::Escape($env:USERNAME),'<USER>'}
  if($env:USERPROFILE){$s=$s -replace [regex]::Escape($env:USERPROFILE),'<USERPROFILE>'}
  if($GameFolder){$s=$s -replace [regex]::Escape($GameFolder),'<GAME_FOLDER>'}
  return $s
}
function Copy-TextSanitized([string]$src,[string]$dst){
  if(Test-Path -LiteralPath $src){
    $t=Get-Content -LiteralPath $src -Raw -ErrorAction SilentlyContinue
    if($null -ne $t){Set-Content -LiteralPath $dst -Value (Redact $t) -Encoding UTF8}
  }
}
function HashRow([string]$p){
  if(!(Test-Path -LiteralPath $p)){return $null}
  $i=Get-Item -LiteralPath $p
  $v=$i.VersionInfo.FileVersion
  $h=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  return [pscustomobject]@{name=$i.Name;version=$v;size=$i.Length;sha256=$h}
}

$os=Get-CimInstance Win32_OperatingSystem
$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
$gpu=Get-CimInstance Win32_VideoController|ForEach-Object{[pscustomobject]@{name=$_.Name;driver=$_.DriverVersion;vram=$_.AdapterRAM;status=$_.Status}}
$sys=[ordered]@{
  generated_at=(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  aetherscaler='1.1.1-diagnostics'
  os=[ordered]@{caption=$os.Caption;version=$os.Version;build=$os.BuildNumber;architecture=$os.OSArchitecture;locale=$os.Locale}
  powershell=$PSVersionTable.PSVersion.ToString()
  cpu=[ordered]@{name=$cpu.Name;cores=$cpu.NumberOfCores;logical=$cpu.NumberOfLogicalProcessors}
  gpu=$gpu
  game_folder=$(if($GameFolder){'<GAME_FOLDER>'}else{'not selected'})
}
$sys|ConvertTo-Json -Depth 6|Set-Content (Join-Path $work 'system.json') -Encoding UTF8

foreach($n in @('sdk_tracker.json','sdk_manifest.json','settings.json')){Copy-TextSanitized (Join-Path $Root $n) (Join-Path $work $n)}
$logsOut=Join-Path $work 'logs';New-Item -ItemType Directory -Force -Path $logsOut|Out-Null
$rootLogs=Join-Path $Root 'Logs'
if(Test-Path $rootLogs){Get-ChildItem $rootLogs -File|Sort-Object LastWriteTime -Descending|Select-Object -First 5|ForEach-Object{Copy-TextSanitized $_.FullName (Join-Path $logsOut $_.Name)}}
if($GameFolder -and (Test-Path -LiteralPath $GameFolder)){
  foreach($n in @('OptiScaler.log','fakenvapi.log','dlssg_to_fsr3.log','OptiScaler.ini')){Copy-TextSanitized (Join-Path $GameFolder $n) (Join-Path $logsOut $n)}
  $runtimeNames=@('dxgi.dll','winmm.dll','version.dll','dbghelp.dll','d3d12.dll','wininet.dll','winhttp.dll','OptiScaler.asi','libxess.dll','libxess_dx11.dll','libxess_fg.dll','libxell.dll','fakenvapi.dll','dlssg_to_fsr3_amd_is_better.dll','amd_fidelityfx_dx12.dll','amd_fidelityfx_upscaler_dx12.dll','amd_fidelityfx_framegeneration_dx12.dll','amd_fidelityfx_vk.dll')
  $rows=@();foreach($n in $runtimeNames){$r=HashRow (Join-Path $GameFolder $n);if($r){$rows+=$r}}
  $rows|ConvertTo-Json -Depth 4|Set-Content (Join-Path $work 'runtime_hashes.json') -Encoding UTF8
}
$readme=@'
AetherScaler Support Bundle
===========================
This archive is generated locally and is NOT uploaded automatically.
User name, user profile path and selected game folder are redacted from copied text logs.
It may contain AetherScaler/OptiScaler configuration values, DLL versions/hashes and basic OS/GPU information.
Review the archive before sharing it publicly.
'@
$readme|Set-Content (Join-Path $work 'README_PRIVACY.txt') -Encoding UTF8
$zip=Join-Path $OutputDirectory "AetherScaler_Support_$stamp.zip"
Compress-Archive -Path (Join-Path $work '*') -DestinationPath $zip -Force
Remove-Item $work -Recurse -Force
Write-Output $zip
if($OpenFolder){Start-Process explorer.exe -ArgumentList "/select,`"$zip`""}
