[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSScriptRoot
$venvPython = Join-Path $packageRoot ".open-interpreter-venv\Scripts\python.exe"
$runner = Join-Path $PSScriptRoot "Run-OpenInterpreter.py"

try {
    if (-not (Test-Path -LiteralPath $venvPython)) {
        throw "Open Interpreter is not installed. Run 02-INSTALL-OPEN-INTERPRETER.cmd first."
    }
    if (-not (Test-Path -LiteralPath $runner)) {
        throw "Run-OpenInterpreter.py is missing. Extract the complete ZIP first."
    }

    Write-Host "Checking the VPN route to HomeTele AI..." -ForegroundColor Cyan
    $tcp = New-Object Net.Sockets.TcpClient
    try {
        $async = $tcp.BeginConnect("10.93.0.10", 8080, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(5000)) {
            throw "TCP timeout. Connect VLESS in TUN mode and route 10.93.0.10/32 through proxy."
        }
        $tcp.EndConnect($async)
    }
    finally {
        $tcp.Dispose()
    }

    Write-Host "Connected. The model runs remotely; code runs on THIS computer." -ForegroundColor Yellow
    Write-Host "Review every proposed command before approving it. Ctrl+C exits." -ForegroundColor Yellow
    & $venvPython $runner
    exit $LASTEXITCODE
}
catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

