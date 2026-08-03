[CmdletBinding()]
param(
    [string]$ProfilePath = (Join-Path $env:USERPROFILE '.local-ai-vpn\owner-laptop.ovpn')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated PowerShell session.'
}
if (-not (Test-Path -LiteralPath $ProfilePath)) {
    throw "OpenVPN profile not found: $ProfilePath"
}

$logRoot = Join-Path $env:ProgramData 'LocalAI-Deployment\logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$logPath = Join-Path $logRoot ("windows-openvpn-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -LiteralPath $logPath -Force | Out-Null
trap {
    Write-Error $_
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    exit 1
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rollbackPath = Join-Path $env:ProgramData "LocalAI-Deployment\rollback\windows-openvpn-$stamp"
New-Item -ItemType Directory -Force -Path $rollbackPath | Out-Null

$winget = (Get-Command winget.exe -ErrorAction Stop).Source
$packageId = 'OpenVPNTechnologies.OpenVPN'
$wasInstalled = $false
& $winget list --id $packageId --exact --accept-source-agreements --disable-interactivity | Out-Null
if ($LASTEXITCODE -eq 0) {
    $wasInstalled = $true
}

$manifest = [ordered]@{
    CreatedAt = (Get-Date).ToString('o')
    PackageId = $packageId
    PackageWasInstalled = $wasInstalled
    ProfilePath = $ProfilePath
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $rollbackPath 'manifest.json') -Encoding utf8

if (-not $wasInstalled) {
    & $winget install --id $packageId --exact --scope machine --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed with exit code $LASTEXITCODE"
    }
}

$openVpnRoot = Join-Path $env:ProgramFiles 'OpenVPN'
$configAuto = Join-Path $openVpnRoot 'config-auto'
if (-not (Test-Path -LiteralPath $openVpnRoot)) {
    throw "OpenVPN installation directory not found: $openVpnRoot"
}
New-Item -ItemType Directory -Force -Path $configAuto | Out-Null

$targetProfile = Join-Path $configAuto 'owner-laptop.ovpn'
if (Test-Path -LiteralPath $targetProfile) {
    Copy-Item -LiteralPath $targetProfile -Destination (Join-Path $rollbackPath 'owner-laptop.ovpn.previous')
}
Copy-Item -LiteralPath $ProfilePath -Destination $targetProfile -Force
$openVpnServiceSid = '*S-1-5-80-3750127322-3829920079-842246558-474445854-3948885660:R'
& icacls.exe $targetProfile '/inheritance:r' '/grant:r' '*S-1-5-18:F' '*S-1-5-32-544:F' $openVpnServiceSid | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to restrict the OpenVPN profile ACL.'
}

$service = Get-Service -Name 'OpenVPNService' -ErrorAction Stop
Set-Service -Name $service.Name -StartupType Automatic
if ($service.Status -eq 'Running') {
    Restart-Service -Name $service.Name -Force
}
else {
    Start-Service -Name $service.Name
}

$connected = $false
for ($attempt = 1; $attempt -le 20; $attempt++) {
    Start-Sleep -Seconds 1
    if (Get-NetIPAddress -IPAddress '10.93.0.11' -ErrorAction SilentlyContinue) {
        $connected = $true
        break
    }
}
if (-not $connected) {
    $logDirectory = Join-Path $env:ProgramData 'OpenVPN\Log'
    throw "OpenVPN service started, but 10.93.0.11 was not assigned. Check $logDirectory"
}

$defaultViaTunnel = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -match 'OpenVPN|Wintun|TAP' }
if ($defaultViaTunnel) {
    throw 'Unexpected default route through OpenVPN was detected.'
}

Write-Host 'OpenVPN client installed and connected.'
Write-Host 'VPN address: 10.93.0.11'
Write-Host "Autostart service: $($service.Name)"
Write-Host "Rollback backup: $rollbackPath"
Write-Host "Installation log: $logPath"
Stop-Transcript | Out-Null
