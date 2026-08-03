[CmdletBinding()]
param(
    [string]$BaseUrl = "http://10.93.0.10:8080",
    [string]$Model = "qwen3-14b-q4km",
    [string]$ReportPath = "",
    [string]$ProxyUrl = ""
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'NetworkHelpers.ps1')
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportDirectory = Join-Path $packageRoot "reports"
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $ReportPath = Join-Path $reportDirectory "ai-station-test-$stamp.txt"
}

function Write-TestLine {
    param(
        [string]$Status,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )
    $line = "{0} {1}" -f $Status, $Message
    Write-Host $line -ForegroundColor $Color
    Add-Content -LiteralPath $ReportPath -Value $line -Encoding UTF8
}

$header = @(
    "HomeTele AI remote test v3",
    "UTC: $([DateTime]::UtcNow.ToString('o'))",
    "OS: $([Environment]::OSVersion.VersionString)",
    "PowerShell: $($PSVersionTable.PSVersion)",
    "Endpoint: $BaseUrl",
    "Expected model: $Model",
    "VPN credentials: not collected",
    ""
)
Set-Content -LiteralPath $ReportPath -Value $header -Encoding UTF8

$client = $null
$tcp = $null
$timer = [Diagnostics.Stopwatch]::StartNew()

try {
    $uri = [Uri]$BaseUrl

    try {
        $tcp = New-Object Net.Sockets.TcpClient
        $async = $tcp.BeginConnect($uri.Host, $uri.Port, $null, $null)
        if ($async.AsyncWaitHandle.WaitOne(3000)) {
            $tcp.EndConnect($async)
            Write-TestLine "[OK]" "Direct TCP $($uri.Host):$($uri.Port) (TUN/direct route is available)" Green
        }
        else {
            Write-TestLine "[INFO]" "Direct TCP is unavailable; this is normal in proxy-only VLESS mode." DarkYellow
        }
    }
    catch {
        Write-TestLine "[INFO]" "Direct TCP is unavailable; this is normal in proxy-only VLESS mode." DarkYellow
    }
    finally {
        if ($null -ne $tcp) { $tcp.Dispose(); $tcp = $null }
    }

    $preferredProxy = $null
    if (-not [string]::IsNullOrWhiteSpace($ProxyUrl)) {
        $explicitUri = ConvertTo-HomeTeleProxyUri $ProxyUrl
        if ($null -eq $explicitUri) {
            throw "ProxyUrl must be an HTTP proxy URL, for example http://127.0.0.1:10809."
        }
        $preferredProxy = [PSCustomObject]@{ Uri = $explicitUri; Source = 'explicit proxy' }
    }
    $candidates = @()
    if ($null -ne $preferredProxy) {
        $candidates += ,$preferredProxy
    }
    else {
        $candidates += @(Get-HomeTeleProxyCandidates $uri)
    }
    $candidates += ,$null
    $selectedProxy = $null
    $health = $null
    $probeErrors = @()
    foreach ($candidate in $candidates) {
        $probe = $null
        try {
            $probe = New-HomeTeleHttpClient $candidate
            $probe.Timeout = [TimeSpan]::FromSeconds(15)
            $response = $probe.GetAsync("$BaseUrl/health").GetAwaiter().GetResult()
            $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            if (-not $response.IsSuccessStatusCode) { throw "HTTP $([int]$response.StatusCode)" }
            $parsed = $body | ConvertFrom-Json
            if ($parsed.status -ne 'ok') { throw 'unexpected health response' }
            $selectedProxy = $candidate
            $health = $parsed
            break
        }
        catch {
            $probeErrors += "$(Get-HomeTeleProxyDisplay $candidate): $($_.Exception.GetBaseException().Message)"
        }
        finally {
            if ($null -ne $probe) { $probe.Dispose() }
        }
    }
    if ($null -eq $health) {
        throw "HTTP connection failed through all transports: $($probeErrors -join ' | '). The server does not require ping; connect VLESS and enable Windows system proxy or TUN."
    }

    Write-TestLine "[OK]" "Transport: $(Get-HomeTeleProxyDisplay $selectedProxy)" Green
    Write-TestLine "[OK]" "GET /health" Green

    $client = New-HomeTeleHttpClient $selectedProxy
    $client.Timeout = [TimeSpan]::FromSeconds(120)

    $modelsResponse = $client.GetAsync("$BaseUrl/v1/models").GetAwaiter().GetResult()
    $modelsBody = $modelsResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if (-not $modelsResponse.IsSuccessStatusCode) {
        throw "GET /v1/models returned HTTP $([int]$modelsResponse.StatusCode)."
    }
    $modelsObject = $modelsBody | ConvertFrom-Json
    $modelIds = @($modelsObject.data | ForEach-Object { $_.id })
    if ($modelIds -notcontains $Model) {
        throw "Expected model '$Model' was not found. Available count: $($modelIds.Count)."
    }
    Write-TestLine "[OK]" "GET /v1/models: $Model" Green

    $rootResponse = $client.GetAsync("$BaseUrl/").GetAwaiter().GetResult()
    $rootBody = $rootResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if (-not $rootResponse.IsSuccessStatusCode -or $rootBody.Length -lt 100) {
        throw "Web UI check failed: HTTP $([int]$rootResponse.StatusCode), bytes $($rootBody.Length)."
    }
    Write-TestLine "[OK]" "Web UI with gzip: HTTP $([int]$rootResponse.StatusCode)" Green

    $payload = @{
        model = $Model
        messages = @(
            @{ role = "user"; content = "Reply in one short Russian sentence: is the remote AI station available?" }
        )
        temperature = 0
        max_tokens = 64
        stream = $false
        chat_template_kwargs = @{ enable_thinking = $false }
    } | ConvertTo-Json -Depth 8 -Compress

    $content = New-Object System.Net.Http.StringContent($payload, [Text.Encoding]::UTF8, "application/json")
    $chatResponse = $client.PostAsync("$BaseUrl/v1/chat/completions", $content).GetAwaiter().GetResult()
    $chatBody = $chatResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if (-not $chatResponse.IsSuccessStatusCode) {
        throw "POST /v1/chat/completions returned HTTP $([int]$chatResponse.StatusCode)."
    }
    $chat = $chatBody | ConvertFrom-Json
    $answer = [string]$chat.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($answer)) {
        throw "Chat Completions returned an empty answer."
    }
    foreach ($marker in @([string][char]0x00D0, [string][char]0x00D1, [string][char]0x00C3, [string][char]0x00C2, [string][char]0xFFFD)) {
        if ($answer.Contains($marker)) {
            throw "The model answer contains a possible UTF-8 mojibake marker."
        }
    }
    $cyrillicPattern = '[{0}-{1}{2}{3}]' -f [char]0x0410, [char]0x044F, [char]0x0401, [char]0x0451
    if ($answer -notmatch $cyrillicPattern) {
        throw "The answer does not contain expected Cyrillic text."
    }
    Write-TestLine "[OK]" "Chat Completions: non-empty UTF-8 answer ($($answer.Length) chars)" Green

    $timer.Stop()
    Write-TestLine "[OK]" "Total duration: $([Math]::Round($timer.Elapsed.TotalSeconds, 2)) s" Green
    Write-TestLine "PASS" "Remote AI station is available through VLESS/VPN." Green
    Write-Host "Report: $ReportPath" -ForegroundColor Cyan
    exit 0
}
catch {
    $timer.Stop()
    Write-TestLine "[FAIL]" $_.Exception.Message Red
    Write-TestLine "FAIL" "Remote AI station test did not complete." Red
    Write-Host "Report: $ReportPath" -ForegroundColor Yellow
    exit 1
}
finally {
    if ($null -ne $client) { $client.Dispose() }
}
