[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$RemoteUrl = 'www-vpn-wiki-sync:/opt/git/vpn-server-wiki.git',
    [string]$GitExe = 'C:\Users\ACER-X-02\AppData\Local\Programs\ExpressLRS Configurator\dependencies\windows_amd64\PortableGit\cmd\git.exe',
    [string]$OpenSshExe = 'C:\Windows\System32\OpenSSH\ssh.exe',
    [string]$LogPath
)

$ErrorActionPreference = 'Stop'
$RepoRoot = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Split-Path -Parent $PSScriptRoot } else { $RepoRoot }
$LogPath = if ([string]::IsNullOrWhiteSpace($LogPath)) { Join-Path $env:LOCALAPPDATA 'CodexProjectSync\vpn-wiki-sync.log' } else { $LogPath }
$ProjectRoot = Join-Path $RepoRoot 'codex-projects-export\01-vpn-server-infrastructure'
$WikiRoot = Join-Path $ProjectRoot 'wiki'
$TargetUpstream = Join-Path $WikiRoot 'upstream'
$Branches = @('www', 'hometele', 'azazello')
$tempRoot = $null
$mutex = $null
$mutexAcquired = $false

function Write-WikiLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    Write-Output $line
}

function Invoke-Git {
    param([string[]]$Arguments, [string]$WorkingDirectory)
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $GitExe -C $WorkingDirectory @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
    if ($exitCode -ne 0) {
        throw "Git-команда завершилась с кодом ${exitCode}: git $($Arguments -join ' ')"
    }
    return $output
}

function Get-SecretFindings {
    param([string]$Root)
    $findings = New-Object System.Collections.Generic.List[object]
    $pathRules = @(
        @{ Category = 'env-file'; Pattern = '(^|/)[.]env($|[.])' },
        @{ Category = 'secrets-directory'; Pattern = '(^|/)(secrets?|credentials|private)(/|$)' },
        @{ Category = 'private-key-file'; Pattern = '[.](key|pem|p12|pfx|ppk)$' },
        @{ Category = 'matrix-alert-config'; Pattern = '(^|/)etc/vpn-audit-alerts/matrix[.]conf$' },
        @{ Category = 'cookie-file'; Pattern = '(^|/)(cookies?)([.]|/|$)' }
    )
    $contentRules = @(
        @{ Category = 'private-key'; Pattern = '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----' },
        @{ Category = 'wireguard-private-key'; Pattern = '(?im)^\s*(PrivateKey|PresharedKey)\s*=' },
        @{ Category = 'possible-vless-uuid'; Pattern = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b' },
        @{ Category = 'reality-private-key'; Pattern = '(?im)^\s*(privateKey|private_key)\s*[:=]' },
        @{ Category = 'hysteria-password'; Pattern = '(?im)^\s*(auth|password)\s*[:=]\s*\S+' },
        @{ Category = 'mtproto-secret'; Pattern = '(?i)(--secret\s+|\b(?:SECRET|MTPROTO_SECRET|proxy_secret|mtproto_secret)\b\s*[:=]\s*|(?:tg://proxy|https://t[.]me/proxy)\S*[?&]secret=)["'']?(?!\[REDACTED_MTPROTO_SECRET\])[0-9a-f]{32,}' },
        @{ Category = 'matrix-access-token'; Pattern = '(?i)(access[_-]?token\s*[:=]|\bsyt_[A-Za-z0-9_-]+)' },
        @{ Category = 'smtp-password'; Pattern = '(?im)^\s*(smtp_pass(word)?|relay_password)\s*[:=]' },
        @{ Category = 'api-token'; Pattern = '(?im)^\s*(api[_-]?key|api[_-]?token|bot[_-]?token)\s*[:=]\s*\S+' },
        @{ Category = 'authorization-link'; Pattern = '(?i)https?://\S+[?&](token|key|secret|auth)=(?!\[REDACTED_MTPROTO_SECRET\])[^&\s]+' },
        @{ Category = 'cookie-data'; Pattern = '(?im)^\s*(cookie|set-cookie)\s*:' }
    )

    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -Force -File) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\') -replace '\\', '/'
        foreach ($rule in $pathRules) {
            if ($relative -match $rule.Pattern) {
                $findings.Add([pscustomobject]@{ Path = $relative; Category = $rule.Category })
            }
        }
        if ($file.Length -gt 4MB) { continue }
        try { $content = Get-Content -Raw -LiteralPath $file.FullName -ErrorAction Stop } catch { continue }
        foreach ($rule in $contentRules) {
            if ($content -match $rule.Pattern) {
                $findings.Add([pscustomobject]@{ Path = $relative; Category = $rule.Category })
            }
        }
    }
    return @($findings | Sort-Object Path, Category -Unique)
}

