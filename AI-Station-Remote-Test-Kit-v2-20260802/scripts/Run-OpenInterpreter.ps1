[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSScriptRoot
$venvPython = Join-Path $packageRoot ".open-interpreter-venv\Scripts\python.exe"
$runner = Join-Path $PSScriptRoot "Run-OpenInterpreter.py"
$baseUrl = 'http://10.93.0.10:8080'
. (Join-Path $PSScriptRoot 'NetworkHelpers.ps1')

try {
    if (-not (Test-Path -LiteralPath $venvPython)) {
        throw "Open Interpreter is not installed. Run 02-INSTALL-OPEN-INTERPRETER.cmd first."
    }
    if (-not (Test-Path -LiteralPath $runner)) {
        throw "Run-OpenInterpreter.py is missing. Extract the complete ZIP first."
    }

    Write-Host "Checking HomeTele AI through Windows proxy or TUN..." -ForegroundColor Cyan
    $targetUri = [Uri]$baseUrl
    $candidates = @()
    $candidates += @(Get-HomeTeleProxyCandidates $targetUri)
    $candidates += ,$null
    $selectedProxy = $null
    $connected = $false
    foreach ($candidate in $candidates) {
        $probe = $null
        try {
            $probe = New-HomeTeleHttpClient $candidate
            $probe.Timeout = [TimeSpan]::FromSeconds(15)
            $response = $probe.GetAsync("$baseUrl/health").GetAwaiter().GetResult()
            if ($response.IsSuccessStatusCode) {
                $selectedProxy = $candidate
                $connected = $true
                break
            }
        }
        catch { }
        finally {
            if ($null -ne $probe) { $probe.Dispose() }
        }
    }
    if (-not $connected) {
        throw "AI endpoint is unavailable through both Windows system proxy and direct/TUN mode. Connect VLESS first. Ping is not required."
    }

    Set-HomeTeleProxyEnvironment $selectedProxy
    Write-Host "Transport: $(Get-HomeTeleProxyDisplay $selectedProxy)" -ForegroundColor Green
    Write-Host "Connected. The model runs remotely; code runs on THIS computer." -ForegroundColor Yellow
    Write-Host "Review every proposed command before approving it. Ctrl+C exits." -ForegroundColor Yellow
    & $venvPython $runner
    exit $LASTEXITCODE
}
catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
