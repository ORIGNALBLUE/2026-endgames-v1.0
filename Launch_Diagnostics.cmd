@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$f=New-Object System.Windows.Forms.FolderBrowserDialog; Add-Type -AssemblyName System.Windows.Forms; if($f.ShowDialog() -eq 'OK'){ & '.\Tools\Collect-Diagnostics.ps1' -GameFolder $f.SelectedPath -OpenFolder } else { & '.\Tools\Collect-Diagnostics.ps1' -OpenFolder }"
endlocal
