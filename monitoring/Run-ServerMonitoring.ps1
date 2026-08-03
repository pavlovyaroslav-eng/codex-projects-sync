[CmdletBinding()]
param(
    [string]$ServersConfig = (Join-Path $PSScriptRoot 'servers.json'),
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_rsa",
    [string]$SshPort = '22',
    [string]$SshUser = 'suazzzi',
    [string]$OutputDir = (Join-Path $PSScriptRoot 'monitoring-reports'),
    [switch]$ShowDashboard,
    [switch]$Continuous,
    [int]$IntervalSeconds = 300
)

$ErrorActionPreference = 'Stop'

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN'  { 'Yellow' }
        'SUCCESS' { 'Green' }
        default { 'White' }
    }

    Write-Host "[$timestamp] [$Level] " -NoNewline
    Write-Host $Message -ForegroundColor $color
}

function Get-ServersConfig {
    if (-not (Test-Path $ServersConfig)) {
        Write-ColorLog "Servers config not found at $ServersConfig. Creating default..." 'WARN'

        $defaultConfig = @{
            servers = @(
                @{
                    name = 'azazello'
                    host = 'azazello.raxla.org'
                    ip = '91.242.163.206'
                    description = 'Czech external gateway'
                    critical_services = @('xray', 'docker')
                    critical_ports = @(443, 9443)
                },
                @{
                    name = 'hometele'
                    host = 'hometele.com.ru'
                    ip = '185.71.196.110'
                    description = 'Russian entry point'
                    critical_services = @('xray', 'postfix')
                    critical_ports = @(443, 80)
                },
                @{
                    name = 'www'
                    host = 'www-vpn-wiki-sync'
                    ip = ''
                    description = 'Service node - Matrix, Git-WIKI'
                    critical_services = @('matrix-synapse', 'nginx', 'coturn')
                    critical_ports = @(8008, 8080, 5349)
                }
            )
        }

        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ServersConfig -Encoding UTF8
        Write-ColorLog "Default config created at $ServersConfig" 'SUCCESS'
    }

    return (Get-Content -Raw -Path $ServersConfig | ConvertFrom-Json)
}

function Invoke-SshCommand {
    param(
        [string]$Host,
        [string]$Command,
        [int]$TimeoutSeconds = 30
    )

    $sshCmd = "ssh"
    $sshArgs = @(
        '-o', 'ConnectTimeout=10',
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'LogLevel=ERROR',
        '-i', $SshKeyPath,
        '-p', $SshPort,
        "${SshUser}@${Host}",
        $Command
    )

    try {
        $output = & $sshCmd @sshArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "SSH command failed with exit code $LASTEXITCODE"
        }
        return $output -join "`n"
    }
    catch {
        throw "SSH connection failed: $_"
    }
}

function Test-ServerConnection {
    param([string]$Host)

    try {
        $result = Invoke-SshCommand -Host $Host -Command "echo 'OK'" -TimeoutSeconds 5
        return $result -eq 'OK'
    }
    catch {
        return $false
    }
}

function Deploy-HealthCheckScript {
    param([string]$Host)

    $scriptPath = Join-Path $PSScriptRoot 'server-health-check.sh'
    if (-not (Test-Path $scriptPath)) {
        throw "Health check script not found at $scriptPath"
    }

    Write-ColorLog "Deploying health check script to $Host..." 'INFO'

    # Convert Windows line endings to Unix
    $content = Get-Content -Raw -Path $scriptPath
    $unixContent = $content -replace "`r`n", "`n"
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $unixContent)

    try {
        # Upload script
        $scpCmd = "scp"
        $scpArgs = @(
            '-o', 'StrictHostKeyChecking=no',
            '-o', 'UserKnownHostsFile=/dev/null',
            '-o', 'LogLevel=ERROR',
            '-i', $SshKeyPath,
            '-P', $SshPort,
            $tempFile,
            "${SshUser}@${Host}:/tmp/server-health-check.sh"
        )
        & $scpCmd @scpArgs 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to upload script"
        }

        # Make executable
        Invoke-SshCommand -Host $Host -Command "chmod +x /tmp/server-health-check.sh" | Out-Null
        Write-ColorLog "Script deployed successfully to $Host" 'SUCCESS'
    }
    finally {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
}

function Get-ServerHealth {
    param(
        [string]$Host,
        [string]$ServerName
    )

    Write-ColorLog "Checking health of $ServerName ($Host)..." 'INFO'

    try {
        # Run health check
        $jsonOutput = Invoke-SshCommand -Host $Host -Command "/tmp/server-health-check.sh $ServerName"

        # Parse JSON
        $health = $jsonOutput | ConvertFrom-Json

        # Save to file
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $outputFile = Join-Path $OutputDir "${ServerName}-${timestamp}.json"
        $health | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding UTF8

        Write-ColorLog "Health check completed for $ServerName" 'SUCCESS'
        return $health
    }
    catch {
        Write-ColorLog "Health check failed for $ServerName : $_" 'ERROR'
        return $null
    }
}

