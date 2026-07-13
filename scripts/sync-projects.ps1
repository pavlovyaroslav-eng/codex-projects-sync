[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GitExe = 'C:\Users\ACER-X-02\AppData\Local\Programs\ExpressLRS Configurator\dependencies\windows_amd64\PortableGit\cmd\git.exe',
    [string]$LogPath = (Join-Path $env:LOCALAPPDATA 'CodexProjectSync\sync.log')
)

$ErrorActionPreference = 'Stop'
$ExpectedRemoteUrl = 'git@github.com:pavlovyaroslav-eng/codex-projects-sync.git'
$mutex = $null
$mutexAcquired = $false

function Write-SyncLog {
    param([string]$Message, [string]$Level = 'INFO')

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    Write-Output $line
}

function Invoke-Git {
    param([string[]]$Arguments, [switch]$AllowFailure)

    $output = @(& $GitExe -C $RepoRoot @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($item in $output) {
        if ($null -ne $item -and "$item".Trim().Length -gt 0) {
            Write-SyncLog "git $($Arguments -join ' '): $item"
        }
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Команда git $($Arguments -join ' ') завершилась с кодом $exitCode."
    }

    [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output
    }
}

function Test-StagedContent {
    $nameResult = Invoke-Git -Arguments @('diff', '--cached', '--name-only', '--diff-filter=ACMR')
    $paths = @($nameResult.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ })

    $forbiddenPathPattern = '(^|/)(secrets?|private|credentials|backups?|node_modules|vendor|__pycache__|\.venv|venv|build|dist|out|coverage|logs?|tmp|temp)(/|$)|\.(key|pem|p12|pfx|ovpn|log|tmp|temp|cache|bak|zip|7z|rar)$|\.conf\.private$'
    $secretPatterns = @(
        '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----',
        'github_pat_[A-Za-z0-9_]{20,}',
        'gh[pousr]_[A-Za-z0-9]{20,}',
        'sk-[A-Za-z0-9_-]{20,}',
        'AKIA[0-9A-Z]{16}',
        "(?i)(api[_-]?key|access[_-]?token|password|passwd|secret)\s*[:=]\s*[`"']?[A-Za-z0-9+/=_-]{12,}"
    )

    foreach ($relativePath in $paths) {
        $normalized = $relativePath -replace '\\', '/'
        $leaf = Split-Path -Leaf $relativePath
        $isForbiddenEnv = $leaf -eq '.env' -or ($leaf.StartsWith('.env.') -and $leaf -ne '.env.example')
        if ($isForbiddenEnv -or $normalized -match $forbiddenPathPattern) {
            throw "Запрещённый файл попал в индекс: $relativePath"
        }

        $fullPath = Join-Path $RepoRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }

        $fileInfo = Get-Item -LiteralPath $fullPath
        if ($fileInfo.Length -gt 2MB) {
            continue
        }

        try {
            $content = Get-Content -Raw -LiteralPath $fullPath -ErrorAction Stop
        }
        catch {
            continue
        }

        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                throw "Возможный секрет обнаружен в индексируемом файле: $relativePath"
            }
        }
    }
}

try {
    $logDirectory = Split-Path -Parent $LogPath
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

    $mutex = New-Object System.Threading.Mutex($false, 'Local\CodexProjectsGitSync')
    try {
        $mutexAcquired = $mutex.WaitOne(0)
    }
    catch [System.Threading.AbandonedMutexException] {
        $mutexAcquired = $true
    }

    if (-not $mutexAcquired) {
        Write-SyncLog 'Другой процесс синхронизации уже выполняется. Запуск пропущен.' 'WARN'
        exit 0
    }

    Write-SyncLog 'Начало синхронизации.'

    if (-not (Test-Path -LiteralPath $GitExe -PathType Leaf)) {
        throw "Git не найден: $GitExe"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
        throw "Каталог не является Git-репозиторием: $RepoRoot"
    }

    $branch = Invoke-Git -Arguments @('branch', '--show-current')
    if (("$($branch.Output -join '')").Trim() -ne 'main') {
        throw 'Активная ветка не main. Синхронизация остановлена.'
    }

    $origin = Invoke-Git -Arguments @('remote', 'get-url', 'origin')
    if (("$($origin.Output -join '')").Trim() -ne $ExpectedRemoteUrl) {
        throw 'URL origin отличается от ожидаемого. Синхронизация остановлена.'
    }

    # Только fast-forward. При конфликте или расхождении история не изменяется.
    Invoke-Git -Arguments @('pull', '--ff-only', 'origin', 'main') | Out-Null

    $status = Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all')
    if (@($status.Output | Where-Object { "$_".Trim() }).Count -gt 0) {
        Invoke-Git -Arguments @('add', '--all', '--', '.') | Out-Null
        try {
            Test-StagedContent
        }
        catch {
            Invoke-Git -Arguments @('reset', '--quiet') -AllowFailure | Out-Null
            throw
        }

        $staged = Invoke-Git -Arguments @('diff', '--cached', '--quiet') -AllowFailure
        if ($staged.ExitCode -eq 1) {
            $message = 'chore(sync): автоматическая синхронизация {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            Invoke-Git -Arguments @('commit', '-m', $message) | Out-Null
        }
        elseif ($staged.ExitCode -ne 0) {
            throw 'Не удалось проверить индекс перед коммитом.'
        }
    }
    else {
        Write-SyncLog 'Локальных изменений нет.'
    }

    # Push выполняется и без нового коммита, чтобы повторить ранее неудавшуюся отправку.
    Invoke-Git -Arguments @('push', 'origin', 'main') | Out-Null
    Write-SyncLog 'Синхронизация успешно завершена.'
    exit 0
}
catch {
    Write-SyncLog $_.Exception.Message 'ERROR'
    Write-SyncLog 'Синхронизация остановлена без merge, rebase или force push.' 'ERROR'
    exit 1
}
finally {
    if ($mutexAcquired -and $null -ne $mutex) {
        $mutex.ReleaseMutex()
    }
    if ($null -ne $mutex) {
        $mutex.Dispose()
    }
}
