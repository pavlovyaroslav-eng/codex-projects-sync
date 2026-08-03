[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSScriptRoot
$venv = Join-Path $packageRoot ".open-interpreter-venv"
$venvPython = Join-Path $venv "Scripts\python.exe"
$requirements = Join-Path $packageRoot "requirements.txt"
$expectedVersion = "0.4.3"

function Find-CompatiblePython {
    $candidates = @()
    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($null -ne $py) {
        $candidates += ,@($py.Source, "-3.11")
        $candidates += ,@($py.Source, "-3.10")
    }
    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($null -ne $python) {
        $candidates += ,@($python.Source)
    }

    foreach ($candidate in $candidates) {
        $exe = $candidate[0]
        $prefix = @()
        if ($candidate.Count -gt 1) { $prefix = @($candidate[1]) }
        try {
            $version = & $exe @prefix -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
            if ($LASTEXITCODE -eq 0 -and $version -match '^3\.(10|11)$') {
                return [PSCustomObject]@{ Exe = $exe; Prefix = $prefix; Version = $version }
            }
        }
        catch { }
    }
    return $null
}

try {
    if (-not (Test-Path -LiteralPath $requirements)) {
        throw "requirements.txt is missing. Extract the complete ZIP first."
    }

    if (-not (Test-Path -LiteralPath $venvPython)) {
        $selected = Find-CompatiblePython
        if ($null -eq $selected) {
            throw "Python 3.10 or 3.11 was not found. Install 64-bit Python 3.11 from https://www.python.org/downloads/windows/ and retry."
        }
        Write-Host "Creating virtual environment with Python $($selected.Version)..." -ForegroundColor Cyan
        & $selected.Exe @($selected.Prefix) -m venv $venv
        if ($LASTEXITCODE -ne 0) { throw "Python failed to create the virtual environment." }
    }

    Write-Host "Updating pip inside the isolated environment..." -ForegroundColor Cyan
    & $venvPython -m pip install --disable-pip-version-check --upgrade pip
    if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed." }

    Write-Host "Installing Open Interpreter $expectedVersion from PyPI..." -ForegroundColor Cyan
    & $venvPython -m pip install --disable-pip-version-check --require-virtualenv -r $requirements
    if ($LASTEXITCODE -ne 0) { throw "Open Interpreter installation failed." }

    $installedVersion = & $venvPython -c "import importlib.metadata; print(importlib.metadata.version('open-interpreter'))"
    if ($LASTEXITCODE -ne 0 -or $installedVersion -ne $expectedVersion) {
        throw "Installed version '$installedVersion' does not match '$expectedVersion'."
    }
    & $venvPython -c "from interpreter import interpreter; assert interpreter is not None; print('Import check: OK')"
    if ($LASTEXITCODE -ne 0) { throw "The interpreter package import check failed." }

    $reportDirectory = Join-Path $packageRoot "reports"
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    @(
        "UTC: $([DateTime]::UtcNow.ToString('o'))",
        "Open Interpreter: $installedVersion",
        "Virtual environment: .open-interpreter-venv",
        "Result: PASS"
    ) | Set-Content -LiteralPath (Join-Path $reportDirectory "open-interpreter-install.txt") -Encoding UTF8

    Write-Host "Open Interpreter $installedVersion is ready." -ForegroundColor Green
    Write-Host "Next: run 03-RUN-OPEN-INTERPRETER.cmd" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

