#requires -Version 5.1

<#
.SYNOPSIS
  Безопасно готовит Windows-компьютер local-ai к аудиту и удалённому управлению из LAN.

.DESCRIPTION
  До изменений собирает аппаратный, дисковый, загрузочный, сетевой и GPU-аудит.
  Затем (если не указан -AuditOnly) сначала включает подтверждённый пользователем
  RDP без NLA для локальной учётной записи с пустым паролем и ограничивает его
  одним адресом RdpAllowedAddress. После этого настраивает OpenSSH, WinRM и SMB.

  Скрипт не меняет разделы/BCD/EFI/BitLocker/Secure Boot, не меняет пароль,
  не отключает Microsoft Defender или Windows Firewall и не открывает доступ из Интернета.

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows-remote-audit-bootstrap.ps1

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows-remote-audit-bootstrap.ps1 -AuditOnly

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows-remote-audit-bootstrap.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidatePattern('^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$')]
    [string]$AllowedSubnet = '192.168.1.0/24',

    [ValidatePattern('^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$')]
    [string]$RdpAllowedAddress = '192.168.1.41/32',

    [ValidateNotNullOrEmpty()]
    [string]$WorkDirectory = 'C:\LocalAI-Deployment',

    [ValidatePattern('^[^\\/:*?"<>|]{1,79}\$$')]
    [string]$ShareName = 'LocalAI-Deployment$',

    [ValidateNotNullOrEmpty()]
    [string]$TargetUser = $env:USERNAME,

    [ValidatePattern('^(ssh-ed25519|ecdsa-sha2-nistp(256|384|521)|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com|rsa-sha2-(256|512)|ssh-rsa) [A-Za-z0-9+/]+={0,3}( .*)?$')]
    [string]$AuthorizedPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUcNxSfwsut+b1yvhX8j0yMcorD6pR2GVI4wfkFLaxd ACER-X-02 local-ai admin v2',

    [switch]$AuditOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$scriptVersion = '2026.07.31.9'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($WhatIfPreference) {
    Write-Host 'DRY-RUN: изменения не выполняются.' -ForegroundColor Yellow
    Write-Host "Версия bootstrap: $scriptVersion"
    Write-Host "Будет создана папка: $WorkDirectory"
    Write-Host "Будет создана скрытая SMB-шара: \\$env:COMPUTERNAME\$ShareName"
    Write-Host "Сначала будет включён RDP без NLA и разрешён только с: $RdpAllowedAddress" -ForegroundColor Yellow
    Write-Host "Затем будут включены key-only OpenSSH (22/TCP), WinRM (5985/TCP), SMB (445/TCP) и ICMPv4 Echo."
    Write-Host "WinRM/SMB будут разрешены только с $RdpAllowedAddress; SSH/ICMP — с $AllowedSubnet"
    Write-Host 'Разделы, BCD, EFI, BitLocker, Secure Boot, Defender, пароли и сетевые адреса изменены не будут.'
    return
}

if (-not (Test-IsAdministrator)) {
    throw 'Запустите Windows PowerShell от имени администратора.'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$inventoryDirectory = Join-Path $WorkDirectory 'inventory'
$logDirectory = Join-Path $WorkDirectory 'logs'
$rollbackRoot = Join-Path $WorkDirectory 'rollback'
$rollbackDirectory = Join-Path $rollbackRoot "windows-bootstrap-$timestamp"

foreach ($path in @($WorkDirectory, $inventoryDirectory, $logDirectory, $rollbackRoot, $rollbackDirectory)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

$transcriptPath = Join-Path $logDirectory "windows-bootstrap-$timestamp.log"
Start-Transcript -LiteralPath $transcriptPath -Force | Out-Null

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
}

function Add-Section {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )
    Write-Log "Аудит: $Title"
    $Lines.Add('')
    $Lines.Add("===== $Title =====")
    try {
        $text = (& $Command 2>&1 | Out-String -Width 4096).TrimEnd()
        if ([string]::IsNullOrWhiteSpace($text)) {
            $Lines.Add('(нет данных)')
        }
        else {
            foreach ($line in ($text -split "`r?`n")) { $Lines.Add($line) }
        }
    }
    catch {
        $Lines.Add("ОШИБКА СБОРА: $($_.Exception.Message)")
    }
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][AllowEmptyCollection()][object[]]$Lines
    )
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($Path, [string[]]$Lines, $utf8NoBom)
}

function Get-Avx2Status {
    try {
        $avx2Type = [Type]::GetType('System.Runtime.Intrinsics.X86.Avx2, System.Private.CoreLib', $false)
        if ($null -ne $avx2Type) {
            return "Проверено через .NET intrinsics: $($avx2Type.GetProperty('IsSupported').GetValue($null))"
        }
        $coreInfo = Get-Command coreinfo.exe -ErrorAction SilentlyContinue
        if ($null -ne $coreInfo) {
            $line = (& $coreInfo.Source -accepteula -f 2>$null | Select-String -Pattern '^AVX2\s')
            if ($line) { return "Проверено через Coreinfo: $($line.Line.Trim())" }
        }
    }
    catch {
        return "Не удалось проверить: $($_.Exception.Message)"
    }
    return 'Не проверено: Windows PowerShell 5.1 не предоставляет надёжный встроенный CPUID; будет проверено Coreinfo/llama.cpp после подключения.'
}

function Backup-RegistryKey {
    param(
        [Parameter(Mandatory = $true)][string]$RegistryPath,
        [Parameter(Mandatory = $true)][string]$FileName
    )
    $destination = Join-Path $rollbackDirectory $FileName
    & reg.exe export $RegistryPath $destination /y 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Не удалось экспортировать $RegistryPath" 'WARN'
    }
}

