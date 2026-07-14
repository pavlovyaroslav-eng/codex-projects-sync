#Requires -RunAsAdministrator
[CmdletBinding()]
param([string]$ToolkitRoot)

$ErrorActionPreference = 'Continue'
if (-not $ToolkitRoot) { $ToolkitRoot = Split-Path -Parent $PSScriptRoot }
$ToolkitRoot = [IO.Path]::GetFullPath($ToolkitRoot)
$registry = Get-Content -LiteralPath (Join-Path $ToolkitRoot 'config\packages.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$logDir = Join-Path $ToolkitRoot 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Start-Transcript -Path (Join-Path $logDir "system-update-$stamp.log") -Force | Out-Null
try {
    foreach ($package in $registry.packages | Where-Object {
        $_.manager -eq 'winget' -and $_.updateScope -eq 'system' -and $_.autoUpdateAllowed
    }) {
        $currentMajor = if ($package.installedVersion -match '^(\d+)') { [int]$Matches[1] } else { $null }
        $show = winget show --id $package.packageId --exact --versions --accept-source-agreements 2>&1
        $versions = @($show | Select-String -Pattern '^\s*(\d+(?:\.\d+)+)\s*$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
        if (-not $versions.Count) {
            Write-Warning "Skipped $($package.name): could not determine an exact stable version."
            continue
        }
        $latest = $versions | Sort-Object { [version]$_ } -Descending | Select-Object -First 1
        $latestMajor = if ($latest -match '^(\d+)') { [int]$Matches[1] } else { $null }
        if (-not $package.allowMajorUpdate -and $null -ne $currentMajor -and $latestMajor -ne $currentMajor) {
            Write-Warning "Skipped $($package.name): major version change $currentMajor -> $latestMajor requires manual approval."
            continue
        }
        winget upgrade --id $package.packageId --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    & (Join-Path $PSScriptRoot 'Test-EngineeringToolkit.ps1') -ToolkitRoot $ToolkitRoot
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
