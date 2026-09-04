#requires -version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RuntimeDir = Join-Path $ScriptRoot 'Runtime'
$LocalesDir = Join-Path $ScriptRoot 'Locales'
$ToolsDir = Join-Path $ScriptRoot 'Tools'
$SettingsPath = Join-Path $ScriptRoot 'settings.json'
$TrackerPath = Join-Path $ScriptRoot 'sdk_tracker.json'
$script:Strings = @{}
$script:ControlsByKey = @{}
$script:CurrentLocale = 'en-US'
$script:gpu = ''

function Read-JsonFile([string]$Path){
    if(Test-Path -LiteralPath $Path){
        try { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
    }
    return $null
}
function Save-JsonFile([string]$Path,$Object){
    $Object | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Get-Setting {
    $s=Read-JsonFile $SettingsPath
    if(!$s){ return [pscustomobject]@{ locale='en-US'; auto_check_hours=24; check_on_launch=$true } }
    if(!$s.locale){$s | Add-Member locale 'en-US'}
    if($null -eq $s.auto_check_hours){$s | Add-Member auto_check_hours 24}
    if($null -eq $s.check_on_launch){$s | Add-Member check_on_launch $true}
    return $s
}
function Save-Setting {
    $hours = switch($script:cmbAutoCheck.SelectedIndex){0{0}1{6}2{12}default{24}}
    Save-JsonFile $SettingsPath ([pscustomobject]@{locale=$script:CurrentLocale;auto_check_hours=$hours;check_on_launch=$true})
}
function Load-Locale([string]$Locale){
    $fallback=Read-JsonFile (Join-Path $LocalesDir 'en-US.json')
    $target=Read-JsonFile (Join-Path $LocalesDir ($Locale+'.json'))
    if(!$fallback){throw 'Missing en-US locale.'}
    $h=@{}
    $fallback.psobject.Properties | ForEach-Object {$h[$_.Name]=[string]$_.Value}
    if($target){$target.psobject.Properties | ForEach-Object {$h[$_.Name]=[string]$_.Value}}
    $script:Strings=$h; $script:CurrentLocale=$Locale
}
function T([string]$Key){ if($script:Strings.ContainsKey($Key)){return $script:Strings[$Key]} return $Key }
function Bind-Text($Control,[string]$Key){$script:ControlsByKey[$Key]+=@($Control);$Control.Text=T $Key}
function Refresh-Language {
    foreach($key in @($script:ControlsByKey.Keys)){
        foreach($c in @($script:ControlsByKey[$key])){ if($c -and !$c.IsDisposed){$c.Text=T $key} }
    }
    $form.Text=T 'app_title'
    if($gridSdk){ foreach($col in $gridSdk.Columns){ if($col.Tag){$col.HeaderText=T ([string]$col.Tag)} } }
    if($cmbPreset){
        $keep=$cmbPreset.SelectedIndex; $cmbPreset.Items.Clear();
        [void]$cmbPreset.Items.AddRange(@((T 'preset_auto'),(T 'preset_intel'),(T 'preset_amd'),(T 'preset_nvidia')));
        $cmbPreset.SelectedIndex=[Math]::Max(0,$keep)
    }
    if($cmbAutoCheck){
        $keep=$cmbAutoCheck.SelectedIndex; $cmbAutoCheck.Items.Clear();
        [void]$cmbAutoCheck.Items.AddRange(@((T 'off'),(T 'hours6'),(T 'hours12'),(T 'hours24')));
        $cmbAutoCheck.SelectedIndex=[Math]::Max(0,$keep)
    }
    Update-GpuLabel
    Refresh-StatusText
    Refresh-SdkGrid
}
function Msg([string]$Key,[System.Windows.Forms.MessageBoxIcon]$Icon=[System.Windows.Forms.MessageBoxIcon]::Information){
    [System.Windows.Forms.MessageBox]::Show((T $Key),'AetherScaler',[System.Windows.Forms.MessageBoxButtons]::OK,$Icon)|Out-Null
}
function Detect-Gpu {
    try {$g=Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name; if($g){return ($g -join ' | ')}}catch{}
    return T 'unknown'
}
function Update-GpuLabel { if($lblGpu){$lblGpu.Text=(T 'detected_gpu')+': '+$script:gpu} }
function Has-AntiCheat([string]$Folder){
    $markers=@('EasyAntiCheat','EasyAntiCheat_EOS','BattlEye','BEClient','vgk','xigncode','xhunter','nProtect')
    foreach($m in $markers){
        if(Get-ChildItem -LiteralPath $Folder -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -like "*$m*"} | Select-Object -First 1){return $true}
    }
    return $false
}
function Backup-Target([string]$Folder,[string[]]$Names){
    $root=Join-Path $Folder '.AetherScaler_Backup'; New-Item -ItemType Directory -Force -Path $root|Out-Null
    $dst=Join-Path $root (Get-Date -Format 'yyyyMMdd-HHmmss');New-Item -ItemType Directory -Force -Path $dst|Out-Null
    foreach($n in $Names){$p=Join-Path $Folder $n;if(Test-Path -LiteralPath $p){Copy-Item -LiteralPath $p -Destination (Join-Path $dst $n) -Force}}
    return $dst
}
function Set-IniValue([string]$Path,[string]$Section,[string]$Key,[string]$Value){
    $lines=[System.Collections.Generic.List[string]](Get-Content -LiteralPath $Path)
    $sec="[$Section]";$secIdx=-1;$nextSec=$lines.Count
    for($i=0;$i -lt $lines.Count;$i++){if($lines[$i].Trim() -ieq $sec){$secIdx=$i;break}}
    if($secIdx -lt 0){$lines.Add('');$lines.Add($sec);$lines.Add("$Key=$Value");Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8;return}
    for($i=$secIdx+1;$i -lt $lines.Count;$i++){if($lines[$i] -match '^\s*\['){$nextSec=$i;break}}
    for($i=$secIdx+1;$i -lt $nextSec;$i++){if($lines[$i] -match ('^\s*'+[regex]::Escape($Key)+'\s*=')){$lines[$i]="$Key=$Value";Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8;return}}
    $lines.Insert($nextSec,"$Key=$Value");Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}
function Apply-QuickPreset {
    switch($cmbPreset.SelectedIndex){
        1 {$cmbDx12.SelectedItem='xess';$cmbDx11.SelectedItem='xess';$cmbVk.SelectedItem='xess'}
        2 {$cmbDx12.SelectedItem='fsr31';$cmbDx11.SelectedItem='fsr31';$cmbVk.SelectedItem='fsr31'}
        3 {$cmbDx12.SelectedItem='dlss';$cmbDx11.SelectedItem='dlss';$cmbVk.SelectedItem='dlss'}
        default {
            if($script:gpu -match 'Intel|Arc'){$cmbDx12.SelectedItem='xess'}
            elseif($script:gpu -match 'AMD|Radeon'){$cmbDx12.SelectedItem='fsr31'}
            elseif($script:gpu -match 'NVIDIA|GeForce'){$cmbDx12.SelectedItem='dlss'}
        }
    }
}
function Apply-Profile {
    $folder=$txtFolder.Text.Trim();if(!(Test-Path -LiteralPath $folder)){Msg 'folder_required' Warning;return}
    if(Has-AntiCheat $folder){Msg 'anticheat_block' Warning;return}
    Apply-QuickPreset
    $hook=[string]$cmbHook.SelectedItem
    $names=@($hook,'OptiScaler.ini','amd_fidelityfx_dx12.dll','amd_fidelityfx_upscaler_dx12.dll','amd_fidelityfx_framegeneration_dx12.dll','amd_fidelityfx_vk.dll','fakenvapi.dll','fakenvapi.ini','libxess.dll','libxess_dx11.dll','libxess_fg.dll','libxell.dll','dlssg_to_fsr3_amd_is_better.dll')
    $backup=Backup-Target $folder $names
    Copy-Item (Join-Path $RuntimeDir 'OptiScaler.dll') (Join-Path $folder $hook) -Force
    $ini=Join-Path $folder 'OptiScaler.ini';if(!(Test-Path $ini)){Copy-Item (Join-Path $RuntimeDir 'OptiScaler.ini.template') $ini -Force}
    foreach($n in $names | Where-Object {$_ -ne $hook -and $_ -ne 'OptiScaler.ini'}){$p=Join-Path $RuntimeDir $n;if(Test-Path $p){Copy-Item $p (Join-Path $folder $n) -Force}}
    Set-IniValue $ini 'Upscalers' 'Dx11Upscaler' ([string]$cmbDx11.SelectedItem)
    Set-IniValue $ini 'Upscalers' 'Dx12Upscaler' ([string]$cmbDx12.SelectedItem)
    Set-IniValue $ini 'Upscalers' 'VulkanUpscaler' ([string]$cmbVk.SelectedItem)
    Set-IniValue $ini 'FrameGen' 'Enabled' ($(if($chkFG.Checked){'true'}else{'false'}))
    Set-IniValue $ini 'FrameGen' 'FGInput' ([string]$cmbFGIn.SelectedItem)
    Set-IniValue $ini 'FrameGen' 'FGOutput' ([string]$cmbFGOut.SelectedItem)
    Set-IniValue $ini 'Menu' 'OverlayMenu' 'true';Set-IniValue $ini 'Menu' 'ShowFps' ($(if($chkFPS.Checked){'true'}else{'false'}));Set-IniValue $ini 'Menu' 'Scale' $numScale.Value.ToString([Globalization.CultureInfo]::InvariantCulture)
    $spoof=[string]$cmbSpoof.SelectedItem
    if($spoof -eq 'Off'){
        Set-IniValue $ini 'Spoofing' 'Dxgi' 'false';Set-IniValue $ini 'Spoofing' 'Vulkan' 'false';Set-IniValue $ini 'Spoofing' 'StreamlineSpoofing' 'false'
    }else{
        $vid='0x10de';$did='0x2684';$name='NVIDIA GeForce RTX 4090'
        if($spoof -eq 'Intel Arc B580'){$vid='0x8086';$did='0xE20B';$name='Intel(R) Arc(TM) B580 Graphics'}
        elseif($spoof -eq 'AMD RX 9070 XT'){$vid='0x1002';$did='0x7550';$name='AMD Radeon RX 9070 XT'}
        Set-IniValue $ini 'Spoofing' 'SpoofedVendorId' $vid;Set-IniValue $ini 'Spoofing' 'SpoofedDeviceId' $did;Set-IniValue $ini 'Spoofing' 'SpoofedGPUName' $name
        Set-IniValue $ini 'Spoofing' 'Dxgi' ($(if($chkDxgi.Checked){'true'}else{'false'}));Set-IniValue $ini 'Spoofing' 'Vulkan' ($(if($chkVkSpoof.Checked){'true'}else{'false'}));Set-IniValue $ini 'Spoofing' 'StreamlineSpoofing' ($(if($chkSL.Checked){'true'}else{'false'}));Set-IniValue $ini 'Spoofing' 'UEIntelAtomics' ($(if($chkUEIntel.Checked){'true'}else{'false'}))
    }
    $statusLabel.Text=(T 'status_applied')+" — $backup"
}
function Restore-LastBackup {
    $folder=$txtFolder.Text.Trim();$root=Join-Path $folder '.AetherScaler_Backup';if(!(Test-Path $root)){return}
    $last=Get-ChildItem $root -Directory|Sort-Object Name -Descending|Select-Object -First 1;if(!$last){return}
    Get-ChildItem $last.FullName -File|ForEach-Object{Copy-Item $_.FullName (Join-Path $folder $_.Name) -Force}
    $statusLabel.Text=T 'status_restored'
}
function Get-FileVersionSafe([string]$Path){
    if(!(Test-Path -LiteralPath $Path)){return '—'}
    try {$v=(Get-Item -LiteralPath $Path).VersionInfo.FileVersion;if($v){return $v}}catch{}
    return 'present'
}
function Get-SdkTracker {
    $x=Read-JsonFile $TrackerPath
    if(!$x){return [pscustomobject]@{checked_at='';optiscaler='';intel_xess='';nvidia_streamline='';amd_fsr='';xell='1.3.2.10';amd_upscaling='4.1.1';amd_fg='4.0.1'}}
    return $x
}
function Refresh-SdkGrid {
    if(!$gridSdk){return}
    $tracker=Get-SdkTracker
    $gridSdk.Rows.Clear()
    $rows=@(
        @('OptiScaler', (Get-FileVersionSafe (Join-Path $RuntimeDir 'OptiScaler.dll')), $tracker.optiscaler),
        @('Intel XeSS', (Get-FileVersionSafe (Join-Path $RuntimeDir 'libxess.dll')), $tracker.intel_xess),
        @('Intel XeSS-FG', (Get-FileVersionSafe (Join-Path $RuntimeDir 'libxess_fg.dll')), $tracker.intel_xess),
        @('Intel XeLL', (Get-FileVersionSafe (Join-Path $RuntimeDir 'libxell.dll')), $(if($tracker.xell){$tracker.xell}else{'1.3.2.10'})),
        @('AMD FSR Upscaling', (Get-FileVersionSafe (Join-Path $RuntimeDir 'amd_fidelityfx_upscaler_dx12.dll')), $(if($tracker.amd_upscaling){$tracker.amd_upscaling}else{$tracker.amd_fsr})),
        @('AMD Frame Generation', (Get-FileVersionSafe (Join-Path $RuntimeDir 'amd_fidelityfx_framegeneration_dx12.dll')), $(if($tracker.amd_fg){$tracker.amd_fg}else{$tracker.amd_fsr})),
        @('NVIDIA Streamline', 'not bundled', $tracker.nvidia_streamline)
    )
    foreach($r in $rows){
        $status=T 'unknown'
        if($r[2]){
            $a=([regex]::Match([string]$r[1],'\d+(\.\d+){1,3}')).Value;$b=([regex]::Match([string]$r[2],'\d+(\.\d+){1,3}')).Value
            if($a -and $b){if($a.StartsWith($b) -or $b.StartsWith($a)){$status=T 'up_to_date'}else{$status=T 'update_available'}}
        }
        [void]$gridSdk.Rows.Add($r[0],$r[1],$(if($r[2]){$r[2]}else{'—'}),$status)
    }
    $lblLastCheck.Text=(T 'last_check')+': '+$(if($tracker.checked_at){$tracker.checked_at}else{'—'})
}
function Check-OfficialReleases {
    $btnCheckOnline.Enabled=$false;$statusLabel.Text=T 'checking'
    try {
        & (Join-Path $ToolsDir 'Update-SDKTracker.ps1') -OutputPath $TrackerPath -Quiet
        Refresh-SdkGrid;$statusLabel.Text=T 'status_ready'
    } catch {$statusLabel.Text=$_.Exception.Message}
    finally {$btnCheckOnline.Enabled=$true}
}
function Configure-AutoTimer {
    $hours=switch($cmbAutoCheck.SelectedIndex){0{0}1{6}2{12}default{24}}
    $timer.Stop();if($hours -gt 0){$timer.Interval=[Math]::Min([int]::MaxValue,$hours*60*60*1000);$timer.Start()};Save-Setting
}
function Refresh-StatusText {if(!$statusLabel.Text -or $statusLabel.Text -in @('Ready','就緒','準備完了','준비됨','Bereit','Prêt','Listo','Pronto')){$statusLabel.Text=T 'status_ready'}}

$settings=Get-Setting;Load-Locale $settings.locale
$form=New-Object Windows.Forms.Form;$form.Text=T 'app_title';$form.Size='980,700';$form.StartPosition='CenterScreen';$form.MinimumSize='900,620'
$top=New-Object Windows.Forms.Panel;$top.Dock='Top';$top.Height=46;$form.Controls.Add($top)
$lblLang=New-Object Windows.Forms.Label;$lblLang.Location='12,14';$lblLang.AutoSize=$true;Bind-Text $lblLang 'language';$top.Controls.Add($lblLang)
$cmbLang=New-Object Windows.Forms.ComboBox;$cmbLang.DropDownStyle='DropDownList';$cmbLang.Location='90,10';$cmbLang.Width=210;$top.Controls.Add($cmbLang)
$localeFiles=Get-ChildItem $LocalesDir -Filter '*.json'|Sort-Object Name
foreach($f in $localeFiles){$o=Read-JsonFile $f;[void]$cmbLang.Items.Add([pscustomobject]@{Name=$o.language_name;Code=$f.BaseName})};$cmbLang.DisplayMember='Name'
for($i=0;$i -lt $cmbLang.Items.Count;$i++){if($cmbLang.Items[$i].Code -eq $script:CurrentLocale){$cmbLang.SelectedIndex=$i;break}}
$statusLabel=New-Object Windows.Forms.Label;$statusLabel.Dock='Right';$statusLabel.Width=500;$statusLabel.TextAlign='MiddleRight';$statusLabel.Padding='0,0,14,0';$statusLabel.Text=T 'status_ready';$top.Controls.Add($statusLabel)

$tabs=New-Object Windows.Forms.TabControl;$tabs.Dock='Fill';$form.Controls.Add($tabs);$tabs.BringToFront()
function New-Tab([string]$key){$t=New-Object Windows.Forms.TabPage;Bind-Text $t $key;[void]$tabs.TabPages.Add($t);return $t}
$tabHome=New-Tab 'tab_home';$tabAdv=New-Tab 'tab_advanced';$tabSdk=New-Tab 'tab_sdk';$tabHelp=New-Tab 'tab_help'
function Label($tab,$x,$y,$key){$l=New-Object Windows.Forms.Label;$l.Location="$x,$y";$l.AutoSize=$true;Bind-Text $l $key;$tab.Controls.Add($l);return $l}
function Combo($tab,$x,$y,$w,$items,$idx){$c=New-Object Windows.Forms.ComboBox;$c.Location="$x,$y";$c.Width=$w;$c.DropDownStyle='DropDownList';[void]$c.Items.AddRange($items);$c.SelectedIndex=$idx;$tab.Controls.Add($c);return $c}

Label $tabHome 20 22 'game_folder'|Out-Null
$txtFolder=New-Object Windows.Forms.TextBox;$txtFolder.Location='20,48';$txtFolder.Width=710;$tabHome.Controls.Add($txtFolder)
$btnBrowse=New-Object Windows.Forms.Button;$btnBrowse.Location='745,45';$btnBrowse.Size='160,30';Bind-Text $btnBrowse 'browse';$tabHome.Controls.Add($btnBrowse)
$btnBrowse.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq 'OK'){$txtFolder.Text=$d.SelectedPath}})
$lblGpu=New-Object Windows.Forms.Label;$lblGpu.Location='20,90';$lblGpu.Size='880,38';$tabHome.Controls.Add($lblGpu);$script:gpu=Detect-Gpu;Update-GpuLabel
Label $tabHome 20 145 'hook'|Out-Null;$cmbHook=Combo $tabHome 20 170 240 @('dxgi.dll','winmm.dll','version.dll','dbghelp.dll','d3d12.dll','wininet.dll','winhttp.dll','OptiScaler.asi') 0
Label $tabHome 320 145 'preset'|Out-Null;$cmbPreset=Combo $tabHome 320 170 260 @('Auto / Recommended','Intel XeSS','AMD FSR','NVIDIA DLSS') 0
$chkFG=New-Object Windows.Forms.CheckBox;$chkFG.Location='20,235';$chkFG.AutoSize=$true;Bind-Text $chkFG 'frame_generation';$tabHome.Controls.Add($chkFG)
$chkSpoofHome=New-Object Windows.Forms.CheckBox;$chkSpoofHome.Location='320,235';$chkSpoofHome.AutoSize=$true;Bind-Text $chkSpoofHome 'spoofing';$tabHome.Controls.Add($chkSpoofHome);$chkSpoofHome.Add_CheckedChanged({if($chkSpoofHome.Checked -and $cmbSpoof.SelectedIndex -eq 0){$cmbSpoof.SelectedIndex=1}elseif(!$chkSpoofHome.Checked){$cmbSpoof.SelectedIndex=0}})
$btnApply=New-Object Windows.Forms.Button;$btnApply.Location='20,310';$btnApply.Size='210,54';Bind-Text $btnApply 'apply';$btnApply.Add_Click({Apply-Profile});$tabHome.Controls.Add($btnApply)
$btnRestore=New-Object Windows.Forms.Button;$btnRestore.Location='250,310';$btnRestore.Size='250,54';Bind-Text $btnRestore 'restore';$btnRestore.Add_Click({Restore-LastBackup});$tabHome.Controls.Add($btnRestore)

