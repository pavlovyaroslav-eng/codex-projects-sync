[CmdletBinding()]
param(
    [string]$BaseUrl = "http://10.93.0.10:8080",
    [string]$Model = "qwen3-14b-q4km",
    [string]$ReportPath = ""
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSScriptRoot
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
    "HomeTele AI remote test",
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

    $tcp = New-Object Net.Sockets.TcpClient
    $async = $tcp.BeginConnect($uri.Host, $uri.Port, $null, $null)
    if (-not $async.AsyncWaitHandle.WaitOne(5000)) {
        throw "TCP timeout. Check VLESS, TUN mode and the route 10.93.0.10/32 -> proxy."
    }
    $tcp.EndConnect($async)
    Write-TestLine "[OK]" "TCP $($uri.Host):$($uri.Port)" Green
    $tcp.Close()
    $tcp = $null

    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.UseProxy = $false
    $handler.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(120)
    $client.DefaultRequestHeaders.AcceptEncoding.ParseAdd("gzip, deflate")
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("HomeTele-AI-Remote-Test/1.0")

    $healthResponse = $client.GetAsync("$BaseUrl/health").GetAwaiter().GetResult()
    $healthBody = $healthResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if (-not $healthResponse.IsSuccessStatusCode) {
        throw "GET /health returned HTTP $([int]$healthResponse.StatusCode)."
    }
    $health = $healthBody | ConvertFrom-Json
    if ($health.status -ne "ok") {
        throw "GET /health returned an unexpected status."
    }
    Write-TestLine "[OK]" "GET /health" Green

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
            @{ role = "user"; content = "Ответь одним коротким предложением по-русски: удалённая ИИ-станция доступна?" }
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
    foreach ($marker in @("Ð", "Ñ", "Ã", "Â", [string][char]0xFFFD)) {
        if ($answer.Contains($marker)) {
            throw "The model answer contains a possible UTF-8 mojibake marker."
        }
    }
    if ($answer -notmatch "[А-Яа-яЁё]") {
        throw "The answer does not contain expected Cyrillic text."
    }
    Write-TestLine "[OK]" "Chat Completions: non-empty UTF-8 answer ($($answer.Length) chars)" Green

    $timer.Stop()
    Write-TestLine "[OK]" "Total duration: $([Math]::Round($timer.Elapsed.TotalSeconds, 2)) s" Green
    Write-TestLine "PASS" "Remote AI station is available through the VPN." Green
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
    if ($null -ne $tcp) { $tcp.Dispose() }
    if ($null -ne $client) { $client.Dispose() }
}