function Get-MtprotoValueKind {
    param([string]$Value, [string]$Context)
    $trimmed = $Value.Trim().Trim('"', "'", '`', '*')
    if ([string]::IsNullOrWhiteSpace($trimmed)) { return 'ambiguous' }
    if ($trimmed -eq '[REDACTED_MTPROTO_SECRET]') { return 'placeholder' }
    if ($trimmed -match '^(\$\{?\w+\}?|%\w+%|<[^>]+>|\[[^\]]+\])$') { return 'placeholder' }
    if ($trimmed -match '^(?i:[0-9a-f]{32,})$') { return 'secret' }
    if ($trimmed.Length -ge 24 -and $trimmed -match '^[A-Za-z0-9+/_=-]+$' -and $trimmed -match '[A-Za-z]' -and $trimmed -match '[0-9]') { return 'secret' }
    if ($trimmed -match '(?i)^(raw|hex|value|secret|mtproto-secret|not-set|unset|none|null|example|placeholder|не|см[.]?|используется|указан|настроен|хранится)$') { return 'description' }
    if ($Context -match '(?i)(без\s+(значения|префикса)|не\s+(хран|указан|публику)|имя\s+переменной|путь\s+к|файл\s+конфигурации|описание|используется\s+raw|without\s+(value|prefix)|not\s+stored|variable\s+name|config\s+path)') { return 'description' }
    return 'ambiguous'
}

function Sanitize-MtprotoInventories {
    param([string]$Root)
    $relativeFiles = @('www/01-INVENTORY.md', 'hometele/01-INVENTORY.md', 'azazello/01-INVENTORY.md')
    $patterns = @(
        '(?i)(?<prefix>(?:tg://proxy|https://t[.]me/proxy)\?[^\s]*?[?&]secret=)(?<value>[^&\s)]+)',
        '(?i)(?<prefix>--secret\s+)(?<value>[^\s"'']+)',
        '(?i)(?<prefix>\b(?:SECRET|MTPROTO_SECRET|proxy_secret|mtproto_secret|secret)\b\s*[:=]\s*["'']?)(?<value>[^\s,"''}\]]+)'
    )

    foreach ($relative in $relativeFiles) {
        $fullPath = Join-Path $Root ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { throw "Ожидаемый inventory-файл отсутствует: $relative" }
        $lines = @(Get-Content -LiteralPath $fullPath -Encoding UTF8)
        $replacementCount = 0
        $changedLines = New-Object System.Collections.Generic.HashSet[int]
        $inspectedLines = New-Object System.Collections.Generic.HashSet[int]

        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            $line = $lines[$lineIndex]
            foreach ($pattern in $patterns) {
                $matches = @([regex]::Matches($line, $pattern))
                for ($matchIndex = $matches.Count - 1; $matchIndex -ge 0; $matchIndex--) {
                    $match = $matches[$matchIndex]
                    $valueGroup = $match.Groups['value']
                    $kind = Get-MtprotoValueKind -Value $valueGroup.Value -Context $line
                    [void]$inspectedLines.Add($lineIndex + 1)
                    if ($kind -eq 'secret') {
                        $line = $line.Remove($valueGroup.Index, $valueGroup.Length).Insert($valueGroup.Index, '[REDACTED_MTPROTO_SECRET]')
                        $replacementCount++
                        [void]$changedLines.Add($lineIndex + 1)
                    }
                    elseif ($kind -eq 'ambiguous') {
                        Write-WikiLog ("{0}:{1} [mtproto-secret] действие=остановка количество=0" -f $relative, ($lineIndex + 1)) 'ERROR'
                        throw "Неоднозначный формат MTProto secret: $relative, строка $($lineIndex + 1)"
                    }
                }
            }
            $lines[$lineIndex] = $line
        }

        if ($replacementCount -gt 0) { Set-Content -LiteralPath $fullPath -Encoding UTF8 -Value $lines }
        $lineList = if ($inspectedLines.Count) { (@($inspectedLines | Sort-Object) -join ',') } else { 'нет' }
        $action = if ($replacementCount -gt 0) { 'обезличивание' } elseif ($inspectedLines.Count -gt 0) { 'оставлено без изменения' } else { 'совпадений нет' }
        Write-WikiLog ("{0} строки={1} [mtproto-secret] действие={2} количество={3}" -f $relative, $lineList, $action, $replacementCount)
    }
}