$noteAdv=Label $tabAdv 20 18 'advanced_note';$noteAdv.ForeColor=[Drawing.Color]::DimGray
Label $tabAdv 20 58 'dx11_upscaler'|Out-Null;$cmbDx11=Combo $tabAdv 20 83 250 @('auto','fsr22','fsr31','xess','xess_12','fsr21_12','fsr22_12','fsr31_12','dlss') 0
Label $tabAdv 320 58 'dx12_upscaler'|Out-Null;$cmbDx12=Combo $tabAdv 320 83 250 @('auto','xess','fsr21','fsr22','fsr31','dlss') 0
Label $tabAdv 620 58 'vulkan_upscaler'|Out-Null;$cmbVk=Combo $tabAdv 620 83 250 @('auto','fsr21','fsr22','fsr31','xess','fsr21_12','fsr31_12','dlss') 0
Label $tabAdv 20 145 'fg_input'|Out-Null;$cmbFGIn=Combo $tabAdv 20 170 250 @('nofg','dlssg','nukems','fsrfg','upscaler','fsrfg30') 0
Label $tabAdv 320 145 'fg_output'|Out-Null;$cmbFGOut=Combo $tabAdv 320 170 250 @('nofg','fsrfg','xefg','nukems') 0
Label $tabAdv 620 145 'spoof_target'|Out-Null;$cmbSpoof=Combo $tabAdv 620 170 250 @('Off','NVIDIA RTX 4090','Intel Arc B580','AMD RX 9070 XT') 0
$chkFPS=New-Object Windows.Forms.CheckBox;$chkFPS.Location='20,235';$chkFPS.AutoSize=$true;Bind-Text $chkFPS 'show_fps';$tabAdv.Controls.Add($chkFPS)
Label $tabAdv 320 235 'overlay_scale'|Out-Null;$numScale=New-Object Windows.Forms.NumericUpDown;$numScale.Location='320,260';$numScale.Minimum=0.5;$numScale.Maximum=2.0;$numScale.DecimalPlaces=1;$numScale.Increment=0.1;$numScale.Value=1.0;$tabAdv.Controls.Add($numScale)
$chkDxgi=New-Object Windows.Forms.CheckBox;$chkDxgi.Location='20,310';$chkDxgi.Checked=$true;$chkDxgi.AutoSize=$true;Bind-Text $chkDxgi 'dxgi_spoof';$tabAdv.Controls.Add($chkDxgi)
$chkVkSpoof=New-Object Windows.Forms.CheckBox;$chkVkSpoof.Location='320,310';$chkVkSpoof.AutoSize=$true;Bind-Text $chkVkSpoof 'vulkan_spoof';$tabAdv.Controls.Add($chkVkSpoof)
$chkSL=New-Object Windows.Forms.CheckBox;$chkSL.Location='620,310';$chkSL.Checked=$true;$chkSL.AutoSize=$true;Bind-Text $chkSL 'streamline_spoof';$tabAdv.Controls.Add($chkSL)
$chkUEIntel=New-Object Windows.Forms.CheckBox;$chkUEIntel.Location='20,350';$chkUEIntel.AutoSize=$true;Bind-Text $chkUEIntel 'intel_ue_fix';$tabAdv.Controls.Add($chkUEIntel)

