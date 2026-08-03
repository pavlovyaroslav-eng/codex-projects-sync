#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [switch]$EraseUsbConfirmed,
    [switch]$VerifyOnly,
    [switch]$SkipReadbackVerification,
    [switch]$ResetDiskBeforeWrite,
    [string]$IsoPath = 'C:\LocalAI-Deployment\downloads\ubuntu-24.04.4-desktop-amd64.iso',
    [string]$ExpectedIsoSha256 = '3a4c9877b483ab46d7c3fbe165a0db275e1ae3cfe56a5657e5a47c2f99a99d1e',
    [int]$UsbDiskNumber = -1,
    [string]$ExpectedUsbModel = 'Generic MassStorageClass',
    [string]$ExpectedUsbSerial = '000000002015',
    [UInt64]$ExpectedUsbSize = 63864569856,
    [string]$BackupRoot = 'C:\LocalAI-Deployment\rollback\ubuntu-usb'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$bufferSize = 4MB

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script from an elevated Windows PowerShell session.'
    }
}

Assert-Administrator

if (-not $EraseUsbConfirmed) {
    throw 'Refusing raw USB write without -EraseUsbConfirmed.'
}

$matchingDisks = @(
    Get-Disk | Where-Object {
        $_.BusType -eq 'USB' -and
        $_.FriendlyName -eq $ExpectedUsbModel -and
        $_.SerialNumber.Trim() -eq $ExpectedUsbSerial -and
        [UInt64]$_.Size -eq $ExpectedUsbSize -and
        -not $_.IsBoot -and
        -not $_.IsSystem -and
        ($UsbDiskNumber -lt 0 -or $_.Number -eq $UsbDiskNumber)
    }
)
if ($matchingDisks.Count -ne 1) {
    throw "Expected exactly one matching USB disk; found $($matchingDisks.Count). Reconnect the device and re-run inventory."
}
$disk = $matchingDisks[0]
$UsbDiskNumber = [int]$disk.Number
if ($disk.IsBoot -or $disk.IsSystem) {
    throw "Refusing to overwrite boot/system disk $UsbDiskNumber."
}
if ($disk.BusType -ne 'USB') {
    throw "Disk $UsbDiskNumber is not a USB disk (BusType=$($disk.BusType))."
}
if ($disk.FriendlyName -ne $ExpectedUsbModel) {
    throw "USB model mismatch: expected '$ExpectedUsbModel', found '$($disk.FriendlyName)'."
}
if ($disk.SerialNumber.Trim() -ne $ExpectedUsbSerial) {
    throw "USB serial mismatch: expected '$ExpectedUsbSerial', found '$($disk.SerialNumber.Trim())'."
}
if ([UInt64]$disk.Size -ne $ExpectedUsbSize) {
    throw "USB size mismatch: expected $ExpectedUsbSize, found $($disk.Size)."
}

$iso = Get-Item -LiteralPath $IsoPath
if ([UInt64]$iso.Length -ge [UInt64]$disk.Size) {
    throw 'ISO is not smaller than the target USB disk.'
}
$actualIsoSha256 = (Get-FileHash -LiteralPath $IsoPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualIsoSha256 -ne $ExpectedIsoSha256) {
    throw "ISO SHA256 mismatch: $actualIsoSha256"
}

