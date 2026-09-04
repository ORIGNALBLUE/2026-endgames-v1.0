@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; if($f.ShowDialog() -eq 'OK'){ & '.\Tools\Collect-Diagnostics.ps1' -GameFolder $f.SelectedPath -OpenFolder } else { & '.\Tools\Collect-Diagnostics.ps1' -OpenFolder }"
endlocal