$gridSdk=New-Object Windows.Forms.DataGridView;$gridSdk.Location='20,20';$gridSdk.Size='850,330';$gridSdk.ReadOnly=$true;$gridSdk.AllowUserToAddRows=$false;$gridSdk.RowHeadersVisible=$false;$gridSdk.AutoSizeColumnsMode='Fill';$tabSdk.Controls.Add($gridSdk)
foreach($key in @('sdk_component','sdk_local','sdk_latest','sdk_status')){$col=New-Object Windows.Forms.DataGridViewTextBoxColumn;$col.HeaderText=T $key;$col.Tag=$key;[void]$gridSdk.Columns.Add($col)}
$btnScan=New-Object Windows.Forms.Button;$btnScan.Location='20,370';$btnScan.Size='180,38';Bind-Text $btnScan 'scan_local';$btnScan.Add_Click({Refresh-SdkGrid});$tabSdk.Controls.Add($btnScan)
$btnCheckOnline=New-Object Windows.Forms.Button;$btnCheckOnline.Location='215,370';$btnCheckOnline.Size='230,38';Bind-Text $btnCheckOnline 'check_online';$btnCheckOnline.Add_Click({Check-OfficialReleases});$tabSdk.Controls.Add($btnCheckOnline)
$btnFetch=New-Object Windows.Forms.Button;$btnFetch.Location='460,370';$btnFetch.Size='270,38';Bind-Text $btnFetch 'fetch_sdks';$btnFetch.Add_Click({Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $ToolsDir 'Fetch-Latest-SDKs.ps1')`""});$tabSdk.Controls.Add($btnFetch)
Label $tabSdk 20 435 'auto_check'|Out-Null;$cmbAutoCheck=Combo $tabSdk 20 460 180 @((T 'off'),(T 'hours6'),(T 'hours12'),(T 'hours24')) 3
$lblLastCheck=New-Object Windows.Forms.Label;$lblLastCheck.Location='230,465';$lblLastCheck.AutoSize=$true;$tabSdk.Controls.Add($lblLastCheck)

$helpBox=New-Object Windows.Forms.TextBox;$helpBox.Multiline=$true;$helpBox.ReadOnly=$true;$helpBox.Location='20,20';$helpBox.Size='850,260';$helpBox.Text=(T 'safety_note')+"`r`n`r`nRuntime: OptiScaler 0.9.4 baseline`r`nSDK tracker: Intel XeSS / NVIDIA Streamline / AMD FidelityFX`r`nLanguages: zh-TW, en-US, ja-JP, ko-KR, de-DE, fr-FR, es-ES, pt-BR";$tabHelp.Controls.Add($helpBox)
$btnManual=New-Object Windows.Forms.Button;$btnManual.Location='20,310';$btnManual.Size='180,38';Bind-Text $btnManual 'manual';$btnManual.Add_Click({Start-Process (Join-Path $ScriptRoot 'Docs\Manual.md')});$tabHelp.Controls.Add($btnManual)
$btnCompat=New-Object Windows.Forms.Button;$btnCompat.Location='215,310';$btnCompat.Size='210,38';Bind-Text $btnCompat 'compatibility';$btnCompat.Add_Click({Start-Process (Join-Path $ScriptRoot 'Docs\Compatibility_ZH-TW_EN.md')});$tabHelp.Controls.Add($btnCompat)
$btnUpstream=New-Object Windows.Forms.Button;$btnUpstream.Location='440,310';$btnUpstream.Size='360,38';Bind-Text $btnUpstream 'open_upstream';$btnUpstream.Add_Click({Start-Process 'https://github.com/optiscaler/OptiScaler/wiki/Compatibility-List'});$tabHelp.Controls.Add($btnUpstream)

$timer=New-Object Windows.Forms.Timer;$timer.Add_Tick({Check-OfficialReleases})
$cmbAutoCheck.Add_SelectedIndexChanged({Configure-AutoTimer})
$cmbLang.Add_SelectedIndexChanged({if($cmbLang.SelectedItem){Load-Locale $cmbLang.SelectedItem.Code;Refresh-Language;Save-Setting}})
$cmbPreset.Add_SelectedIndexChanged({Apply-QuickPreset})
for($i=0;$i -lt 4;$i++){if(@(0,6,12,24)[$i] -eq [int]$settings.auto_check_hours){$cmbAutoCheck.SelectedIndex=$i;break}}
Refresh-SdkGrid;Configure-AutoTimer
$form.Add_Shown({if($settings.check_on_launch){Check-OfficialReleases}})
[void]$form.ShowDialog()