function Convert-PublicKeysToFingerprints {
    param([string]$Root)
    $sshKeygen = (Get-Command ssh-keygen.exe -ErrorAction Stop).Source
    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -Force -File -Filter '*.pub') {
        $fingerprint = @(& $sshKeygen -lf $file.FullName 2>$null)
        if ($LASTEXITCODE -ne 0 -or $fingerprint.Count -eq 0) {
            throw "Не удалось получить отпечаток публичного ключа: $($file.FullName.Substring($Root.Length).TrimStart('\'))"
        }
        Set-Content -LiteralPath $file.FullName -Encoding UTF8 -Value ("Public key fingerprint: {0}" -f ($fingerprint -join ' '))
    }
}

function Test-Utf8TextFiles {
    param([string]$Root)
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $textExtensions = @('.md', '.txt', '.conf', '.ini', '.json', '.yaml', '.yml', '.toml', '.sh', '.ps1', '.service', '.timer')
    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -Force -File) {
        if ($textExtensions -notcontains $file.Extension.ToLowerInvariant()) { continue }
        try { [void]$strictUtf8.GetString([System.IO.File]::ReadAllBytes($file.FullName)) }
        catch { throw "Файл не является корректным UTF-8: $($file.FullName.Substring($Root.Length).TrimStart('\'))" }
    }
}

function Test-MarkdownLinks {
    param([string]$Root)
    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -Force -File -Filter '*.md') {
        $content = Get-Content -Raw -LiteralPath $file.FullName
        foreach ($match in [regex]::Matches($content, '(?<!!)\[[^\]]+\]\((?<target>[^)]+)\)')) {
            $target = $match.Groups['target'].Value.Split('#')[0]
            if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^(https?|mailto):') { continue }
            $decoded = [uri]::UnescapeDataString($target.Trim('<', '>'))
            $resolved = Join-Path $file.DirectoryName $decoded
            if (-not (Test-Path -LiteralPath $resolved)) {
                throw "Неразрешённая Markdown-ссылка в $($file.FullName.Substring($Root.Length).TrimStart('\')): $target"
            }
        }
    }
}

