#requires -Version 5.1

# This script performs the Windows-side preparation for the approved dual-boot
# layout. It refuses to change the disk unless both physical recovery conditions
# are explicitly acknowledged and all disk identity/safety checks pass.

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$BackupConfirmed,
    [switch]$RecoveryUsbBootConfirmed,
    [switch]$OwnerAcceptedMissingRecoverySafeguards,
    [switch]$AuditOnly,
    [UInt64]$WindowsTargetSize = 420GB,
    [int]$DiskNumber = 0,
    [int]$WindowsPartitionNumber = 3,
    [string]$ExpectedDiskModel = 'Samsung SSD 990 PRO 1TB',
    [string]$ExpectedDiskSerial = '0025_384B_41A0_6E2A.',
    [UInt64]$ExpectedDiskSize = 1000204886016,
    [string]$BackupDirectory = 'C:\LocalAI-Deployment\rollback\dualboot'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script from an elevated Windows PowerShell session.'
    }
}

Assert-Administrator

if (-not (($BackupConfirmed -and $RecoveryUsbBootConfirmed) -or $OwnerAcceptedMissingRecoverySafeguards)) {
    throw 'Refusing disk changes: verify backup and Recovery USB, or explicitly accept the missing safeguards.'
}

$disk = Get-Disk -Number $DiskNumber
if ($disk.FriendlyName -ne $ExpectedDiskModel) {
    throw "Disk identity mismatch: expected '$ExpectedDiskModel', found '$($disk.FriendlyName)'."
}
if ($disk.SerialNumber.Trim() -ne $ExpectedDiskSerial) {
    throw "Disk serial mismatch: expected '$ExpectedDiskSerial', found '$($disk.SerialNumber.Trim())'."
}
if ([UInt64]$disk.Size -ne $ExpectedDiskSize) {
    throw "Disk size mismatch: expected $ExpectedDiskSize, found $($disk.Size)."
}
if ($disk.PartitionStyle -ne 'GPT' -or -not $disk.IsBoot -or -not $disk.IsSystem) {
    throw 'Disk 0 is no longer the expected GPT boot/system disk.'
}

$partition = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $WindowsPartitionNumber
if ($partition.DriveLetter -ne 'C' -or $partition.Type -ne 'Basic') {
    throw 'Partition identity mismatch: expected the Basic C: partition.'
}

$bitLocker = Get-BitLockerVolume -MountPoint 'C:'
if ($bitLocker.ProtectionStatus -ne 'Off' -or $bitLocker.VolumeStatus -ne 'FullyDecrypted') {
    throw 'BitLocker is enabled or C: is not fully decrypted.'
}

$supported = Get-PartitionSupportedSize -DiskNumber $DiskNumber -PartitionNumber $WindowsPartitionNumber
if ($WindowsTargetSize -lt [UInt64]$supported.SizeMin -or $WindowsTargetSize -gt [UInt64]$supported.SizeMax) {
    throw "Target size $WindowsTargetSize is outside supported range $($supported.SizeMin)..$($supported.SizeMax)."
}

