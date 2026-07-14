[CmdletBinding()]
param([string]$ToolkitRoot)

$ErrorActionPreference = 'Stop'
if (-not $ToolkitRoot) { $ToolkitRoot = Split-Path -Parent $PSScriptRoot }
$ToolkitRoot = [IO.Path]::GetFullPath($ToolkitRoot)
foreach ($directory in @('logs', 'backups', 'config', 'plugins', 'tools')) {
    New-Item -ItemType Directory -Path (Join-Path $ToolkitRoot $directory) -Force | Out-Null
}

& (Join-Path $PSScriptRoot 'Backup-CodexConfiguration.ps1') -ToolkitRoot $ToolkitRoot

$source = Join-Path $ToolkitRoot 'plugins\yaroslav-engineering-toolkit'
foreach ($destination in @(
    (Join-Path $HOME 'plugins\yaroslav-engineering-toolkit'),
    (Join-Path $HOME '.codex\plugins\yaroslav-engineering-toolkit')
)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    & robocopy $source $destination /MIR /R:2 /W:2 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) { throw "Plugin synchronization failed for $destination" }
}

$codex = 'E:\EngineeringTools\npm-global\codex.cmd'
if (Test-Path $codex) { & $codex plugin add 'yaroslav-engineering-toolkit@personal' }

$powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
$action = New-ScheduledTaskAction -Execute $powershell -Argument ('-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $PSScriptRoot 'Update-UserComponents.ps1') + '"')
$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At '05:00'
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 4)
$principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'Codex Engineering Toolkit - Weekly Update' -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Safe non-elevated weekly update of the Codex engineering toolkit.' -Force | Out-Null

& (Join-Path $PSScriptRoot 'Test-EngineeringToolkit.ps1') -ToolkitRoot $ToolkitRoot
