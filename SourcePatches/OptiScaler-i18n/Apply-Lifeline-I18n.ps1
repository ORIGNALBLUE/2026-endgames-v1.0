param([Parameter(Mandatory=$true)][string]$SourceRoot)
$ErrorActionPreference='Stop'
$menu=Join-Path $SourceRoot 'OptiScaler\menu\menu_common.cpp'
$hdr=Join-Path $SourceRoot 'OptiScaler\menu\LifelineI18n.h'
if(!(Test-Path $menu)){throw "menu_common.cpp not found: $menu"}
Copy-Item (Join-Path $PSScriptRoot 'LifelineI18n.h') $hdr -Force
$t=Get-Content $menu -Raw -Encoding UTF8
if($t-notmatch 'LifelineI18n.h'){$t=$t -replace '#include "menu_common.h"', "#include `"menu_common.h`"`r`n#include `"LifelineI18n.h`""}
$t=$t -replace 'io\.Fonts->GetGlyphRangesDefault\(\)','LifelineI18n::GlyphRanges(io.Fonts)'
$needle='if \(ImGui::Begin\(windowTitle\.c_str\(\), NULL, flags\)\)\s*\{'
if($t-match $needle -and $t-notmatch 'LifelineI18n::RenderMiniPanel\(\)'){$m=[regex]::Match($t,$needle);$insert=$m.Value+"`r`n        LifelineI18n::RenderMiniPanel();";$t=$t.Substring(0,$m.Index)+$insert+$t.Substring($m.Index+$m.Length)}
Set-Content $menu $t -Encoding UTF8
Write-Host 'Lifeline i18n patch applied.'
