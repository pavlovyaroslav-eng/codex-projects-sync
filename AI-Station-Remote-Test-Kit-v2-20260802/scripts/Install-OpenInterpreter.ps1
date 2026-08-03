[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSScriptRoot
$venv = Join-Path $packageRoot ".open-interpreter-venv"
$venvPython = Join-Path $venv "Scripts\python.exe"
$requirements = Join-Path $packageRoot "requirements.txt"
$expectedVersion = "0.4.3"
$pythonInstallerUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
$pythonInstallerSha256 = "5ee42c4eee1e6b4464bb23722f90b45303f79442df63083f05322f1785f5fdde"
. (Join-Path $PSScriptRoot 'NetworkHelpers.ps1')

function Find-CompatiblePython {
    $candidates = @()
    $perUserPython = Join-Path $env:LocalAppData 'Programs\Python\Python311\python.exe'
    if (Test-Path -LiteralPath $perUserPython) {
        $candidates += ,@($perUserPython)
    }
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

function Install-CompatiblePython {
    $answer = Read-Host "Python 3.10/3.11 was not found. Install official Python 3.11.9 for this Windows user? [Y/N]"
    if ($answer -notmatch '^(?i:y|yes)$') {
        throw "Python installation was cancelled. Install 64-bit Python 3.11 from python.org and retry."
    }

    $downloadDirectory = Join-Path $env:TEMP 'HomeTele-AI-Installer'
    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
    $installer = Join-Path $downloadDirectory 'python-3.11.9-amd64.exe'
    Write-Host "Downloading Python 3.11.9 from python.org..." -ForegroundColor Cyan
    $download = @{ Uri = $pythonInstallerUrl; OutFile = $installer; UseBasicParsing = $true }
    if ($null -ne $script:internetProxy) { $download.Proxy = $script:internetProxy.Uri.AbsoluteUri }
    Invoke-WebRequest @download

    $actualHash = (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $pythonInstallerSha256) {
        throw "The downloaded Python installer SHA-256 does not match the verified release file."
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $installer
    if ($signature.Status -ne 'Valid' -or $null -eq $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch 'Python Software Foundation') {
        throw "The downloaded Python installer does not have a valid Python Software Foundation signature."
    }

    Write-Host "Installing Python for the current user (no administrator rights required)..." -ForegroundColor Cyan
    $arguments = @(
        '/passive', 'InstallAllUsers=0', 'Include_launcher=1', 'InstallLauncherAllUsers=0',
        'Include_pip=1', 'Include_test=0', 'Include_doc=0', 'PrependPath=0', 'Shortcuts=0'
    )
    $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -notin @(0, 1641, 3010)) {
        throw "Python installer returned exit code $($process.ExitCode)."
    }
    $selected = Find-CompatiblePython
    if ($null -eq $selected) { throw "Python installation completed, but Python 3.11 could not be located." }
    return $selected
}

try {
    if (-not (Test-Path -LiteralPath $requirements)) {
        throw "requirements.txt is missing. Extract the complete ZIP first."
    }

    $script:internetProxy = Get-HomeTeleProxyConfiguration ([Uri]'https://pypi.org/')
    if ($null -ne $script:internetProxy) {
        Set-HomeTeleProxyEnvironment $script:internetProxy
        Write-Host "Internet transport: $(Get-HomeTeleProxyDisplay $script:internetProxy)" -ForegroundColor Cyan
    }
    [Environment]::SetEnvironmentVariable('PIP_DEFAULT_TIMEOUT', '120', 'Process')

    if (-not (Test-Path -LiteralPath $venvPython)) {
        $selected = Find-CompatiblePython
        if ($null -eq $selected) {
            $selected = Install-CompatiblePython
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
