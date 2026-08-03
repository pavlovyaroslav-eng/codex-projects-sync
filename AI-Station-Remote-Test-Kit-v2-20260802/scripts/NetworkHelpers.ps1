Set-StrictMode -Version 2.0

function ConvertTo-HomeTeleProxyUri {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $candidate = $Value.Trim()
    if ($candidate -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        $candidate = "http://$candidate"
    }
    try {
        $uri = [Uri]$candidate
        if ($uri.Scheme -notin @('http', 'https')) { return $null }
        return $uri
    }
    catch { return $null }
}

function Get-HomeTeleProxyCandidates {
    param([Parameter(Mandatory = $true)][Uri]$TargetUri)

    $rawCandidates = @()
    $uri = ConvertTo-HomeTeleProxyUri ([Environment]::GetEnvironmentVariable('HOMETELE_PROXY'))
    if ($null -ne $uri) {
        $rawCandidates += [PSCustomObject]@{ Uri = $uri; Source = 'environment (HOMETELE_PROXY)' }
    }

    try {
        $defaultProxy = [Net.WebRequest]::DefaultWebProxy
        if ($null -ne $defaultProxy -and -not $defaultProxy.IsBypassed($TargetUri)) {
            $proxyUri = $defaultProxy.GetProxy($TargetUri)
            if ($null -ne $proxyUri -and $proxyUri.AbsoluteUri -ne $TargetUri.AbsoluteUri) {
                $rawCandidates += [PSCustomObject]@{ Uri = $proxyUri; Source = 'Windows system proxy' }
            }
        }
    }
    catch { }

    try {
        $settings = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
        if ([int]$settings.ProxyEnable -eq 1) {
            $raw = [string]$settings.ProxyServer
            $selected = $raw
            if ($raw.Contains('=')) {
                $entries = @{}
                foreach ($part in $raw.Split(';')) {
                    if ($part -match '^\s*([^=]+)=(.+)$') {
                        $entries[$Matches[1].Trim().ToLowerInvariant()] = $Matches[2].Trim()
                    }
                }
                if ($entries.ContainsKey('http')) { $selected = $entries['http'] }
                elseif ($entries.ContainsKey('https')) { $selected = $entries['https'] }
                else { $selected = '' }
            }
            $proxyUri = ConvertTo-HomeTeleProxyUri $selected
            if ($null -ne $proxyUri) {
                $rawCandidates += [PSCustomObject]@{ Uri = $proxyUri; Source = 'Windows proxy settings' }
            }
        }
    }
    catch { }

    $environmentNames = @()
    if ($TargetUri.Scheme -eq 'http') {
        $environmentNames += @('HTTP_PROXY', 'http_proxy')
    }
    else {
        $environmentNames += @('HTTPS_PROXY', 'https_proxy')
    }
    foreach ($name in $environmentNames) {
        $value = [Environment]::GetEnvironmentVariable($name)
        $uri = ConvertTo-HomeTeleProxyUri $value
        if ($null -ne $uri) {
            $rawCandidates += [PSCustomObject]@{ Uri = $uri; Source = "environment ($name)" }
        }
    }

    foreach ($port in @(10809, 7890, 2081, 12334)) {
        $socket = $null
        try {
            $socket = New-Object Net.Sockets.TcpClient
            $pending = $socket.BeginConnect('127.0.0.1', $port, $null, $null)
            if ($pending.AsyncWaitHandle.WaitOne(150)) {
                $socket.EndConnect($pending)
                $rawCandidates += [PSCustomObject]@{
                    Uri = [Uri]("http://127.0.0.1:$port")
                    Source = 'auto-detected local HTTP proxy'
                }
            }
        }
        catch { }
        finally { if ($null -ne $socket) { $socket.Dispose() } }
    }

    $seen = @{}
    foreach ($candidate in $rawCandidates) {
        $key = $candidate.Uri.AbsoluteUri.ToLowerInvariant()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            Write-Output $candidate
        }
    }
}

function Get-HomeTeleProxyConfiguration {
    param([Parameter(Mandatory = $true)][Uri]$TargetUri)

    $candidates = @(Get-HomeTeleProxyCandidates $TargetUri)
    if ($candidates.Count -gt 0) { return $candidates[0] }
    return $null
}

function Get-HomeTeleProxyDisplay {
    param($ProxyConfiguration)

    if ($null -eq $ProxyConfiguration) { return 'direct/TUN' }
    $uri = [Uri]$ProxyConfiguration.Uri
    return "{0} via {1}://{2}:{3}" -f $ProxyConfiguration.Source, $uri.Scheme, $uri.Host, $uri.Port
}

function New-HomeTeleHttpClient {
    param($ProxyConfiguration)

    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
    if ($null -eq $ProxyConfiguration) {
        $handler.UseProxy = $false
    }
    else {
        $handler.UseProxy = $true
        $handler.Proxy = New-Object Net.WebProxy($ProxyConfiguration.Uri.AbsoluteUri, $false)
    }
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.DefaultRequestHeaders.AcceptEncoding.ParseAdd('gzip, deflate')
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('HomeTele-AI-Remote-Test/2.0')
    return $client
}

function Set-HomeTeleProxyEnvironment {
    param($ProxyConfiguration)

    if ($null -eq $ProxyConfiguration) { return }
    $value = $ProxyConfiguration.Uri.AbsoluteUri
    foreach ($name in @('HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy')) {
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
    [Environment]::SetEnvironmentVariable('NO_PROXY', 'localhost,127.0.0.1', 'Process')
    [Environment]::SetEnvironmentVariable('no_proxy', 'localhost,127.0.0.1', 'Process')
}