function Resolve-TargetAccount {
    param([Parameter(Mandatory = $true)][string]$Name)

    $candidates = [System.Collections.Generic.List[string]]::new()
    $candidates.Add($Name)
    if (($Name -notmatch '[\\@]') -and $env:COMPUTERNAME) {
        $candidates.Add("$env:COMPUTERNAME\$Name")
    }

    foreach ($candidate in $candidates) {
        try {
            $ntAccount = [Security.Principal.NTAccount]::new($candidate)
            $sid = $ntAccount.Translate([Security.Principal.SecurityIdentifier])
            $canonical = $sid.Translate([Security.Principal.NTAccount]).Value
            return [pscustomobject]@{
                Name = $canonical
                Sid  = $sid.Value
            }
        }
        catch {
            continue
        }
    }
    throw "Не удалось разрешить учётную запись '$Name'. Запустите с -TargetUser 'COMPUTER\\user' или 'MicrosoftAccount\\email'."
}

function Test-LocalGroupMembershipBySid {
    param(
        [Parameter(Mandatory = $true)][string]$GroupSid,
        [Parameter(Mandatory = $true)][string]$MemberSid
    )
    try {
        return [bool](Get-LocalGroupMember -SID $GroupSid -ErrorAction Stop | Where-Object { $_.SID.Value -eq $MemberSid })
    }
    catch {
        Write-Log "Не удалось проверить группу ${GroupSid}: $($_.Exception.Message)" 'WARN'
        return $false
    }
}

function Backup-FirewallRulesForPorts {
    param([int[]]$Ports)

    $records = [System.Collections.Generic.List[object]]::new()
    foreach ($rule in (Get-NetFirewallRule -Direction Inbound -ErrorAction SilentlyContinue)) {
        $portFilters = @($rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue)
        foreach ($filter in $portFilters) {
            $localPorts = @([string]$filter.LocalPort -split ',')
            if (@($Ports | Where-Object { $localPorts -contains [string]$_ }).Count -eq 0) { continue }
            $address = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
            $application = $rule | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue
            $service = $rule | Get-NetFirewallServiceFilter -ErrorAction SilentlyContinue
            $records.Add([pscustomobject]@{
                Name          = $rule.Name
                DisplayName   = $rule.DisplayName
                Enabled       = [string]$rule.Enabled
                Direction     = [string]$rule.Direction
                Action        = [string]$rule.Action
                Profile       = [string]$rule.Profile
                Protocol      = [string]$filter.Protocol
                LocalPort     = [string]$filter.LocalPort
                RemotePort    = [string]$filter.RemotePort
                RemoteAddress = [string]$address.RemoteAddress
                Program       = [string]$application.Program
                Service       = [string]$service.Service
            })
        }
    }
    $records | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $rollbackDirectory 'firewall-rules-before.json') -Encoding UTF8
}

function Restrict-EnabledAllowRulesForPort {
    param(
        [Parameter(Mandatory = $true)][int]$Port,
        [Parameter(Mandatory = $true)][string]$RemoteAddress
    )

    foreach ($rule in (Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue)) {
        $filters = @($rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue)
        foreach ($filter in $filters) {
            $ports = @([string]$filter.LocalPort -split ',')
            if ($ports -contains [string]$Port) {
                $addressFilter = $rule | Get-NetFirewallAddressFilter
                $addressFilter | Set-NetFirewallAddressFilter -RemoteAddress $RemoteAddress | Out-Null
                Write-Log "Firewall: существующее правило '$($rule.DisplayName)' для порта $Port ограничено $RemoteAddress"
            }
        }
    }
}

function Ensure-LanFirewallRule {
    param(
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][ValidateSet('TCP', 'UDP', 'ICMPv4')][string]$Protocol,
        [int]$LocalPort = 0,
        [Parameter(Mandatory = $true)][string]$RemoteAddress,
        [int]$IcmpType = -1
    )

    $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $rule) {
        $parameters = @{
            DisplayName   = $DisplayName
            Direction     = 'Inbound'
            Action        = 'Allow'
            Enabled       = 'True'
            Profile       = 'Any'
            Protocol      = $Protocol
            RemoteAddress = $RemoteAddress
            PolicyStore   = 'PersistentStore'
        }
        if ($LocalPort -gt 0) { $parameters.LocalPort = $LocalPort }
        if ($IcmpType -ge 0) { $parameters.IcmpType = $IcmpType }
        New-NetFirewallRule @parameters | Out-Null
        Write-Log "Firewall: создано правило '$DisplayName' только для $RemoteAddress"
    }
    else {
        $rule | Set-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Any | Out-Null
        $rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $RemoteAddress | Out-Null
        Write-Log "Firewall: обновлено правило '$DisplayName' только для $RemoteAddress"
    }
}

