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
    'Set-BackupExpectedHashes',
    'Restore-BackupPath',
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

    # An incomplete manifest must not overwrite a file with an unknown state.
    $target = Join-Path $root 'incomplete-manifest'
    New-Item -ItemType Directory -Path $target | Out-Null
    Set-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Value 'original' -NoNewline
    $backup = Backup-Target $target @('OptiScaler.ini')
    Set-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Value 'external-change' -NoNewline
    $result = Restore-BackupPath $target $backup
    Assert-Equal 'external-change' (Get-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Raw) 'Incomplete manifest overwrote an unknown file state'
    Assert-Equal 1 $result.skipped 'Incomplete manifest was not reported as skipped'

    # Planned hashes allow a failed deployment to roll back only exact staged bytes.
    $target = Join-Path $root 'planned-rollback'
    New-Item -ItemType Directory -Path $target | Out-Null
    Set-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Value 'original' -NoNewline
    $backup = Backup-Target $target @('OptiScaler.ini','dxgi.dll')
    $stagedIni = Join-Path $root 'staged.ini';$stagedDll = Join-Path $root 'staged.dll'
    Set-Content -LiteralPath $stagedIni -Value 'deployed-ini' -NoNewline
    Set-Content -LiteralPath $stagedDll -Value 'deployed-dll' -NoNewline
    $expected = @{'OptiScaler.ini'=(Get-FileHashSafe $stagedIni);'dxgi.dll'=(Get-FileHashSafe $stagedDll)}
    Set-BackupExpectedHashes $backup $expected
    Copy-Item -LiteralPath $stagedIni -Destination (Join-Path $target 'OptiScaler.ini')
    Copy-Item -LiteralPath $stagedDll -Destination (Join-Path $target 'dxgi.dll')
    $result = Restore-BackupPath $target $backup
    Assert-Equal 'original' (Get-Content -LiteralPath (Join-Path $target 'OptiScaler.ini') -Raw) 'Planned rollback did not restore original'
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $target 'dxgi.dll')) 'Planned rollback did not remove new file'
    Assert-Equal 1 $result.restored 'Planned rollback restore count'
    Assert-Equal 1 $result.removed 'Planned rollback remove count'

    Write-Host 'Restore safety tests passed.'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
