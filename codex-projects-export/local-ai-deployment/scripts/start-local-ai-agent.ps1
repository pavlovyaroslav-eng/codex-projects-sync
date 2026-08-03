[CmdletBinding()]
param(
    [ValidateSet('aider', 'opencode')]
    [string]$Agent = 'aider',

    [ValidateSet('coder30', 'qwen14', 'qwen-vl')]
    [string]$Profile = 'coder30',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AgentArguments
)

$ErrorActionPreference = 'Stop'
$stationAddress = '10.93.0.10'
$apiBase = "http://${stationAddress}:8080/v1"
$sshKey = Join-Path $env:USERPROFILE '.ssh\id_ed25519_local_ai_admin_v2'
$ssh = (Get-Command ssh.exe -ErrorAction Stop).Source

$modelByProfile = @{
    'coder30' = 'qwen3-coder-30b-a3b-q4km'
    'qwen14'  = 'qwen3-14b-q4km'
    'qwen-vl' = 'qwen3-vl-8b-q4km'
}

if (-not (Test-Path -LiteralPath $sshKey)) {
    throw "SSH key not found: $sshKey"
}

$tcp = [System.Net.Sockets.TcpClient]::new()
try {
    $connect = $tcp.ConnectAsync($stationAddress, 22)
    if (-not $connect.Wait(3000) -or -not $tcp.Connected) {
        throw "The AI station is unavailable at ${stationAddress}:22. Connect OpenVPN first."
    }
}
finally {
    $tcp.Dispose()
}

Write-Host "Selecting AI profile '$Profile' on $stationAddress ..."
& $ssh -i $sshKey -o BatchMode=yes -o ConnectTimeout=5 -o HostKeyAlias=192.168.1.65 "user@$stationAddress" "sudo ai-model start $Profile"
if ($LASTEXITCODE -ne 0) {
    throw "Unable to select AI profile '$Profile'."
}

$ready = $false
for ($attempt = 1; $attempt -le 24; $attempt++) {
    try {
        $health = Invoke-RestMethod -Uri "http://${stationAddress}:8080/health" -TimeoutSec 3
        if ($health.status -eq 'ok') {
            $ready = $true
            break
        }
    }
    catch {}
    Start-Sleep -Seconds 2
}
if (-not $ready) {
    throw "The selected model did not become ready at $apiBase."
}

$model = $modelByProfile[$Profile]
switch ($Agent) {
    'aider' {
        $executable = Join-Path $env:USERPROFILE '.local\bin\aider.exe'
        if (-not (Test-Path -LiteralPath $executable)) {
            throw "Aider is not installed at $executable"
        }
        & $executable --model "openai/$model" @AgentArguments
    }
    'opencode' {
        $command = Get-Command opencode.cmd -ErrorAction SilentlyContinue
        if (-not $command) {
            $fallback = 'E:\EngineeringTools\npm-global\opencode.cmd'
            if (-not (Test-Path -LiteralPath $fallback)) {
                throw 'OpenCode is not installed.'
            }
            $executable = $fallback
        }
        else {
            $executable = $command.Source
        }
        & $executable --model "local-ai/$model" @AgentArguments
    }
}

exit $LASTEXITCODE