function Add-AuthorizedKey {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$PublicKey,
        [Parameter(Mandatory = $true)][string[]]$AclSids
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if (Test-Path -LiteralPath $Path) {
        Copy-Item -LiteralPath $Path -Destination (Join-Path $rollbackDirectory ((Split-Path -Leaf $Path) + '.before')) -Force
    }

    $newIdentity = (($PublicKey -split '\s+')[0..1] -join ' ')
    $existing = @()
    if (Test-Path -LiteralPath $Path) { $existing = @(Get-Content -LiteralPath $Path) }
    $found = $false
    foreach ($line in $existing) {
        $parts = @($line.Trim() -split '\s+')
        if ($parts.Count -ge 2 -and (($parts[0..1] -join ' ') -eq $newIdentity)) { $found = $true }
    }
    if (-not $found) {
        Add-Content -LiteralPath $Path -Value $PublicKey -Encoding ASCII
        Write-Log "Публичный ключ добавлен в $Path"
    }
    else {
        Write-Log "Публичный ключ уже присутствует в $Path"
    }

    $grantArguments = [System.Collections.Generic.List[string]]::new()
    $grantArguments.Add($Path)
    $grantArguments.Add('/inheritance:r')
    $grantArguments.Add('/grant:r')
    foreach ($sid in $AclSids) { $grantArguments.Add("*$($sid):F") }
    & icacls.exe $grantArguments.ToArray() | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Не удалось установить ACL для $Path" }
}

function Ensure-SshdPublicKeyAuthentication {
    $sshdConfig = Join-Path $env:ProgramData 'ssh\sshd_config'
    if (-not (Test-Path -LiteralPath $sshdConfig)) {
        $defaultConfig = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd_config_default'
        if (Test-Path -LiteralPath $defaultConfig) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $sshdConfig) | Out-Null
            Copy-Item -LiteralPath $defaultConfig -Destination $sshdConfig -Force
            Write-Log "Создан $sshdConfig из штатного шаблона Microsoft OpenSSH."
        }
        else {
            throw "Не найден ни $sshdConfig, ни штатный шаблон $defaultConfig"
        }
    }

    $backup = Join-Path $rollbackDirectory 'sshd_config.before'
    Copy-Item -LiteralPath $sshdConfig -Destination $backup -Force
    $lines = @(Get-Content -LiteralPath $sshdConfig)
    $firstMatchIndex = $lines.Count
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*Match\s+') {
            $firstMatchIndex = $index
            break
        }
    }

    $desiredGlobalDirectives = [ordered]@{
        PubkeyAuthentication = 'yes'
        PasswordAuthentication = 'no'
    }
    $foundGlobalDirectives = @{}
    foreach ($name in $desiredGlobalDirectives.Keys) { $foundGlobalDirectives[$name] = $false }

    for ($index = 0; $index -lt $firstMatchIndex; $index++) {
        foreach ($name in $desiredGlobalDirectives.Keys) {
            if ($lines[$index] -match ('^\s*' + [regex]::Escape($name) + '\s+')) {
                $lines[$index] = "$name $($desiredGlobalDirectives[$name])"
                $foundGlobalDirectives[$name] = $true
            }
        }
    }

    $missingDirectives = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $desiredGlobalDirectives.Keys) {
        if (-not $foundGlobalDirectives[$name]) {
            $missingDirectives.Add("$name $($desiredGlobalDirectives[$name])")
        }
    }
    if ($missingDirectives.Count -gt 0) {
        $beforeMatch = @()
        $fromMatch = @()
        if ($firstMatchIndex -gt 0) { $beforeMatch = @($lines[0..($firstMatchIndex - 1)]) }
        if ($firstMatchIndex -lt $lines.Count) { $fromMatch = @($lines[$firstMatchIndex..($lines.Count - 1)]) }
        $lines = @($beforeMatch) + @(
            '',
            '# Managed by local-ai bootstrap: SSH is key-only because blank-password network logon is enabled for RDP.'
        ) + @($missingDirectives) + @($fromMatch)
    }
    Write-Utf8File -Path $sshdConfig -Lines $lines

    $sshdExe = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd.exe'
    & $sshdExe -t -f $sshdConfig 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Copy-Item -LiteralPath $backup -Destination $sshdConfig -Force
        throw 'Проверка sshd_config не прошла; исходный файл восстановлен.'
    }
}

