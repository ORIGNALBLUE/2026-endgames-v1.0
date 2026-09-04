$ErrorActionPreference='Stop'
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Dst=Join-Path $Root 'SDK_Archives';New-Item -ItemType Directory -Force -Path $Dst|Out-Null
$headers=@{'User-Agent'='AetherScaler-Bridge'}
$repos=@(
  @{Key='Intel';Repo='intel/xess'},
  @{Key='NVIDIA';Repo='NVIDIA-RTX/Streamline'},
  @{Key='AMD';Repo='GPUOpen-LibrariesAndSDKs/FidelityFX-SDK'}
)
foreach($x in $repos){
  $r=Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$($x.Repo)/releases/latest"
  $asset=$r.assets|Where-Object {$_.name -match '\.zip$'}|Select-Object -First 1
  if(!$asset){Write-Warning "No ZIP asset for $($x.Repo)";continue}
  $out=Join-Path $Dst $asset.name
  Write-Host "[$($x.Key)] $($r.tag_name) -> $($asset.name)"
  Invoke-WebRequest -Headers $headers -Uri $asset.browser_download_url -OutFile $out
}
Write-Host "Saved to $Dst"
