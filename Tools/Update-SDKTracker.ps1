param(
  [string]$OutputPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'sdk_tracker.json'),
  [switch]$Quiet
)
$ErrorActionPreference='Stop'
$headers=@{'User-Agent'='AetherScaler-Bridge'}
function Latest([string]$repo){
  $r=Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$repo/releases/latest"
  return [pscustomobject]@{tag=[string]$r.tag_name;name=[string]$r.name;published=[string]$r.published_at;body=[string]$r.body;url=[string]$r.html_url}
}
$op=Latest 'optiscaler/OptiScaler'
$intel=Latest 'intel/xess'
$nv=Latest 'NVIDIA-RTX/Streamline'
$amd=Latest 'GPUOpen-LibrariesAndSDKs/FidelityFX-SDK'
$xell=''
if($intel.body -match 'XeLL\s+(?:to\s+)?([0-9]+(?:\.[0-9]+){2,3})'){$xell=$Matches[1]}
$up='';$fg=''
if($amd.body -match 'Upscaling\s+([0-9]+(?:\.[0-9]+){2,3})'){$up=$Matches[1]}
if($amd.body -match 'Frame Generation\s+([0-9]+(?:\.[0-9]+){2,3})'){$fg=$Matches[1]}
$o=[ordered]@{
  checked_at=(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  optiscaler=$op.tag.TrimStart('v')
  intel_xess=$intel.tag.TrimStart('v')
  nvidia_streamline=$nv.tag.TrimStart('v')
  amd_fsr=$amd.tag.TrimStart('v')
  xell=$xell
  amd_upscaling=$up
  amd_fg=$fg
  sources=[ordered]@{
    optiscaler=$op.url
    intel=$intel.url
    nvidia=$nv.url
    amd=$amd.url
  }
}
$o|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $OutputPath -Encoding UTF8
if(!$Quiet){$o|Format-List}
