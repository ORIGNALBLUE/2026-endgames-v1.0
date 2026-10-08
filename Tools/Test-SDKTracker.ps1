param(
  [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'sdk_tracker.json')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Path)) { throw "sdk_tracker.json not found: $Path" }

$data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
$required = @('checked_at','optiscaler','intel_xess','nvidia_streamline','amd_fsr','xell','amd_upscaling','amd_fg','sources')
foreach($name in $required) {
  if ($null -eq $data.$name) { throw "Missing required field: $name" }
}
foreach($name in @('optiscaler','intel_xess','nvidia_streamline','amd_fsr','xell','amd_upscaling','amd_fg')) {
  if ([string]::IsNullOrWhiteSpace([string]$data.$name)) { throw "Empty version field: $name" }
  if ([string]$data.$name -notmatch '^\d+(?:\.\d+){1,3}$') { throw "Invalid version format in ${name}: $($data.$name)" }
}
foreach($name in @('optiscaler','intel','nvidia','amd')) {
  $url = if($name -eq 'optiscaler'){ $data.sources.optiscaler } else { $data.sources.$name }
  if ([string]::IsNullOrWhiteSpace([string]$url) -or [string]$url -notmatch '^https://github\.com/') {
    throw "Invalid source URL: $name"
  }
}
[DateTime]::Parse($data.checked_at).ToUniversalTime() | Out-Null
Write-Host "SDK tracker self-test passed: $Path"
