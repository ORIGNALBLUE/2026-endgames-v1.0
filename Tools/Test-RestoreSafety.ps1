#requires -version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$managerPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'AetherScaler_Manager.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $managerPath,
    [ref]$tokens,
    [ref]$parseErrors
)
if ($parseErrors.Count -gt 0) {
    throw ('Manager parse failed: ' + (($parseErrors | ForEach-Object Message) -join '; '))
}

$requiredFunctions = @(
    'Read-JsonFile',
    'Save-JsonFile',
    'Get-FileHashSafe',
    'Backup-Target',
    'Complete-BackupManifest',
    'Restore-LastBackup'
)
$definitions = $ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true)

foreach ($name in $requiredFunctions) {
    $definition = $definitions | Where-Object Name -eq $name | Select-Object -First 1
    if (-not $definition) { throw "Missing function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}

function T([string]$Key) { return $Key }
function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -ne $Actual) {
        throw "$Message (expected='$Expected', actual='$Actual')"
    }
}

$root = Join-Path ([IO.Path]::GetTempPath()) ('AetherScaler-RestoreTest-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $root | Out-Null
try {
    # A file that did not exist before deployment must be removed.
    $target = Join-Path $root 'new-file'
    New-Item -ItemType Directory -Path $target | Out-Null
    $backup = Backup-Target $target @('dxgi.dll')
    Set-Content -LiteralPath (Join-Path $target 'dxgi.dll') -Value 'deployed' -NoNewline
    Complete-BackupManifest $backup $target @('dxgi.dll')
    $script:txtFolder = [pscustomobject]@{ Text = $target }
    $script:statusLabel = [pscustomobject]@{ Text = '' }
    Restore-LastBackup
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $target 'dxgi.dll')) 'New deployed file was not removed'

    # An overwritten original must be restored.
    $target = Join-Path $root 'existing-file'
    New-Item -ItemType Directory -Path $target | Out-Null
    Set-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Value 'original' -NoNewline
    $backup = Backup-Target $target @('OptiScaler.ini')
    Set-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Value 'deployed' -NoNewline
    Complete-BackupManifest $backup $target @('OptiScaler.ini')
    $script:txtFolder.Text = $target
    Restore-LastBackup
    Assert-Equal 'original' (Get-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Raw) 'Original file was not restored'

    # User changes made after deployment must be preserved.
    $target = Join-Path $root 'user-modified'
    New-Item -ItemType Directory -Path $target | Out-Null
    $backup = Backup-Target $target @('version.dll')
    Set-Content -LiteralPath (Join-Path $target 'version.dll') -Value 'deployed' -NoNewline
    Complete-BackupManifest $backup $target @('version.dll')
    Set-Content -LiteralPath (Join-Path $target 'version.dll') -Value 'user-change' -NoNewline
    $script:txtFolder.Text = $target
    Restore-LastBackup
    Assert-Equal 'user-change' (Get-Content -LiteralPath (Join-Path $target 'version.dll') -Raw) 'User-modified file was removed'

    Write-Host 'Restore safety tests passed.'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
