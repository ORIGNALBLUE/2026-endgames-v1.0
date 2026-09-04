@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0Logs" mkdir "%~dp0Logs"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$log=Join-Path '%~dp0Logs' ('Launcher-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log'); Start-Transcript -Path $log -Force | Out-Null; try { & '%~dp0AetherScaler_Manager.ps1' } finally { Stop-Transcript | Out-Null }"
endlocal