function Publish-UpstreamMirror {
    param([string]$PreparedUpstream)
    $newPath = Join-Path $WikiRoot ('.upstream.new-' + [guid]::NewGuid().ToString('N'))
    $backupPath = Join-Path $WikiRoot ('.upstream.old-' + [guid]::NewGuid().ToString('N'))
    Copy-Item -LiteralPath $PreparedUpstream -Destination $newPath -Recurse
    try {
        if (Test-Path -LiteralPath $TargetUpstream) { Move-Item -LiteralPath $TargetUpstream -Destination $backupPath }
        Move-Item -LiteralPath $newPath -Destination $TargetUpstream
        if (Test-Path -LiteralPath $backupPath) { Remove-Item -LiteralPath $backupPath -Recurse -Force }
    }
    catch {
        if ((-not (Test-Path -LiteralPath $TargetUpstream)) -and (Test-Path -LiteralPath $backupPath)) {
            Move-Item -LiteralPath $backupPath -Destination $TargetUpstream
        }
        if (Test-Path -LiteralPath $newPath) { Remove-Item -LiteralPath $newPath -Recurse -Force }
        throw
    }
}

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $LogPath) -Force | Out-Null
    $mutex = New-Object System.Threading.Mutex($false, 'Local\CodexVpnWikiSync')
    try { $mutexAcquired = $mutex.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $mutexAcquired = $true }
    if (-not $mutexAcquired) { throw 'Другой импорт WIKI уже выполняется.' }
    if (-not (Test-Path -LiteralPath $GitExe)) { throw "Git не найден: $GitExe" }
    if (-not (Test-Path -LiteralPath $OpenSshExe)) { throw "Windows OpenSSH не найден: $OpenSshExe" }

    Write-WikiLog 'Начало одностороннего импорта Git-WIKI.'
    $env:GIT_TERMINAL_PROMPT = '0'
    $env:GIT_SSH_VARIANT = 'ssh'
    $env:GIT_SSH = $OpenSshExe
    $env:GIT_SSH_COMMAND = 'C:/Windows/System32/OpenSSH/ssh.exe -o IdentityAgent=none'
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-vpn-wiki-' + [guid]::NewGuid().ToString('N'))
    $cloneRoot = Join-Path $tempRoot 'repository'
    $prepared = Join-Path $tempRoot 'upstream'
    New-Item -ItemType Directory -Path $prepared -Force | Out-Null

    Invoke-Git -WorkingDirectory $tempRoot -Arguments @('clone', '--no-checkout', '--', $RemoteUrl, $cloneRoot) | Out-Null
    Invoke-Git -WorkingDirectory $cloneRoot -Arguments @('fetch', '--prune', 'origin', '+refs/heads/*:refs/remotes/origin/*') | Out-Null

    foreach ($branch in $Branches) {
        $branchRoot = Join-Path $prepared $branch
        New-Item -ItemType Directory -Path $branchRoot -Force | Out-Null
        Invoke-Git -WorkingDirectory $cloneRoot -Arguments @('checkout', '--force', '--detach', ('refs/remotes/origin/' + $branch)) | Out-Null
        Invoke-Git -WorkingDirectory $cloneRoot -Arguments @('clean', '-fdx') | Out-Null
        foreach ($item in Get-ChildItem -LiteralPath $cloneRoot -Force | Where-Object { $_.Name -ne '.git' }) {
            Copy-Item -LiteralPath $item.FullName -Destination $branchRoot -Recurse -Force
        }
    }

    @(
        '# Автоматическое зеркало серверной WIKI',
        '',
        'Каталог создан `scripts/sync-vpn-wiki.ps1`. Не редактировать вручную.',
        '',
        '- `www/` — ветка `www`',
        '- `hometele/` — ветка `hometele`',
        '- `azazello/` — ветка `azazello`',
        '',
        'Перед публикацией каждая ветка экспортируется без `.git`, проходит обезличивание и полную проверку секретов.'
    ) | Set-Content -LiteralPath (Join-Path $prepared 'README.md') -Encoding UTF8

    if (Get-ChildItem -LiteralPath $prepared -Recurse -Force -Directory | Where-Object { $_.Name -eq '.git' }) {
        throw 'Во временном экспорте обнаружен вложенный .git.'
    }
    Sanitize-MtprotoInventories -Root $prepared
    Convert-PublicKeysToFingerprints -Root $prepared
    $findings = @(Get-SecretFindings -Root $prepared)
    if ($findings.Count -gt 0) {
        foreach ($finding in $findings) { Write-WikiLog ("Исключён импорт: {0} [{1}]" -f $finding.Path, $finding.Category) 'ERROR' }
        throw 'Обнаружены потенциальные секреты. Upstream не обновлён.'
    }
    Test-Utf8TextFiles -Root $prepared
    Test-MarkdownLinks -Root $prepared
    Publish-UpstreamMirror -PreparedUpstream $prepared
    Write-WikiLog ('Импортированы ветки: ' + ($Branches -join ', '))
    Write-WikiLog 'Импорт Git-WIKI успешно завершён.'
    exit 0
}
catch {
    Write-WikiLog $_.Exception.Message 'ERROR'
    Write-WikiLog 'Импорт остановлен; существующий wiki/upstream не изменён либо восстановлен.' 'ERROR'
    exit 1
}
finally {
    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
    if ($mutexAcquired -and $mutex) { $mutex.ReleaseMutex() }
    if ($mutex) { $mutex.Dispose() }
}
