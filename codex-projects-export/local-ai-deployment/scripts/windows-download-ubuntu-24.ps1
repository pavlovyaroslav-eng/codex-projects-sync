#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$DownloadDirectory = 'C:\LocalAI-Deployment\downloads'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$isoName = 'ubuntu-24.04.4-desktop-amd64.iso'
$source = "https://releases.ubuntu.com/24.04/$isoName"
$expectedSha256 = '3a4c9877b483ab46d7c3fbe165a0db275e1ae3cfe56a5657e5a47c2f99a99d1e'
$destination = Join-Path $DownloadDirectory $isoName
$partialPath = "$destination.part"
$stderrLog = Join-Path $DownloadDirectory 'ubuntu-24.04.4-curl.stderr.log'
$taskName = 'LocalAI-Download-Ubuntu-24.04.4'

New-Item -Path $DownloadDirectory -ItemType Directory -Force | Out-Null

if (Test-Path -LiteralPath $destination) {
    $actualSha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -eq $expectedSha256) {
        Write-Output "READY: $destination"
        Write-Output "SHA256: $actualSha256"
        exit 0
    }

    $invalidPath = "$destination.invalid-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $destination -Destination $invalidPath
    Write-Output "Existing ISO failed SHA256 and was preserved as: $invalidPath"
}

$downloadTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($downloadTask -and $downloadTask.State -eq 'Running') {
    $partialBytes = if (Test-Path -LiteralPath $partialPath) {
        (Get-Item -LiteralPath $partialPath).Length
    }
    else {
        0
    }
    [pscustomobject]@{
        State          = 'Downloading'
        ScheduledTask  = $taskName
        PartialBytes   = $partialBytes
        PartialPath    = $partialPath
        ExpectedSHA256 = $expectedSha256
    } | Format-List
    exit 0
}

if (Test-Path -LiteralPath $partialPath) {
    $partialSha256 = (Get-FileHash -LiteralPath $partialPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($partialSha256 -eq $expectedSha256) {
        Move-Item -LiteralPath $partialPath -Destination $destination
        if ($downloadTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        Write-Output "READY: $destination"
        Write-Output "SHA256: $partialSha256"
        exit 0
    }
}

$curlPath = Join-Path $env:SystemRoot 'System32\curl.exe'
$curlArguments = "--fail --location --retry 5 --retry-delay 5 --continue-at - --stderr $stderrLog --output $partialPath $source"

if (-not $downloadTask) {
    $action = New-ScheduledTaskAction -Execute $curlPath -Argument $curlArguments
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settingsParameters = @{
        ExecutionTimeLimit       = (New-TimeSpan -Hours 2)
        AllowStartIfOnBatteries  = $true
        DontStopIfGoingOnBatteries = $true
    }
    $settings = New-ScheduledTaskSettingsSet @settingsParameters
    $registerParameters = @{
        TaskName    = $taskName
        Action      = $action
        Principal   = $principal
        Settings    = $settings
        Description = 'Download official Ubuntu 24.04.4 Desktop ISO'
        Force       = $true
    }
    Register-ScheduledTask @registerParameters | Out-Null
}

Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 1
$downloadTask = Get-ScheduledTask -TaskName $taskName
$taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
$partialBytes = if (Test-Path -LiteralPath $partialPath) {
    (Get-Item -LiteralPath $partialPath).Length
}
else {
    0
}

[pscustomobject]@{
    State           = $downloadTask.State
    ScheduledTask   = $taskName
    LastTaskResult  = $taskInfo.LastTaskResult
    PartialBytes    = $partialBytes
    PartialPath     = $partialPath
    StandardError   = $stderrLog
    ExpectedSHA256  = $expectedSha256
} | Format-List
