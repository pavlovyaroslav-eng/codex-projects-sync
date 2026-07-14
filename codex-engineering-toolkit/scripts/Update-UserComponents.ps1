[CmdletBinding()]
param([string]$ToolkitRoot)

$ErrorActionPreference = 'Continue'
if (-not $ToolkitRoot) { $ToolkitRoot = Split-Path -Parent $PSScriptRoot }
$ToolkitRoot = [IO.Path]::GetFullPath($ToolkitRoot)
$logDir = Join-Path $ToolkitRoot 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$transcript = Join-Path $logDir "user-update-$stamp.log"

$mutex = [Threading.Mutex]::new($false, 'Local\CodexEngineeringToolkitUserUpdate')
if (-not $mutex.WaitOne(0)) { throw 'Another toolkit update is already running.' }
try {
    Start-Transcript -Path $transcript -Force | Out-Null
    & (Join-Path $PSScriptRoot 'Backup-CodexConfiguration.ps1') -ToolkitRoot $ToolkitRoot

    $npm = 'E:\EngineeringTools\NodeJS\node-v24.18.0-win-x64\npm.cmd'
    $codex = 'E:\EngineeringTools\npm-global\codex.cmd'
    $pipx = 'C:\Users\ACER-X-02\AppData\Roaming\Python\Python312\Scripts\pipx.exe'
    if (Test-Path $npm) { & $npm install --global '@openai/codex@latest' --prefix 'E:\EngineeringTools\npm-global' }
    if (Test-Path $codex) { & $codex plugin marketplace upgrade --json }
    if (Test-Path $pipx) {
        foreach ($package in @('cmake', 'platformio', 'esptool')) { & $pipx upgrade $package }
    }

    $source = Join-Path $ToolkitRoot 'plugins\yaroslav-engineering-toolkit'
    foreach ($destination in @(
        (Join-Path $HOME 'plugins\yaroslav-engineering-toolkit'),
        (Join-Path $HOME '.codex\plugins\yaroslav-engineering-toolkit')
    )) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        & robocopy $source $destination /MIR /R:2 /W:2 /NFL /NDL /NJH /NJS /NP
        if ($LASTEXITCODE -gt 7) { throw "Plugin synchronization failed for $destination" }
    }
    if (Test-Path $codex) { & $codex plugin add 'yaroslav-engineering-toolkit@personal' }

    $remotionDir = Join-Path $ToolkitRoot 'tools\media-remotion'
    if ((Test-Path $npm) -and (Test-Path (Join-Path $remotionDir 'package-lock.json'))) {
        & $npm --prefix $remotionDir ci
    }
    & (Join-Path $PSScriptRoot 'Test-EngineeringToolkit.ps1') -ToolkitRoot $ToolkitRoot
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
