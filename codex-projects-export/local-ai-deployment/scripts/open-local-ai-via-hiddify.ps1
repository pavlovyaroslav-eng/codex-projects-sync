[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [int]$TimeoutSeconds = 75
)

$ErrorActionPreference = 'Stop'
$stationAddress = '10.93.0.10'
$webUi = "http://${stationAddress}:3000"
$apiHealth = "http://${stationAddress}:8080/health"
$vpnServerName = 'matrix.hometele.com.ru'

function Test-TcpPort {
    param(
        [Parameter(Mandatory)] [string]$Address,
        [Parameter(Mandatory)] [int]$Port,
        [int]$TimeoutMilliseconds = 3000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $pending = $client.ConnectAsync($Address, $Port)
        return $pending.Wait($TimeoutMilliseconds) -and $client.Connected
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

$hiddify = Get-Process -Name Hiddify -ErrorAction SilentlyContinue
$hiddifyTun = Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Status -eq 'Up' -and
        ($_.Name -eq 'tun0' -or $_.InterfaceDescription -match 'sing-tun|Hiddify')
    } |
    Select-Object -First 1

if (-not $hiddify -or -not $hiddifyTun) {
    throw 'Hiddify is not connected. Connect the required Hiddify profile and run this script again.'
}

$vpnServerAddress = Resolve-DnsName $vpnServerName -Type A -ErrorAction Stop |
    Select-Object -First 1 -ExpandProperty IPAddress
$outerRoute = Find-NetRoute -RemoteIPAddress $vpnServerAddress -ErrorAction Stop |
    Select-Object -First 1
if ($outerRoute.InterfaceIndex -ne $hiddifyTun.ifIndex) {
    throw "The OpenVPN server route does not use Hiddify ($($hiddifyTun.Name))."
}

$openVpn = Get-Service -Name OpenVPNService -ErrorAction Stop
if ($openVpn.Status -ne 'Running') {
    throw 'OpenVPNService is not running. Start it from an elevated PowerShell session.'
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    $vpnAddress = Get-NetIPAddress -IPAddress '10.93.0.11' -ErrorAction SilentlyContinue
    if ($vpnAddress) {
        try {
            $innerRoute = Find-NetRoute -RemoteIPAddress $stationAddress -ErrorAction Stop |
                Select-Object -First 1
        }
        catch {
            $innerRoute = $null
        }
    }

    if ($vpnAddress -and $innerRoute -and
        $innerRoute.InterfaceAlias -match 'OpenVPN|TAP|Wintun') {
        break
    }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)

if (-not $vpnAddress -or -not $innerRoute) {
    throw 'The inner OpenVPN tunnel did not reconnect before the timeout.'
}

$sshReady = Test-TcpPort -Address $stationAddress -Port 22
try {
    $health = Invoke-RestMethod -Uri $apiHealth -TimeoutSec 5
    $apiReady = $health.status -eq 'ok'
}
catch {
    $apiReady = $false
}

if (-not $sshReady -or -not $apiReady) {
    throw "The VPN route exists, but AI station services are unavailable (SSH=$sshReady, API=$apiReady)."
}

[pscustomobject]@{
    Hiddify           = 'connected'
    OuterInterface    = $hiddifyTun.Name
    OpenVPN           = $openVpn.Status
    LaptopVPNAddress  = $vpnAddress.IPAddress
    AIStation         = $stationAddress
    InnerInterface    = $innerRoute.InterfaceAlias
    SSH               = $sshReady
    API               = $apiReady
    OpenWebUI         = $webUi
} | Format-List

if (-not $CheckOnly) {
    Start-Process $webUi
}
