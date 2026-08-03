#requires -Version 5.1

# Read-only critical recheck for control point 1. This script only reads
# event logs, Windows Recovery Environment state, Secure Boot/BCD state,
# and Microsoft Defender status.

[CmdletBinding()]
param(
    [string]$OutputPath = 'C:\LocalAI-Deployment\inventory\stage1-critical-recheck.txt'
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

Start-Transcript -LiteralPath $OutputPath -Force | Out-Null
try {
    Write-Output '===== WHEA (EXACT PROVIDER) ====='
    $wheaEvents = @(
        Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-WHEA-Logger'
            StartTime    = (Get-Date).AddDays(-30)
        } -ErrorAction SilentlyContinue
    )
    Write-Output ("WHEA event count (30 days): {0}" -f $wheaEvents.Count)
    $wheaEvents |
        Select-Object -First 20 TimeCreated, Id, LevelDisplayName, ProviderName, Message |
        Format-List

    Write-Output '===== WINDOWS MEMORY DIAGNOSTIC ====='
    $memoryEvents = @(
        Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
            StartTime    = (Get-Date).AddDays(-365)
        } -ErrorAction SilentlyContinue
    )
    Write-Output ("Memory diagnostic event count (365 days): {0}" -f $memoryEvents.Count)
    $memoryEvents |
        Select-Object -First 10 TimeCreated, Id, LevelDisplayName, ProviderName, Message |
        Format-List

    Write-Output '===== WINDOWS RECOVERY ENVIRONMENT ====='
    try {
        & reagentc.exe /info 2>&1
        Write-Output ("reagentc /info exit: {0}" -f $LASTEXITCODE)
    }
    catch {
        Write-Output ("reagentc /info invocation error: {0}" -f $_.Exception.Message)
    }
    try {
        & reagentc.exe /info /target C:\Windows 2>&1
        Write-Output ("reagentc /info /target exit: {0}" -f $LASTEXITCODE)
    }
    catch {
        Write-Output ("reagentc /info /target invocation error: {0}" -f $_.Exception.Message)
    }
    @(
        'C:\Windows\System32\Recovery\ReAgent.xml',
        'C:\Windows\System32\Recovery\Winre.wim',
        'C:\Recovery\WindowsRE\Winre.wim'
    ) | ForEach-Object {
        [pscustomobject]@{
            Path   = $_
            Exists = Test-Path -LiteralPath $_
        }
    } | Format-Table -AutoSize
    Get-ChildItem -LiteralPath 'C:\Windows\System32\Recovery' -Force -ErrorAction SilentlyContinue |
        Select-Object FullName, Length, LastWriteTime, Attributes |
        Format-Table -AutoSize
    Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinRE' -ErrorAction SilentlyContinue |
        Format-List *

    Write-Output '===== SECURE BOOT / BCD ====='
    try {
        $secureBootEnabled = Confirm-SecureBootUEFI -ErrorAction Stop
        Write-Output ("Confirm-SecureBootUEFI: {0}" -f $secureBootEnabled)
    }
    catch {
        Write-Output ("Confirm-SecureBootUEFI error: {0}" -f $_.Exception.Message)
        Write-Output ("Confirm-SecureBootUEFI HRESULT: 0x{0:X8}" -f ($_.Exception.HResult -band 0xffffffffL))
    }
    $secureBootState = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction SilentlyContinue
    if ($null -ne $secureBootState) {
        $secureBootState |
            Select-Object UEFISecureBootEnabled |
            Format-List
    }
    else {
        Write-Output 'Secure Boot State registry key is absent.'
    }
    try {
        & bcdedit.exe /enum '{current}' 2>&1
        Write-Output ("bcdedit current exit: {0}" -f $LASTEXITCODE)
    }
    catch {
        Write-Output ("bcdedit current invocation error: {0}" -f $_.Exception.Message)
    }
    try {
        & bcdedit.exe /enum '{bootmgr}' 2>&1
        Write-Output ("bcdedit bootmgr exit: {0}" -f $LASTEXITCODE)
    }
    catch {
        Write-Output ("bcdedit bootmgr invocation error: {0}" -f $_.Exception.Message)
    }

    Write-Output '===== MICROSOFT DEFENDER ====='
    Get-Service -Name WinDefend, WdNisSvc, SecurityHealthService -ErrorAction SilentlyContinue |
        Select-Object Name, Status, StartType |
        Format-Table -AutoSize
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        Get-MpComputerStatus |
            Select-Object AMServiceEnabled, AntivirusEnabled, AntispywareEnabled,
                BehaviorMonitorEnabled, IoavProtectionEnabled, NISEnabled,
                OnAccessProtectionEnabled, RealTimeProtectionEnabled,
                IsTamperProtected, AntivirusSignatureLastUpdated,
                AntivirusSignatureVersion, QuickScanAge, FullScanAge |
            Format-List
    }
    else {
        Write-Output 'Get-MpComputerStatus is unavailable.'
    }
}
finally {
    Stop-Transcript | Out-Null
}