$requestedOperation = if ($VerifyOnly) {
    "verify the first $($iso.Length) bytes against the official ISO SHA256"
}
else {
    "overwrite with verified ISO $IsoPath"
}
if (-not $PSCmdlet.ShouldProcess(
        "\\.\PhysicalDrive$UsbDiskNumber ($ExpectedUsbModel, $ExpectedUsbSerial, $ExpectedUsbSize bytes)",
        $requestedOperation
    )) {
    Write-Output 'Raw write cancelled by ShouldProcess.'
    exit 0
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Join-Path $BackupRoot $timestamp
New-Item -Path $backupDirectory -ItemType Directory -Force | Out-Null
Get-Disk -Number $UsbDiskNumber | Format-List * |
    Set-Content -LiteralPath (Join-Path $backupDirectory 'disk-before.txt') -Encoding UTF8
Get-Partition -DiskNumber $UsbDiskNumber -ErrorAction SilentlyContinue | Format-List * |
    Set-Content -LiteralPath (Join-Path $backupDirectory 'partitions-before.txt') -Encoding UTF8

if ($ResetDiskBeforeWrite -and -not $VerifyOnly) {
    Clear-Disk -Number $UsbDiskNumber -RemoveData -RemoveOEM -Confirm:$false
    Update-HostStorageCache
    $clearedDisk = Get-Disk -Number $UsbDiskNumber
    $remainingPartitions = @(Get-Partition -DiskNumber $UsbDiskNumber -ErrorAction SilentlyContinue)
    if ($remainingPartitions.Count -ne 0) {
        throw "USB reset left $($remainingPartitions.Count) partition(s); refusing raw write."
    }
    Write-Output "USB PARTITIONS CLEARED: Disk $UsbDiskNumber (reported style=$($clearedDisk.PartitionStyle))"
}

if (-not ('LocalAiRawDiskNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public static class LocalAiRawDiskNative {
    public const uint GENERIC_READ = 0x80000000;
    public const uint GENERIC_WRITE = 0x40000000;
    public const uint FILE_SHARE_READ = 0x00000001;
    public const uint FILE_SHARE_WRITE = 0x00000002;
    public const uint OPEN_EXISTING = 3;
    public const uint FILE_FLAG_WRITE_THROUGH = 0x80000000;
    public const uint FSCTL_LOCK_VOLUME = 0x00090018;
    public const uint FSCTL_DISMOUNT_VOLUME = 0x00090020;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern SafeFileHandle CreateFile(
        string fileName,
        uint desiredAccess,
        uint shareMode,
        IntPtr securityAttributes,
        uint creationDisposition,
        uint flagsAndAttributes,
        IntPtr templateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool DeviceIoControl(
        SafeFileHandle device,
        uint controlCode,
        IntPtr inBuffer,
        uint inBufferSize,
        IntPtr outBuffer,
        uint outBufferSize,
        out uint bytesReturned,
        IntPtr overlapped);

    [DllImport("msvcrt.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int memcmp(byte[] left, byte[] right, UIntPtr count);
}
'@
}

$devicePath = "\\.\PhysicalDrive$UsbDiskNumber"
$lockedVolumeHandles = New-Object System.Collections.Generic.List[Microsoft.Win32.SafeHandles.SafeFileHandle]
$physicalHandle = $null
$targetStream = $null
$sourceStream = $null

try {
    $driveLetters = Get-Partition -DiskNumber $UsbDiskNumber -ErrorAction SilentlyContinue |
        Where-Object { [char]$_.DriveLetter -ne [char]0 } |
        Select-Object -ExpandProperty DriveLetter

    foreach ($driveLetter in $driveLetters) {
        $volumePath = "\\.\$($driveLetter):"
        $volumeHandle = [LocalAiRawDiskNative]::CreateFile(
            $volumePath,
            [LocalAiRawDiskNative]::GENERIC_READ -bor [LocalAiRawDiskNative]::GENERIC_WRITE,
            [LocalAiRawDiskNative]::FILE_SHARE_READ -bor [LocalAiRawDiskNative]::FILE_SHARE_WRITE,
            [IntPtr]::Zero,
            [LocalAiRawDiskNative]::OPEN_EXISTING,
            0,
            [IntPtr]::Zero
        )
        if ($volumeHandle.IsInvalid) {
            throw "Cannot open volume $volumePath; Win32=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
        }
        $bytesReturned = [uint32]0
        if (-not [LocalAiRawDiskNative]::DeviceIoControl(
                $volumeHandle,
                [LocalAiRawDiskNative]::FSCTL_LOCK_VOLUME,
                [IntPtr]::Zero, 0, [IntPtr]::Zero, 0,
                [ref]$bytesReturned,
                [IntPtr]::Zero
            )) {
            $volumeHandle.Dispose()
            throw "Cannot lock volume $volumePath; Win32=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
        }
        if (-not [LocalAiRawDiskNative]::DeviceIoControl(
                $volumeHandle,
                [LocalAiRawDiskNative]::FSCTL_DISMOUNT_VOLUME,
                [IntPtr]::Zero, 0, [IntPtr]::Zero, 0,
                [ref]$bytesReturned,
                [IntPtr]::Zero
            )) {
            $volumeHandle.Dispose()
            throw "Cannot dismount volume $volumePath; Win32=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
        }
        $lockedVolumeHandles.Add($volumeHandle)
    }

    $physicalHandle = [LocalAiRawDiskNative]::CreateFile(
        $devicePath,
        [LocalAiRawDiskNative]::GENERIC_READ -bor [LocalAiRawDiskNative]::GENERIC_WRITE,
        [LocalAiRawDiskNative]::FILE_SHARE_READ -bor [LocalAiRawDiskNative]::FILE_SHARE_WRITE,
        [IntPtr]::Zero,
        [LocalAiRawDiskNative]::OPEN_EXISTING,
        [LocalAiRawDiskNative]::FILE_FLAG_WRITE_THROUGH,
        [IntPtr]::Zero
    )
    if ($physicalHandle.IsInvalid) {
        throw "Cannot open $devicePath; Win32=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
    }

    $targetStream = [System.IO.FileStream]::new(
        $physicalHandle,
        [System.IO.FileAccess]::ReadWrite,
        $bufferSize,
        $false
    )

    $headerBackup = New-Object byte[] $bufferSize
    $headerBytes = $targetStream.Read($headerBackup, 0, $headerBackup.Length)
    [IO.File]::WriteAllBytes(
        (Join-Path $backupDirectory 'first-4MiB-before.bin'),
        $headerBackup[0..($headerBytes - 1)]
    )
    $targetStream.Position = 0

    $buffer = New-Object byte[] $bufferSize
    [Int64]$nextReport = 512MB
    if (-not $VerifyOnly) {
        $sourceStream = [IO.File]::OpenRead($IsoPath)
        [Int64]$written = 0
        while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $targetStream.Write($buffer, 0, $read)
            $written += $read
            if ($written -ge $nextReport) {
                Write-Output ("WRITE {0:N2}% ({1} / {2} bytes)" -f (100 * $written / $iso.Length), $written, $iso.Length)
                $nextReport += 512MB
            }
        }
        $targetStream.Flush($true)
        $sourceStream.Dispose()
        $sourceStream = $null
    }

    if ($SkipReadbackVerification) {
        Write-Output "USB WRITTEN: $devicePath"
        Write-Output "READBACK VERIFICATION: skipped by owner request"
        Write-Output "SOURCE SHA256: $ExpectedIsoSha256"
        Write-Output "Backup: $backupDirectory"
        exit 0
    }

    $targetStream.Position = 0
    $sourceStream = [IO.File]::OpenRead($IsoPath)
    $sourceBuffer = New-Object byte[] $bufferSize
    [Int64]$remaining = $iso.Length
    [Int64]$verified = 0
    $nextReport = 512MB
    while ($remaining -gt 0) {
        $toRead = if ($remaining -gt $buffer.Length) {
            $buffer.Length
        }
        else {
            [int]$remaining
        }
        $sourceRead = $sourceStream.Read($sourceBuffer, 0, $toRead)
        $targetRead = $targetStream.Read($buffer, 0, $toRead)
        if ($sourceRead -le 0 -or $targetRead -le 0) {
            throw "Unexpected end of USB while verifying at byte $verified."
        }
        if ($sourceRead -ne $targetRead) {
            throw "Read length differs at byte ${verified}: ISO=$sourceRead USB=$targetRead."
        }
        $comparison = [LocalAiRawDiskNative]::memcmp(
            $sourceBuffer,
            $buffer,
            [UIntPtr]::new([UInt64]$sourceRead)
        )
        if ($comparison -ne 0) {
            $differenceInBlock = 0
            while (
                $differenceInBlock -lt $sourceRead -and
                $sourceBuffer[$differenceInBlock] -eq $buffer[$differenceInBlock]
            ) {
                $differenceInBlock++
            }
            $absoluteDifference = $verified + $differenceInBlock
            throw "USB byte mismatch at absolute offset $absoluteDifference (ISO=$($sourceBuffer[$differenceInBlock]), USB=$($buffer[$differenceInBlock]))."
        }
        $remaining -= $sourceRead
        $verified += $sourceRead
        if ($verified -ge $nextReport) {
            Write-Output ("VERIFY {0:N2}% ({1} / {2} bytes)" -f (100 * $verified / $iso.Length), $verified, $iso.Length)
            $nextReport += 512MB
        }
    }
    $sourceStream.Dispose()
    $sourceStream = $null
    Write-Output "USB READY: $devicePath"
    Write-Output "BYTE-FOR-BYTE MATCH: $IsoPath"
    Write-Output "SOURCE SHA256: $ExpectedIsoSha256"
    Write-Output "Backup: $backupDirectory"
}
finally {
    if ($sourceStream) { $sourceStream.Dispose() }
    if ($targetStream) { $targetStream.Dispose() }
    elseif ($physicalHandle) { $physicalHandle.Dispose() }
    foreach ($handle in $lockedVolumeHandles) {
        $handle.Dispose()
    }
    Update-HostStorageCache -ErrorAction SilentlyContinue
}
