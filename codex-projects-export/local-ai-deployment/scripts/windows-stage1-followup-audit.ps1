#requires -Version 5.1

# Read-only follow-up checks for control point 1. This script does not alter
# disks, boot configuration, firmware, drivers, firewall, services, or accounts.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

Write-Output '===== SHRINK LIMIT ====='
Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 3 |
    Select-Object SizeMin, SizeMax,
        @{Name='SizeMinGiB';Expression={[math]::Round($_.SizeMin / 1GB, 2)}},
        @{Name='SizeMaxGiB';Expression={[math]::Round($_.SizeMax / 1GB, 2)}} |
    Format-List
Get-Partition -DiskNumber 0 -PartitionNumber 3 |
    Select-Object DiskNumber, PartitionNumber, DriveLetter, Size,
        @{Name='SizeGiB';Expression={[math]::Round($_.Size / 1GB, 2)}}, Offset |
    Format-List
Get-Volume -DriveLetter C |
    Select-Object Size, SizeRemaining,
        @{Name='SizeGiB';Expression={[math]::Round($_.Size / 1GB, 2)}},
        @{Name='FreeGiB';Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
        HealthStatus |
    Format-List

Write-Output '===== DISK / FIRMWARE / HEALTH ====='
Get-PhysicalDisk | Sort-Object DeviceId |
    Select-Object DeviceId, FriendlyName, SerialNumber, FirmwareVersion,
        MediaType, BusType, HealthStatus, OperationalStatus, Size |
    Format-Table -AutoSize
Get-CimInstance Win32_DiskDrive |
    Select-Object Index, Model, FirmwareRevision, SerialNumber, InterfaceType,
        MediaType, Size, Status |
    Format-Table -AutoSize
$nvme = Get-PhysicalDisk | Where-Object BusType -eq 'NVMe' | Select-Object -First 1
if ($nvme) {
    $nvme | Get-StorageReliabilityCounter |
        Format-List Temperature, TemperatureMax, Wear, PowerOnHours,
            ReadErrorsTotal, ReadErrorsUncorrected, WriteErrorsTotal,
            WriteErrorsUncorrected, ReadLatencyMax, WriteLatencyMax,
            FlushLatencyMax
}

Write-Output '===== WINRE / SECURE BOOT ====='
& reagentc.exe /info /target C:\Windows 2>&1
Write-Output "reagentc_exit=$LASTEXITCODE"
Get-ChildItem -LiteralPath 'C:\Windows\System32\Recovery' -Force -ErrorAction SilentlyContinue |
    Select-Object Name, Length, LastWriteTime |
    Format-Table -AutoSize
Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction SilentlyContinue |
    Select-Object UEFISecureBootEnabled |
    Format-List

Write-Output '===== CPU FEATURES / NUMA ====='
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class LocalAiNativeAudit {
  [DllImport("kernel32.dll")] public static extern bool IsProcessorFeaturePresent(uint feature);
  [DllImport("kernel32.dll", SetLastError=true)] public static extern bool GetNumaHighestNodeNumber(out uint highestNodeNumber);
  [DllImport("kernel32.dll")] public static extern uint GetActiveProcessorCount(ushort groupNumber);
}
"@ -ErrorAction SilentlyContinue
$highest = [uint32]0
$numaOk = [LocalAiNativeAudit]::GetNumaHighestNodeNumber([ref]$highest)
[pscustomobject]@{
    AVX                     = [LocalAiNativeAudit]::IsProcessorFeaturePresent(39)
    AVX2                    = [LocalAiNativeAudit]::IsProcessorFeaturePresent(40)
    NumaApiSuccess          = $numaOk
    HighestNumaNode         = $highest
    NumaNodeCount           = if ($numaOk) { $highest + 1 } else { $null }
    ActiveLogicalProcessors = [LocalAiNativeAudit]::GetActiveProcessorCount(0xffff)
} | Format-List
Get-CimInstance Win32_PerfFormattedData_PerfOS_NUMANodeMemory -ErrorAction SilentlyContinue |
    Select-Object Name, AvailableMBytes, TotalMBytes |
    Format-Table -AutoSize

Write-Output '===== WHEA / MEMORY DIAGNOSTIC ====='
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id = 18,19,20,46,47
    StartTime = (Get-Date).AddDays(-30)
} -ErrorAction SilentlyContinue |
    Select-Object -First 10 TimeCreated, Id, LevelDisplayName, ProviderName, Message |
    Format-List
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
    StartTime = (Get-Date).AddDays(-365)
} -ErrorAction SilentlyContinue |
    Select-Object -First 5 TimeCreated, Id, LevelDisplayName, Message |
    Format-List

Write-Output '===== NETWORK LINK ====='
Get-NetAdapter -Name 'Ethernet' |
    Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed,
        DriverVersion, DriverDate |
    Format-List
Get-NetAdapterAdvancedProperty -Name 'Ethernet' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Speed|Duplex|Скорост|дуплекс' } |
    Select-Object DisplayName, DisplayValue, RegistryKeyword, RegistryValue |
    Format-List
Get-NetAdapterStatistics -Name 'Ethernet' |
    Format-List ReceivedBytes, SentBytes, ReceivedPacketErrors,
        OutboundPacketErrors, ReceivedDiscardedPackets, OutboundDiscardedPackets
