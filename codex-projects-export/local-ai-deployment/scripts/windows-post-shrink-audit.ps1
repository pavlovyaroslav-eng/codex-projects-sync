#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$OutputPath = 'C:\LocalAI-Deployment\inventory\disk-layout-after-shrink.txt'
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

Start-Transcript -LiteralPath $OutputPath -Force | Out-Null
try {
    Write-Output '===== DISK / PARTITIONS AFTER SHRINK ====='
    Get-Disk -Number 0 |
        Select-Object Number, FriendlyName, SerialNumber, BusType, PartitionStyle,
            IsBoot, IsSystem, HealthStatus, OperationalStatus, Size |
        Format-List
    Get-Partition -DiskNumber 0 |
        Select-Object DiskNumber, PartitionNumber, DriveLetter, Type, GptType,
            Size, Offset |
        Format-Table -AutoSize
    Get-Volume -DriveLetter C |
        Select-Object DriveLetter, FileSystemType, HealthStatus, OperationalStatus,
            Size, SizeRemaining |
        Format-List

    $partition = Get-Partition -DiskNumber 0 -PartitionNumber 3
    $disk = Get-Disk -Number 0
    $unallocatedBytes = [UInt64]$disk.Size - ([UInt64]$partition.Offset + [UInt64]$partition.Size)
    [pscustomobject]@{
        WindowsPartitionBytes = $partition.Size
        WindowsPartitionGiB   = [math]::Round($partition.Size / 1GB, 2)
        UnallocatedBytes      = $unallocatedBytes
        UnallocatedGiB        = [math]::Round($unallocatedBytes / 1GB, 2)
    } | Format-List

    Write-Output '===== SUPPORTED SIZE / BITLOCKER / HIBERNATION ====='
    Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 3 |
        Format-List SizeMin, SizeMax
    Get-BitLockerVolume -MountPoint C: |
        Select-Object MountPoint, VolumeStatus, ProtectionStatus,
            EncryptionPercentage, EncryptionMethod, KeyProtector |
        Format-List
    Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' |
        Select-Object HiberbootEnabled |
        Format-List
    Write-Output ("hiberfil_exists={0}" -f (Test-Path -LiteralPath 'C:\hiberfil.sys'))

    Write-Output '===== REMOTE ACCESS STILL LISTENING ====='
    Get-Service -Name sshd, TermService, WinRM, LanmanServer |
        Select-Object Name, Status, StartType |
        Format-Table -AutoSize
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object LocalPort -in 22, 445, 3389, 5985 |
        Select-Object LocalAddress, LocalPort, State, OwningProcess |
        Sort-Object LocalPort |
        Format-Table -AutoSize
}
finally {
    Stop-Transcript | Out-Null
}