function Show-HealthSummary {
    param([array]$HealthData)

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          VPN Infrastructure Health Dashboard                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    foreach ($server in $HealthData) {
        if ($null -eq $server) { continue }

        Write-Host "┌─ $($server.hostname) ─────────────────────────────────" -ForegroundColor Yellow
        Write-Host "│ Uptime      : $($server.system.uptime)"
        Write-Host "│ CPU Usage   : $($server.system.cpu_usage)"
        Write-Host "│ Memory      : $($server.system.memory.usage) used"
        Write-Host "│ Disk Usage  : $($server.system.disk.usage)"
        Write-Host "│ Load Avg    : $($server.system.load)"

        # Services
        Write-Host "│"
        Write-Host "│ Services:" -ForegroundColor Cyan
        foreach ($svc in $server.services.systemd) {
            $statusColor = if ($svc.status -eq 'active') { 'Green' } else { 'Red' }
            Write-Host "│   • $($svc.name.PadRight(20)) : " -NoNewline
            Write-Host $svc.status -ForegroundColor $statusColor
        }

        if ($server.services.failed_count -gt 0) {
            Write-Host "│   ⚠ Failed services: $($server.services.failed_count)" -ForegroundColor Red
        }

        # VPN Status
        if ($server.vpn.xray.installed) {
            $xrayColor = if ($server.vpn.xray.running -eq 'true') { 'Green' } else { 'Red' }
            Write-Host "│"
            Write-Host "│ Xray        : " -NoNewline
            Write-Host $server.vpn.xray.running -ForegroundColor $xrayColor
        }

        # WireGuard
        if ($server.vpn.wireguard.Count -gt 0) {
            Write-Host "│ WireGuard   : $($server.vpn.wireguard.Count) interface(s)" -ForegroundColor Green
        }

        # Critical Ports
        if ($server.critical_ports.Count -gt 0) {
            Write-Host "│"
            Write-Host "│ Critical Ports:" -ForegroundColor Cyan
            foreach ($port in $server.critical_ports) {
                $portColor = if ($port.status -eq 'listening') { 'Green' } else { 'Red' }
                Write-Host "│   • Port $($port.port): " -NoNewline
                Write-Host $port.status -ForegroundColor $portColor
            }
        }

        Write-Host "└────────────────────────────────────────────────────────`n"
    }

    Write-Host "Report saved to: $OutputDir`n" -ForegroundColor Gray
}

function Start-ContinuousMonitoring {
    param([array]$Servers)

    Write-ColorLog "Starting continuous monitoring (interval: ${IntervalSeconds}s). Press Ctrl+C to stop." 'INFO'

    try {
        while ($true) {
            $healthData = @()

            foreach ($server in $Servers) {
                $health = Get-ServerHealth -Host $server.host -ServerName $server.name
                if ($null -ne $health) {
                    $healthData += $health
                }
            }

            if ($ShowDashboard) {
                Clear-Host
                Show-HealthSummary -HealthData $healthData
            }

            Write-ColorLog "Next check in ${IntervalSeconds} seconds..." 'INFO'
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    catch {
        Write-ColorLog "Monitoring stopped: $_" 'WARN'
    }
}

# Main execution
try {
    Write-Host "`n=== VPN Infrastructure Monitoring ===`n" -ForegroundColor Cyan

    # Load config
    $config = Get-ServersConfig
    $servers = $config.servers

    Write-ColorLog "Loaded $($servers.Count) servers from config" 'INFO'

    # Test SSH key
    if (-not (Test-Path $SshKeyPath)) {
        Write-ColorLog "SSH key not found at $SshKeyPath" 'ERROR'
        Write-ColorLog "Please configure SSH key or use -SshKeyPath parameter" 'ERROR'
        exit 1
    }

    # Deploy health check script to all servers
    foreach ($server in $servers) {
        Write-ColorLog "Testing connection to $($server.name)..." 'INFO'

        if (Test-ServerConnection -Host $server.host) {
            Write-ColorLog "Connection successful to $($server.name)" 'SUCCESS'
            Deploy-HealthCheckScript -Host $server.host
        }
        else {
            Write-ColorLog "Cannot connect to $($server.name) ($($server.host))" 'ERROR'
            Write-ColorLog "Skipping $($server.name)..." 'WARN'
        }
    }

    # Run health checks
    if ($Continuous) {
        Start-ContinuousMonitoring -Servers $servers
    }
    else {
        $healthData = @()

        foreach ($server in $servers) {
            $health = Get-ServerHealth -Host $server.host -ServerName $server.name
            if ($null -ne $health) {
                $healthData += $health
            }
        }

        # Show summary
        if ($ShowDashboard) {
            Show-HealthSummary -HealthData $healthData
        }

        Write-ColorLog "Monitoring completed. Reports saved to $OutputDir" 'SUCCESS'
    }
}
catch {
    Write-ColorLog "Fatal error: $_" 'ERROR'
    exit 1
}