$recoveryFiles = @(
    'C:\Windows\System32\Recovery\ReAgent.xml',
    'C:\Windows\System32\Recovery\Winre.wim',
    'C:\Recovery\WindowsRE\Winre.wim'
)
$winRePresent = $recoveryFiles | Where-Object { Test-Path -LiteralPath $_ }
if (-not $winRePresent) {
    Write-Warning 'Local WinRE remains unavailable.'
}
if ($OwnerAcceptedMissingRecoverySafeguards) {
    Write-Warning 'Owner explicitly accepted proceeding without confirmed external backup/Recovery USB safeguards.'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runBackup = Join-Path $BackupDirectory $timestamp
New-Item -Path $runBackup -ItemType Directory -Force | Out-Null

$preflight = [pscustomobject]@{
    Timestamp              = (Get-Date).ToString('o')
    DiskNumber             = $disk.Number
    DiskModel              = $disk.FriendlyName
    DiskSerialNumber       = $disk.SerialNumber
    DiskSize               = $disk.Size
    PartitionNumber        = $partition.PartitionNumber
    CurrentPartitionSize   = $partition.Size
    TargetPartitionSize    = $WindowsTargetSize
    SupportedMinimum       = $supported.SizeMin
    SupportedMaximum       = $supported.SizeMax
    BitLockerStatus        = $bitLocker.VolumeStatus
    BitLockerProtection    = $bitLocker.ProtectionStatus
    RecoveryUsbAcknowledged = [bool]$RecoveryUsbBootConfirmed
    BackupAcknowledged     = [bool]$BackupConfirmed
    MissingSafeguardsAccepted = [bool]$OwnerAcceptedMissingRecoverySafeguards
}
$preflight | ConvertTo-Json -Depth 3 |
    Set-Content -LiteralPath (Join-Path $runBackup 'preflight.json') -Encoding UTF8

$bcdBackupPath = Join-Path $runBackup 'bcd-backup'
$bcdExportProcess = Start-Process -FilePath 'bcdedit.exe' -ArgumentList @('/export', $bcdBackupPath) -WindowStyle Hidden -Wait -PassThru
if ($bcdExportProcess.ExitCode -ne 0) {
    throw "BCD export failed with exit code $($bcdExportProcess.ExitCode)."
}
$bcdEnumPath = Join-Path $runBackup 'bcd-before.txt'
$bcdEnumErrorPath = Join-Path $runBackup 'bcd-before.stderr.txt'
$bcdEnumProcess = Start-Process -FilePath 'bcdedit.exe' -ArgumentList @('/enum', 'all') -RedirectStandardOutput $bcdEnumPath -RedirectStandardError $bcdEnumErrorPath -WindowStyle Hidden -Wait -PassThru
if ($bcdEnumProcess.ExitCode -ne 0) {
    throw "BCD enumeration failed with exit code $($bcdEnumProcess.ExitCode)."
}

$chkdskPath = Join-Path $runBackup 'chkdsk-scan.txt'
$chkdskErrorPath = Join-Path $runBackup 'chkdsk-scan.stderr.txt'
$chkdskProcess = Start-Process -FilePath 'chkdsk.exe' -ArgumentList @('C:', '/scan') -RedirectStandardOutput $chkdskPath -RedirectStandardError $chkdskErrorPath -WindowStyle Hidden -Wait -PassThru
if ($chkdskProcess.ExitCode -gt 1) {
    throw "chkdsk /scan failed with exit code $($chkdskProcess.ExitCode)."
}

if ($AuditOnly) {
    Write-Output 'AUDIT ONLY: all identity, BitLocker, size, BCD export, and CHKDSK checks passed.'
    Write-Output "Preflight directory: $runBackup"
    exit 0
}

if ($PSCmdlet.ShouldProcess(
        "Disk $DiskNumber partition $WindowsPartitionNumber (C:)",
        "disable hibernation/Fast Startup and resize NTFS to $WindowsTargetSize bytes"
    )) {
    $powercfgProcess = Start-Process -FilePath 'powercfg.exe' -ArgumentList @('/hibernate', 'off') -WindowStyle Hidden -Wait -PassThru
    if ($powercfgProcess.ExitCode -ne 0) {
        throw "powercfg /hibernate off failed with exit code $($powercfgProcess.ExitCode)."
    }
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Type DWord -Value 0
    Resize-Partition -DiskNumber $DiskNumber -PartitionNumber $WindowsPartitionNumber -Size $WindowsTargetSize -Confirm:$false
}

Get-Partition -DiskNumber $DiskNumber |
    Select-Object DiskNumber, PartitionNumber, DriveLetter, Type, GptType, Size, Offset |
    Format-Table -AutoSize
Get-PartitionSupportedSize -DiskNumber $DiskNumber -PartitionNumber $WindowsPartitionNumber |
    Format-List SizeMin, SizeMax
Write-Output "Rollback/audit directory: $runBackup"