function Collect-PreChangeAudit {
    Write-Log 'Сбор read-only аудита до изменений.'

    $diskLines = [System.Collections.Generic.List[string]]::new()
    $diskLines.Add("Collected: $(Get-Date -Format o)")
    Add-Section $diskLines 'Physical disks' { Get-PhysicalDisk | Sort-Object DeviceId | Select-Object DeviceId, FriendlyName, SerialNumber, MediaType, BusType, HealthStatus, OperationalStatus, Size, AllocatedSize | Format-Table -AutoSize }
    Add-Section $diskLines 'Storage reliability / SMART-NVMe counters' { Get-PhysicalDisk | ForEach-Object { $disk = $_; try { $disk | Get-StorageReliabilityCounter | Select-Object @{Name='Disk';Expression={$disk.FriendlyName}}, Temperature, TemperatureMax, Wear, PowerOnHours, ReadErrorsTotal, WriteErrorsTotal, ReadLatencyMax, WriteLatencyMax } catch { [pscustomobject]@{Disk=$disk.FriendlyName;Status="Unavailable: $($_.Exception.Message)"} } } | Format-Table -AutoSize }
    Add-Section $diskLines 'Disk partition style and free extents' { Get-Disk | Sort-Object Number | Select-Object Number, FriendlyName, SerialNumber, BusType, PartitionStyle, IsBoot, IsSystem, HealthStatus, OperationalStatus, Size, LargestFreeExtent | Format-Table -AutoSize }
    Add-Section $diskLines 'Partitions' { Get-Partition | Sort-Object DiskNumber, PartitionNumber | Select-Object DiskNumber, PartitionNumber, DriveLetter, Type, GptType, MbrType, IsActive, IsBoot, IsSystem, Size, Offset | Format-Table -AutoSize }
    Add-Section $diskLines 'Volumes' { Get-Volume | Sort-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel, FileSystemType, DriveType, HealthStatus, OperationalStatus, Size, SizeRemaining, Path | Format-Table -AutoSize }
    Write-Utf8File -Path (Join-Path $inventoryDirectory 'disk-layout-before.txt') -Lines $diskLines

    $bootLines = [System.Collections.Generic.List[string]]::new()
    $bootLines.Add("Collected: $(Get-Date -Format o)")
    Add-Section $bootLines 'Firmware type' { Get-ComputerInfo -Property BiosFirmwareType | Format-List }
    Add-Section $bootLines 'Secure Boot' { try { "SecureBootUEFI=$((Confirm-SecureBootUEFI -ErrorAction Stop))" } catch { "Unavailable/Legacy/unsupported: $($_.Exception.Message)" } }
    Add-Section $bootLines 'Windows Recovery Environment' { & reagentc.exe /info }
    Add-Section $bootLines 'Windows Boot Manager' { & bcdedit.exe /enum '{bootmgr}' }
    Add-Section $bootLines 'Current Windows loader' { & bcdedit.exe /enum '{current}' }
    Add-Section $bootLines 'All BCD entries (read-only)' { & bcdedit.exe /enum all }
    Add-Section $bootLines 'BitLocker summary without recovery secrets' { Get-BitLockerVolume | Select-Object MountPoint, VolumeType, VolumeStatus, ProtectionStatus, EncryptionMethod, EncryptionPercentage, AutoUnlockEnabled, @{Name='KeyProtectorTypes';Expression={($_.KeyProtector.KeyProtectorType -join ',')}} | Format-Table -AutoSize }
    Add-Section $bootLines 'manage-bde status (does not reveal recovery password)' { & manage-bde.exe -status }
    Add-Section $bootLines 'Fast Startup and hibernation registry' { Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled,HibernateEnabled -ErrorAction SilentlyContinue | Select-Object HiberbootEnabled,HibernateEnabled | Format-List }
    Add-Section $bootLines 'Available sleep states' { & powercfg.exe /a }
    Write-Utf8File -Path (Join-Path $inventoryDirectory 'windows-boot-before.txt') -Lines $bootLines

    $networkLines = [System.Collections.Generic.List[string]]::new()
    $networkLines.Add("Collected: $(Get-Date -Format o)")
    Add-Section $networkLines 'Adapters and link speed' { Get-NetAdapter | Sort-Object ifIndex | Select-Object ifIndex, Name, InterfaceDescription, Status, MacAddress, LinkSpeed, MediaConnectionState | Format-Table -AutoSize }
    Add-Section $networkLines 'IP configuration' { Get-NetIPConfiguration -Detailed | Format-List }
    Add-Section $networkLines 'IPv4 routes' { Get-NetRoute -AddressFamily IPv4 | Sort-Object DestinationPrefix, RouteMetric | Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric, State | Format-Table -AutoSize }
    Add-Section $networkLines 'Network profiles' { Get-NetConnectionProfile | Select-Object Name, InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity | Format-Table -AutoSize }
    Add-Section $networkLines 'Listening remote-management ports before changes' { Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object LocalPort -in 22,445,3389,5985,5986 | Sort-Object LocalPort | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize }
    Add-Section $networkLines 'Existing SMB shares' { Get-SmbShare | Select-Object Name, Path, Description, EncryptData, FolderEnumerationMode | Format-Table -AutoSize }
    Add-Section $networkLines 'Windows Firewall profiles' { Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, NotifyOnListen, LogAllowed, LogBlocked | Format-Table -AutoSize }
    Add-Section $networkLines 'Relevant inbound firewall rules' { Get-NetFirewallRule -Direction Inbound -ErrorAction SilentlyContinue | ForEach-Object { $rule=$_; $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -match '(^|,)(22|445|3389|5985|5986)(,|$)' } | ForEach-Object { $address=$rule | Get-NetFirewallAddressFilter; [pscustomobject]@{Name=$rule.DisplayName;Enabled=$rule.Enabled;Action=$rule.Action;Profile=$rule.Profile;Protocol=$_.Protocol;LocalPort=$_.LocalPort;RemoteAddress=($address.RemoteAddress -join ',')} } } | Format-Table -AutoSize }
    Write-Utf8File -Path (Join-Path $inventoryDirectory 'network-before.txt') -Lines $networkLines

    $gpuLines = [System.Collections.Generic.List[string]]::new()
    $gpuLines.Add("Collected: $(Get-Date -Format o)")
    Add-Section $gpuLines 'Display controllers (CIM)' { Get-CimInstance Win32_VideoController | Select-Object Name, AdapterCompatibility, AdapterRAM, DriverVersion, DriverDate, PNPDeviceID, Status | Format-List }
    Add-Section $gpuLines 'NVIDIA concise status' { $command=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue; if ($command) { & $command.Source --query-gpu=name,driver_version,memory.total,temperature.gpu,power.draw,power.limit,pstate,pci.bus_id --format=csv } else { 'nvidia-smi.exe not found' } }
    Add-Section $gpuLines 'NVIDIA topology' { $command=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue; if ($command) { & $command.Source topo -m } else { 'nvidia-smi.exe not found' } }
    Add-Section $gpuLines 'CUDA compiler' { $command=Get-Command nvcc.exe -ErrorAction SilentlyContinue; if ($command) { & $command.Source --version } else { 'nvcc.exe not found; CUDA Toolkit may be absent (driver CUDA capability is reported by nvidia-smi).' } }
    Write-Utf8File -Path (Join-Path $inventoryDirectory 'gpu-before.txt') -Lines $gpuLines

    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $baseboard = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
    $processors = @(Get-CimInstance Win32_Processor)
    $physicalMemory = @(Get-CimInstance Win32_PhysicalMemory)
    $netAdapters = @(Get-NetAdapter | Where-Object Status -eq 'Up')
    $video = @(Get-CimInstance Win32_VideoController)
    $firmware = try { (Get-ComputerInfo -Property BiosFirmwareType).BiosFirmwareType } catch { 'Unknown' }
    $secureBoot = try { [string](Confirm-SecureBootUEFI -ErrorAction Stop) } catch { 'Unavailable/Legacy/unsupported' }
    $bitlocker = try { @(Get-BitLockerVolume | ForEach-Object { "$($_.MountPoint): Protection=$($_.ProtectionStatus), Status=$($_.VolumeStatus), RecoveryProtectorPresent=$([bool]($_.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword'))" }) -join '<br>' } catch { "Unavailable: $($_.Exception.Message)" }
    $wheaCount = try { @(Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'; StartTime=(Get-Date).AddDays(-30)} -ErrorAction Stop).Count } catch { 0 }
    $memoryDiag = try { @(Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-MemoryDiagnostics-Results'; StartTime=(Get-Date).AddDays(-365)} -ErrorAction Stop | Select-Object -First 3 TimeCreated,Id,LevelDisplayName,Message | Format-List | Out-String -Width 4096).Trim() } catch { 'Нет доступного результата Windows Memory Diagnostic за 365 дней.' }
    $thermal = try { @(Get-CimInstance -Namespace 'root/wmi' -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | ForEach-Object { [math]::Round(($_.CurrentTemperature / 10) - 273.15, 1) }) -join ', ' } catch { 'ACPI не предоставляет температуру CPU; требуется HWiNFO/IPMI.' }
    $numa = try { @(Get-CimInstance Win32_PerfFormattedData_PerfOS_NUMANodeMemory -ErrorAction Stop | Select-Object Name,AvailableMBytes,TotalMBytes | Format-Table -AutoSize | Out-String -Width 4096).Trim() } catch { "Не удалось прочитать NUMA counters: $($_.Exception.Message)" }

    $report = [System.Collections.Generic.List[string]]::new()
    $report.Add('# Hardware report — этап 1 (до изменений)')
    $report.Add('')
    $report.Add("Дата сбора: $(Get-Date -Format o)")
    $report.Add(('Компьютер: `{0}`' -f $env:COMPUTERNAME))
    $report.Add('')
    $report.Add('## Операционная система и плата')
    $report.Add('')
    $report.Add("- ОС: $($os.Caption), version $($os.Version), build $($os.BuildNumber), architecture $($os.OSArchitecture)")
    $report.Add("- Материнская плата: $($baseboard.Manufacturer) $($baseboard.Product), version $($baseboard.Version)")
    $report.Add("- BIOS: $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion), release $($bios.ReleaseDate)")
    $report.Add("- Режим прошивки: $firmware")
    $report.Add("- Secure Boot: $secureBoot")
    $report.Add('')
    $report.Add('## CPU, RAM и NUMA')
    $report.Add('')
    foreach ($cpu in $processors) { $report.Add("- CPU: $($cpu.Name.Trim()); cores=$($cpu.NumberOfCores); logical=$($cpu.NumberOfLogicalProcessors); maxMHz=$($cpu.MaxClockSpeed)") }
    $report.Add("- Сокетов: $($computer.NumberOfProcessors); логических процессоров: $($computer.NumberOfLogicalProcessors)")
    $report.Add("- RAM: $([math]::Round($computer.TotalPhysicalMemory / 1GB, 2)) GiB; модулей: $($physicalMemory.Count)")
    $report.Add("- AVX2: $(Get-Avx2Status)")
    $report.Add("- CPU/ACPI температуры: $thermal")
    $report.Add("- WHEA hardware events за 30 дней: $wheaCount")
    $report.Add('- Windows Memory Diagnostic:')
    $report.Add('```text')
    foreach ($line in ($memoryDiag -split "`r?`n")) { $report.Add($line) }
    $report.Add('```')
    $report.Add('- NUMA counters:')
    $report.Add('```text')
    foreach ($line in ($numa -split "`r?`n")) { $report.Add($line) }
    $report.Add('```')
    $report.Add('')
    $report.Add('## GPU')
    $report.Add('')
    foreach ($gpu in $video) { $report.Add("- $($gpu.Name); driver=$($gpu.DriverVersion); CIM AdapterRAM=$($gpu.AdapterRAM) bytes (для VRAM использовать gpu-before.txt/nvidia-smi)") }
    $report.Add('')
    $report.Add('## Сеть')
    $report.Add('')
    foreach ($adapter in $netAdapters) { $report.Add("- $($adapter.Name): MAC=$($adapter.MacAddress), link=$($adapter.LinkSpeed), description=$($adapter.InterfaceDescription)") }
    $report.Add('- Указанная LinkSpeed — скорость линка, не iperf throughput; фактический тест выполняется позднее с отдельной LAN-точкой.')
    $report.Add('')
    $report.Add('## BitLocker')
    $report.Add('')
    $report.Add("$bitlocker")
    $report.Add('- Recovery password намеренно не записывается в отчёт. Наличие protector фиксируется без вывода секрета.')
    $report.Add('')
    $report.Add('## Ограничения этого снимка')
    $report.Add('')
    $report.Add('- Стресс-тест RAM/CPU/GPU не выполнялся: это отдельный этап после проверки охлаждения и удалённого доступа.')
    $report.Add('- Состояние дисков, разделов, WinRE/BCD, NVIDIA и CUDA приведено в файлах `inventory/*-before.txt`.')
    Write-Utf8File -Path (Join-Path $WorkDirectory 'hardware-report.md') -Lines $report
}

function Backup-RemoteAccessState {
    Write-Log "Резервная копия изменяемых настроек: $rollbackDirectory"
    Backup-RegistryKey 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server' 'terminal-server.reg'
    Backup-RegistryKey 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' 'rdp-tcp.reg'
    $lsaPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $lsaItem = Get-ItemProperty -LiteralPath $lsaPath -ErrorAction SilentlyContinue
    $limitBlankPasswordUseExists = $false
    $limitBlankPasswordUseValue = $null
    if ($null -ne $lsaItem -and $lsaItem.PSObject.Properties.Name -contains 'LimitBlankPasswordUse') {
        $limitBlankPasswordUseExists = $true
        $limitBlankPasswordUseValue = $lsaItem.LimitBlankPasswordUse
    }
    [pscustomobject]@{
        RegistryPath = $lsaPath
        ValueName = 'LimitBlankPasswordUse'
        Existed = $limitBlankPasswordUseExists
        Value = $limitBlankPasswordUseValue
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $rollbackDirectory 'blank-password-policy-before.json') -Encoding UTF8

    $sshdConfig = Join-Path $env:ProgramData 'ssh\sshd_config'
    if (Test-Path -LiteralPath $sshdConfig) {
        Copy-Item -LiteralPath $sshdConfig -Destination (Join-Path $rollbackDirectory 'sshd_config.before-initial') -Force
    }
    Get-Service sshd,TermService,WinRM,LanmanServer -ErrorAction SilentlyContinue |
        Select-Object Name,Status,StartType | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $rollbackDirectory 'services-before.json') -Encoding UTF8
    Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue |
        Select-Object Name,Path,Description,EncryptData,FolderEnumerationMode |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $rollbackDirectory 'smb-share-before.json') -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $winRmOutput = @()
    $winRmExitCode = -1
    try {
        # An absent listener is an expected initial state. winrm.cmd writes its
        # WSManFault to PowerShell's error stream, which must not abort backup.
        $ErrorActionPreference = 'Continue'
        $winRmOutput = @(& winrm.cmd enumerate winrm/config/listener 2>&1)
        $winRmExitCode = $LASTEXITCODE
    }
    catch {
        $winRmOutput = @("Unable to enumerate WinRM listeners: $($_.Exception.Message)")
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    @("ExitCode=$winRmExitCode") + @($winRmOutput | ForEach-Object { [string]$_ }) |
        Set-Content -LiteralPath (Join-Path $rollbackDirectory 'winrm-listeners-before.txt') -Encoding UTF8
    Backup-FirewallRulesForPorts -Ports 22,445,3389,5985,5986

    @(
        'Rollback is intentionally manual to avoid deleting pre-existing access.',
        "Backup captured: $(Get-Date -Format o)",
        'Registry restore (only if rollback is required):',
        '  reg import terminal-server.reg',
        '  reg import rdp-tcp.reg',
        'Blank-password policy: restore the value recorded in blank-password-policy-before.json, then restart TermService.',
        'SSHD restore (if file existed):',
        '  copy /y sshd_config.before-initial C:\ProgramData\ssh\sshd_config',
        'Review firewall-rules-before.json and services-before.json before reverting.',
        "The SMB share created by this script is named $ShareName; do not remove it if it existed before (see smb-share-before.json)."
    ) | Set-Content -LiteralPath (Join-Path $rollbackDirectory 'ROLLBACK-INSTRUCTIONS.txt') -Encoding UTF8
}

function Configure-OpenSsh {
    Write-Log 'Настройка OpenSSH Server.'
    $capability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Select-Object -First 1
    if ($null -eq $capability) { throw 'Windows capability OpenSSH.Server не найдена.' }
    if ($capability.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name $capability.Name | Out-Null
        Write-Log "Установлена capability $($capability.Name)"
    }
    else {
        Write-Log "OpenSSH Server уже установлен: $($capability.Name)"
    }

    # The first service start creates host keys and, on some Windows builds,
    # initializes ProgramData\ssh. Do this before validating sshd_config.
    Set-Service -Name sshd -StartupType Automatic
    if ((Get-Service -Name sshd).Status -ne 'Running') {
        Start-Service -Name sshd
        Start-Sleep -Seconds 2
    }

    Ensure-SshdPublicKeyAuthentication

    $account = Resolve-TargetAccount -Name $TargetUser
    $profile = Get-CimInstance Win32_UserProfile | Where-Object SID -eq $account.Sid | Select-Object -First 1
    if ($null -eq $profile -or [string]::IsNullOrWhiteSpace($profile.LocalPath)) {
        throw "Не найден профиль Windows для $($account.Name) ($($account.Sid))."
    }

    $userAuthorizedKeys = Join-Path $profile.LocalPath '.ssh\authorized_keys'
    Add-AuthorizedKey -Path $userAuthorizedKeys -PublicKey $AuthorizedPublicKey -AclSids @($account.Sid, 'S-1-5-18')

    if (Test-LocalGroupMembershipBySid -GroupSid 'S-1-5-32-544' -MemberSid $account.Sid) {
        $adminAuthorizedKeys = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
        Add-AuthorizedKey -Path $adminAuthorizedKeys -PublicKey $AuthorizedPublicKey -AclSids @('S-1-5-32-544', 'S-1-5-18')
    }
    else {
        Write-Log "$($account.Name) не входит в локальные Administrators; используется профильный authorized_keys." 'WARN'
    }

    Restart-Service -Name sshd -Force
    Restrict-EnabledAllowRulesForPort -Port 22 -RemoteAddress $AllowedSubnet
    Ensure-LanFirewallRule -DisplayName 'LocalAI - OpenSSH from trusted LAN' -Protocol TCP -LocalPort 22 -RemoteAddress $AllowedSubnet
}

function Configure-Rdp {
    Write-Log "Настройка подтверждённого blank-password RDP только для $RdpAllowedAddress." 'WARN'
    # Restrict the transport before enabling the listener or weakening logon
    # policy, so there is no broad exposure window.
    Restrict-EnabledAllowRulesForPort -Port 3389 -RemoteAddress $RdpAllowedAddress
    Ensure-LanFirewallRule -DisplayName 'LocalAI - RDP TCP from controller only' -Protocol TCP -LocalPort 3389 -RemoteAddress $RdpAllowedAddress
    Ensure-LanFirewallRule -DisplayName 'LocalAI - RDP UDP from controller only' -Protocol UDP -LocalPort 3389 -RemoteAddress $RdpAllowedAddress

    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name LimitBlankPasswordUse -Type DWord -Value 0
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 0
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Type DWord -Value 0
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name SecurityLayer -Type DWord -Value 2
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name MinEncryptionLevel -Type DWord -Value 3
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name fPromptForPassword -Type DWord -Value 0
    Set-Service -Name TermService -StartupType Automatic
    if ((Get-Service -Name TermService).Status -eq 'Running') {
        Restart-Service -Name TermService -Force
    }
    else {
        Start-Service -Name TermService
    }

    $account = Resolve-TargetAccount -Name $TargetUser
    if (-not (Test-LocalGroupMembershipBySid -GroupSid 'S-1-5-32-555' -MemberSid $account.Sid)) {
        Add-LocalGroupMember -SID 'S-1-5-32-555' -Member $account.Name
        Write-Log "$($account.Name) добавлен в Remote Desktop Users."
    }

    Write-Log 'NLA отключена и удалённый вход с пустым паролем разрешён по явному запросу пользователя.' 'WARN'
}

function Configure-WinRm {
    Write-Log 'Настройка PowerShell Remoting / WinRM.'
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Set-Service -Name WinRM -StartupType Automatic
    Restrict-EnabledAllowRulesForPort -Port 5985 -RemoteAddress $RdpAllowedAddress
    Restrict-EnabledAllowRulesForPort -Port 5986 -RemoteAddress $RdpAllowedAddress
    Ensure-LanFirewallRule -DisplayName 'LocalAI - WinRM HTTP from controller only' -Protocol TCP -LocalPort 5985 -RemoteAddress $RdpAllowedAddress
}

function Configure-SmbWorkspace {
    Write-Log 'Настройка рабочей папки и SMB-доступа.'
    $account = Resolve-TargetAccount -Name $TargetUser
    $adminsName = ([Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')).Translate([Security.Principal.NTAccount]).Value

    $acl = Get-Acl -LiteralPath $WorkDirectory
    foreach ($identity in @($account.Name, $adminsName, 'NT AUTHORITY\SYSTEM')) {
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            $identity,
            'FullControl',
            'ContainerInherit,ObjectInherit',
            'None',
            'Allow'
        )
        $acl.SetAccessRule($rule)
    }
    Set-Acl -LiteralPath $WorkDirectory -AclObject $acl

    Set-Service -Name LanmanServer -StartupType Automatic
    Start-Service -Name LanmanServer

    $share = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if ($null -eq $share) {
        New-SmbShare -Name $ShareName -Path $WorkDirectory -Description 'Local AI deployment audit workspace (LAN only)' -FullAccess $account.Name,$adminsName -CachingMode None -EncryptData $true | Out-Null
        Write-Log "Создан SMB-ресурс \\$env:COMPUTERNAME\$ShareName"
    }
    elseif ([IO.Path]::GetFullPath($share.Path) -ne [IO.Path]::GetFullPath($WorkDirectory)) {
        throw "SMB-имя $ShareName уже указывает на '$($share.Path)'; существующий ресурс не изменён."
    }
    else {
        Grant-SmbShareAccess -Name $ShareName -AccountName $account.Name -AccessRight Full -Force | Out-Null
        Grant-SmbShareAccess -Name $ShareName -AccountName $adminsName -AccessRight Full -Force | Out-Null
        Set-SmbShare -Name $ShareName -CachingMode None -EncryptData $true -Force | Out-Null
        Write-Log "Существующий SMB-ресурс $ShareName проверен и обновлён."
    }

    Restrict-EnabledAllowRulesForPort -Port 445 -RemoteAddress $RdpAllowedAddress
    Ensure-LanFirewallRule -DisplayName 'LocalAI - SMB from controller only' -Protocol TCP -LocalPort 445 -RemoteAddress $RdpAllowedAddress
}

function Configure-DiagnosticPing {
    Ensure-LanFirewallRule -DisplayName 'LocalAI - ICMPv4 Echo from trusted LAN' -Protocol ICMPv4 -RemoteAddress $AllowedSubnet -IcmpType 8
}

function Write-PostChangeVerification {
    $path = Join-Path $inventoryDirectory 'remote-access-after.txt'
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("Collected: $(Get-Date -Format o)")
    Add-Section $lines 'Services' { Get-Service sshd,TermService,WinRM,LanmanServer -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize }
    Add-Section $lines 'Listening ports' { Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object LocalPort -in 22,445,3389,5985,5986 | Sort-Object LocalPort | Select-Object LocalAddress,LocalPort,OwningProcess | Format-Table -AutoSize }
    Add-Section $lines 'SMB share' { Get-SmbShare -Name $ShareName | Select-Object Name,Path,Description,EncryptData,CachingMode | Format-List; Get-SmbShareAccess -Name $ShareName | Select-Object AccountName,AccessControlType,AccessRight | Format-Table -AutoSize }
    Add-Section $lines 'LocalAI firewall rules' { Get-NetFirewallRule -DisplayName 'LocalAI -*' -ErrorAction SilentlyContinue | ForEach-Object { $rule=$_; $port=$rule | Get-NetFirewallPortFilter; $address=$rule | Get-NetFirewallAddressFilter; [pscustomobject]@{Name=$rule.DisplayName;Enabled=$rule.Enabled;Action=$rule.Action;Profile=$rule.Profile;Protocol=$port.Protocol;LocalPort=$port.LocalPort;IcmpType=$port.IcmpType;RemoteAddress=($address.RemoteAddress -join ',')} } | Format-Table -AutoSize }
    Add-Section $lines 'Firewall profiles (must remain enabled)' { Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction | Format-Table -AutoSize }
    Add-Section $lines 'Microsoft Defender status (not modified)' { Get-MpComputerStatus -ErrorAction SilentlyContinue | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,BehaviorMonitorEnabled,IoavProtectionEnabled,AntispywareEnabled | Format-List }
    Add-Section $lines 'RDP settings' { Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name LimitBlankPasswordUse | Select-Object LimitBlankPasswordUse; Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections | Select-Object fDenyTSConnections; Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication,SecurityLayer,MinEncryptionLevel,fPromptForPassword | Select-Object UserAuthentication,SecurityLayer,MinEncryptionLevel,fPromptForPassword | Format-List }
    Write-Utf8File -Path $path -Lines $lines

    $summary = @(
        "Computer=$env:COMPUTERNAME",
        "BootstrapVersion=$scriptVersion",
        "TargetUser=$TargetUser",
        "AllowedSubnet=$AllowedSubnet",
        "RdpAllowedAddress=$RdpAllowedAddress",
        "WorkDirectory=$WorkDirectory",
        "SMB=\\$env:COMPUTERNAME\$ShareName",
        'SSH=22/TCP key-only authentication; password authentication disabled',
        'RDP=3389/TCP+UDP; NLA disabled; blank-password remote logon enabled by explicit user request',
        "WinRM=5985/TCP; source=$RdpAllowedAddress",
        "SMB=445/TCP with share encryption; source=$RdpAllowedAddress",
        "SSH public key fingerprint=SHA256:wNDRXXxIXfy1eXBjSJAMvkM+NNjN1/nFoA4lqFJwt2k",
        "Transcript=$transcriptPath",
        "Rollback=$rollbackDirectory"
    )
    Write-Utf8File -Path (Join-Path $WorkDirectory 'REMOTE-ACCESS.txt') -Lines $summary
}

$exitCode = 0
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Log "Bootstrap version: $scriptVersion"
    Write-Log "Windows detected: $($os.Caption), version $($os.Version), build $($os.BuildNumber)"
    if ($os.Caption -notmatch 'Windows 10') {
        Write-Log 'ОС отличается от ожидаемой Windows 10; аудит продолжен, изменения совместимы с поддерживаемыми desktop Windows.' 'WARN'
    }
    if ($os.Caption -match ' Home') {
        Write-Log 'Windows Home не поддерживает штатный входящий RDP. Неофициальные RDP-патчи не устанавливаются; используйте SSH/WinRM/SMB.' 'WARN'
    }

    if (-not $AuditOnly) {
        $partialSshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
        if ($null -ne $partialSshService) {
            # A previous interrupted run may have installed OpenSSH together
            # with Microsoft's broad default rule. Contain it before the long
            # audit and before accepting any connection.
            Write-Log 'Обнаружен установленный OpenSSH: немедленно ограничиваю входящий SSH доверенной LAN перед продолжением.' 'WARN'
            Restrict-EnabledAllowRulesForPort -Port 22 -RemoteAddress $AllowedSubnet
            Ensure-LanFirewallRule -DisplayName 'LocalAI - OpenSSH from trusted LAN' -Protocol TCP -LocalPort 22 -RemoteAddress $AllowedSubnet
        }
    }

    if ($AuditOnly) {
        Collect-PreChangeAudit
        Write-Log 'AuditOnly: удалённый доступ и firewall не изменялись.'
    }
    else {
        Backup-RemoteAccessState
        Configure-Rdp
        Write-Log 'RDP настроен первым; продолжаю остальные каналы удалённого доступа и аудит.'
        Configure-OpenSsh
        Configure-WinRm
        Configure-SmbWorkspace
        Configure-DiagnosticPing
        Write-PostChangeVerification
        Collect-PreChangeAudit
        Write-Log 'Настройка завершена. Перезагрузка обычно не требуется.'
        Write-Log "SMB: \\192.168.1.65\$ShareName"
        Write-Log 'SSH: ssh -i C:\Users\ACER-X-02\.ssh\id_ed25519_local_ai_admin_v2 <TARGET_USER>@192.168.1.65'
        Write-Log 'RDP: mstsc.exe /v:192.168.1.65'
    }
}
catch {
    $exitCode = 1
    Write-Log $_.Exception.Message 'ERROR'
    Write-Log "Смотрите лог $transcriptPath и резервную копию $rollbackDirectory" 'ERROR'
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
}

exit $exitCode
