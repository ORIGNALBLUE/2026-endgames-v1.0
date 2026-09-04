param([switch]$OpenBrowser)
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path);$dir=Join-Path $Root 'SupportBundles';$j=Get-ChildItem $dir -Filter 'PublicSummary_*.json' -File|Sort LastWriteTime -Descending|Select-Object -First 1;if(!$j){Write-Error 'No PublicSummary found. Export a support bundle first.';exit 1};$o=Get-Content $j.FullName -Raw -Encoding UTF8|ConvertFrom-Json;$md=@"
### AetherScaler Lifeline public report
- Report ID: `$($o.report_id)
- Lifeline: `$($o.lifeline_version)
- Locale: `$($o.locale)
- GPU: `$($o.gpu)
- Driver: `$($o.driver)
- VRAM bucket: `$($o.vram_bucket)
- OS: `$($o.os)
- Upscaler: `$($o.upscaler)
- Frame generation: `$($o.frame_generation)

Result / symptoms:
<!-- Please describe the game, API, FPS before/after, image issues, crashes or stutter. -->

Privacy note: this text was generated from PublicSummary only. Do not paste PrivateSupport contents publicly without reviewing them.
"@;$p=Join-Path $dir ('GitHubReport-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.md');Set-Content $p $md -Encoding UTF8;Set-Clipboard $md;Write-Output $p;if($OpenBrowser){Start-Process 'https://github.com/ORIGNALBLUE/2026-endgames-v1.0/issues/new?template=lifeline-report.yml'}
