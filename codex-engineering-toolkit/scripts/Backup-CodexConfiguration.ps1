[CmdletBinding()]
param(
    [string]$ToolkitRoot,
    [string]$CodexHome,
    [string]$AgentsHome
)

$ErrorActionPreference = 'Stop'
$ToolkitRoot = if ([string]::IsNullOrWhiteSpace($ToolkitRoot)) { Split-Path -Parent $PSScriptRoot } else { $ToolkitRoot }
$CodexHome = if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
}
else { $CodexHome }
$AgentsHome = if ([string]::IsNullOrWhiteSpace($AgentsHome)) { Join-Path $env:USERPROFILE '.agents' } else { $AgentsHome }
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $ToolkitRoot "backups\codex-config-$timestamp"
$excludedNames = @(
    'auth.json', '.env', '.env.local', '.env.production',
    'credentials.json', 'cookies.json', 'installation_id', 'cap_sid'
)
$excludedExtensions = @('.key', '.pem', '.p12', '.pfx', '.sqlite', '.sqlite-shm', '.sqlite-wal')
$excludedSegments = @(
    '.sandbox-secrets', 'sessions', 'attachments', 'computer-use',
    'node_repl', 'process_manager', 'sqlite', 'tmp', '.tmp'
)

function Test-SafeBackupPath {
    param([System.IO.FileInfo]$File, [string]$SourceRoot)

    if ($excludedNames -contains $File.Name) { return $false }
    if ($excludedExtensions -contains $File.Extension.ToLowerInvariant()) { return $false }

    $relative = $File.FullName.Substring($SourceRoot.Length).TrimStart('\')
    $segments = $relative -split '\\'
    foreach ($segment in $segments) {
        if ($excludedSegments -contains $segment) { return $false }
    }
    return $true
}

function Copy-SafeTree {
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { return }
    Get-ChildItem -LiteralPath $Source -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not (Test-SafeBackupPath -File $_ -SourceRoot $Source)) { return }
        $relative = $_.FullName.Substring($Source.Length).TrimStart('\')
        $target = Join-Path $Destination $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}

function Copy-PluginTree {
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { return }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $arguments = @(
        $Source, $Destination, '/E', '/XJ', '/R:1', '/W:1',
        '/COPY:DAT', '/DCOPY:DAT', '/NFL', '/NDL', '/NJH', '/NJS', '/NP',
        '/XF', 'auth.json', '.env', '.env.local', '.env.production',
        'credentials.json', 'cookies.json', '*.key', '*.pem', '*.p12', '*.pfx',
        '/XD', '.remote-plugin-install-staging', '.sandbox-secrets'
    )
    & robocopy.exe @arguments | Out-Null
    if ($LASTEXITCODE -gt 7) {
        throw "Не удалось создать резервную копию plugins (robocopy: $LASTEXITCODE)."
    }
}

function Copy-SanitizedToml {
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { return }
    $insideEnvSection = $false
    $safeLines = foreach ($line in Get-Content -LiteralPath $Source) {
        if ($line -match '^\s*\[([^\]]+)\]\s*$') {
            $insideEnvSection = $Matches[1] -match '(?i)(^|\.)env$'
            $line
            continue
        }
        if (($insideEnvSection -or $line -match '(?i)(token|secret|password|passwd|api[_-]?key|authorization|cookie)') -and $line -match '^\s*([^#=]+?)\s*=') {
            '{0} = "<REDACTED>"' -f $Matches[1].Trim()
        }
        else {
            $line
        }
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    $safeLines | Set-Content -LiteralPath $Destination -Encoding UTF8
}

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
$hashes = @()

if (Test-Path -LiteralPath $CodexHome -PathType Container) {
    $codexTarget = Join-Path $backupRoot '.codex'
    New-Item -ItemType Directory -Path $codexTarget -Force | Out-Null

    Copy-SanitizedToml -Source (Join-Path $CodexHome 'config.toml') -Destination (Join-Path $codexTarget 'config.sanitized.toml')
    foreach ($fileName in @('.codex-global-state.json', '.codex-global-state.json.bak')) {
        $sourceFile = Join-Path $CodexHome $fileName
        if (Test-Path -LiteralPath $sourceFile -PathType Leaf) {
            Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $codexTarget $fileName) -Force
        }
    }
    foreach ($directoryName in @('automations', 'rules', 'skills')) {
        Copy-SafeTree -Source (Join-Path $CodexHome $directoryName) -Destination (Join-Path $codexTarget $directoryName)
    }
    Copy-PluginTree -Source (Join-Path $CodexHome 'plugins') -Destination (Join-Path $codexTarget 'plugins')

    foreach ($candidate in @(
        (Join-Path $CodexHome 'config.toml'),
        (Join-Path $CodexHome '.codex-global-state.json')
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $candidate
            $hashes += [pscustomobject]@{ path = $candidate; sha256 = $hash.Hash }
        }
    }
    $localPlugin = Join-Path $CodexHome 'plugins\yaroslav-engineering-toolkit'
    if (Test-Path -LiteralPath $localPlugin -PathType Container) {
        Get-ChildItem -LiteralPath $localPlugin -Recurse -File | ForEach-Object {
            $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName
            $hashes += [pscustomobject]@{ path = $_.FullName; sha256 = $hash.Hash }
        }
    }
}

if (Test-Path -LiteralPath $AgentsHome -PathType Container) {
    Copy-SafeTree -Source $AgentsHome -Destination (Join-Path $backupRoot '.agents')
    $marketplace = Join-Path $AgentsHome 'plugins\marketplace.json'
    if (Test-Path -LiteralPath $marketplace -PathType Leaf) {
        $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $marketplace
        $hashes += [pscustomobject]@{ path = $marketplace; sha256 = $hash.Hash }
    }
}

$manifest = [ordered]@{
    createdAt = (Get-Date).ToString('o')
    backupRoot = $backupRoot
    sources = @($CodexHome, $AgentsHome)
    excludedNames = $excludedNames
    excludedExtensions = $excludedExtensions
    excludedSegments = $excludedSegments
    originalConfigurationHashes = $hashes
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $backupRoot 'backup-manifest.json') -Encoding UTF8

Write-Output $backupRoot
