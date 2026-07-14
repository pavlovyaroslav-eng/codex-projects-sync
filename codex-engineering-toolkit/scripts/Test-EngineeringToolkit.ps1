[CmdletBinding()]
param(
    [string]$ToolkitRoot,
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'
if (-not $ToolkitRoot) {
    $ToolkitRoot = Split-Path -Parent $PSScriptRoot
}
$ToolkitRoot = [IO.Path]::GetFullPath($ToolkitRoot)
$logDir = Join-Path $ToolkitRoot 'logs'
$configPath = Join-Path $ToolkitRoot 'config\packages.json'
$pluginRoot = Join-Path $ToolkitRoot 'plugins\yaroslav-engineering-toolkit'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Invoke-SmokeCommand {
    param([string]$FilePath, [string[]]$Arguments, [bool]$AllowNonZeroExit)
    if (-not $FilePath -or -not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return [pscustomobject]@{ ok = $false; exitCode = $null; output = 'Executable not found' }
    }
    $psi = New-Object Diagnostics.ProcessStartInfo
    $quotedArguments = @($Arguments | ForEach-Object {
        '"' + ([string]$_).Replace('"', '\"') + '"'
    }) -join ' '
    if ([IO.Path]::GetExtension($FilePath) -in @('.cmd', '.bat')) {
        $psi.FileName = $env:ComSpec
        $psi.Arguments = '/d /s /c ""' + $FilePath + '" ' + $quotedArguments + '"'
    } else {
        $psi.FileName = $FilePath
        $psi.Arguments = $quotedArguments
    }
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $psi
    try {
        [void]$process.Start()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            return [pscustomobject]@{ ok = $false; exitCode = $null; output = 'Timed out' }
        }
        $ok = ($process.ExitCode -eq 0) -or $AllowNonZeroExit
        return [pscustomobject]@{ ok = $ok; exitCode = $process.ExitCode; output = ('Exit code ' + $process.ExitCode) }
    } catch {
        return [pscustomobject]@{ ok = $false; exitCode = $null; output = $_.Exception.Message }
    } finally {
        if ($process) { $process.Dispose() }
    }
}

$registry = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$results = [Collections.Generic.List[object]]::new()
foreach ($package in $registry.packages) {
    if ($package.name -eq 'openEMS') {
        $results.Add([pscustomobject]@{ name = $package.name; status = 'unavailable'; version = $null; path = $null; critical = $false; detail = 'No trusted WinGet package or approved build was available.' })
        continue
    }
    if ($package.smokeTestMode -eq 'file') {
        $ok = Test-Path -LiteralPath $package.executablePath -PathType Leaf
        $detail = if ($ok) { (Get-Item -LiteralPath $package.executablePath).VersionInfo.FileVersion } else { 'Executable not found' }
        $results.Add([pscustomobject]@{ name = $package.name; status = $(if ($ok) {'passed'} else {'failed'}); version = $package.installedVersion; path = $package.executablePath; critical = $true; detail = $detail })
        continue
    }
    $run = Invoke-SmokeCommand -FilePath $package.executablePath -Arguments @($package.versionArguments) -AllowNonZeroExit ([bool]$package.allowNonZeroExit)
    $detail = (($run.output -split [Environment]::NewLine | Select-Object -First 3) -join ' ').Trim()
    $results.Add([pscustomobject]@{ name = $package.name; status = $(if ($run.ok) {'passed'} else {'failed'}); version = $package.installedVersion; path = $package.executablePath; critical = $true; detail = $detail })
}

$structural = [Collections.Generic.List[object]]::new()
try {
    Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
    $structural.Add([pscustomobject]@{ name = 'packages.json'; status = 'passed'; detail = 'Valid JSON' })
} catch {
    $structural.Add([pscustomobject]@{ name = 'packages.json'; status = 'failed'; detail = $_.Exception.Message })
}

$python = 'C:\Users\ACER-X-02\AppData\Local\Programs\Python\Python312\python.exe'
$previousPythonUtf8 = $env:PYTHONUTF8
$env:PYTHONUTF8 = '1'
$validator = 'C:\Users\ACER-X-02\.codex\skills\.system\plugin-creator\scripts\validate_plugin.py'
$validationRun = Invoke-SmokeCommand -FilePath $python -Arguments @($validator, $pluginRoot) -AllowNonZeroExit $false
$structural.Add([pscustomobject]@{ name = 'personal plugin manifest'; status = $(if ($validationRun.ok) {'passed'} else {'failed'}); detail = $validationRun.output })

$skillValidator = 'C:\Users\ACER-X-02\.codex\skills\.system\skill-creator\scripts\quick_validate.py'
Get-ChildItem -LiteralPath (Join-Path $pluginRoot 'skills') -Directory | ForEach-Object {
    $run = Invoke-SmokeCommand -FilePath $python -Arguments @($skillValidator, $_.FullName) -AllowNonZeroExit $false
    $structural.Add([pscustomobject]@{ name = ('skill:' + $_.Name); status = $(if ($run.ok) {'passed'} else {'failed'}); detail = $run.output })
}
if ($null -eq $previousPythonUtf8) {
    Remove-Item Env:\PYTHONUTF8 -ErrorAction SilentlyContinue
} else {
    $env:PYTHONUTF8 = $previousPythonUtf8
}

$marketplacePath = Join-Path $HOME '.agents\plugins\marketplace.json'
try {
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $entry = @($marketplace.plugins) | Where-Object { $_.name -eq 'yaroslav-engineering-toolkit' }
    if (-not $entry) { throw 'Marketplace entry not found' }
    $structural.Add([pscustomobject]@{ name = 'personal marketplace'; status = 'passed'; detail = $marketplacePath })
} catch {
    $structural.Add([pscustomobject]@{ name = 'personal marketplace'; status = 'failed'; detail = $_.Exception.Message })
}

$task = Get-ScheduledTask -TaskName 'Codex Engineering Toolkit - Weekly Update' -ErrorAction SilentlyContinue
$structural.Add([pscustomobject]@{ name = 'weekly scheduled task'; status = $(if ($task) {'passed'} else {'failed'}); detail = $(if ($task) {$task.State.ToString()} else {'Task not found'}) })

$remotionDir = Join-Path $ToolkitRoot 'tools\media-remotion'
$npm = 'E:\EngineeringTools\NodeJS\node-v24.18.0-win-x64\npm.cmd'
$remotionRun = Invoke-SmokeCommand -FilePath $npm -Arguments @('--prefix', $remotionDir, 'run', 'check') -AllowNonZeroExit $false
$structural.Add([pscustomobject]@{ name = 'Remotion compositions'; status = $(if ($remotionRun.ok) {'passed'} else {'failed'}); detail = $remotionRun.output })

$git = 'E:\EngineeringTools\Git\cmd\git.exe'
$repoRoot = Split-Path -Parent $ToolkitRoot
$gitLines = @(& $git -C $repoRoot status --short 2>&1)
$gitExitCode = $LASTEXITCODE
$outside = @($gitLines | Where-Object { $_ -and $_ -notmatch 'codex-engineering-toolkit' })
$structural.Add([pscustomobject]@{ name = 'Git scope'; status = $(if ($gitExitCode -eq 0 -and $outside.Count -eq 0) {'passed'} else {'failed'}); detail = $(if ($outside.Count) {$outside -join '; '} else {'Changes limited to toolkit'}) })

$secretPatterns = '(?i)(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|api[_-]?key\s*[:=]\s*[^$\s]|password\s*[:=]\s*[^$\s]|gh[pousr]_[A-Za-z0-9_]{20,})'
$scanFiles = Get-ChildItem -LiteralPath $ToolkitRoot -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\(backups|logs|node_modules|\.git)\\' -and $_.Length -lt 2MB
}
$secretHits = @($scanFiles | Select-String -Pattern $secretPatterns -ErrorAction SilentlyContinue)
$structural.Add([pscustomobject]@{ name = 'secret scan'; status = $(if ($secretHits.Count -eq 0) {'passed'} else {'failed'}); detail = $(if ($secretHits.Count) {"$($secretHits.Count) suspicious match(es)"} else {'No credential-shaped values found'}) })

$summary = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    machine = $env:COMPUTERNAME
    toolkitRoot = $ToolkitRoot
    components = $results
    structuralChecks = $structural
}
$installedPath = Join-Path $ToolkitRoot 'installed-components.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $installedPath -Encoding UTF8
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$jsonLog = Join-Path $logDir "verification-$stamp.json"
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonLog -Encoding UTF8

$failed = @($results | Where-Object { $_.critical -and $_.status -eq 'failed' })
$failedStructural = @($structural | Where-Object { $_.status -eq 'failed' })
$report = @(
    '# Last toolkit verification',
    '',
    ('Generated: ' + $summary.generatedAt),
    ('Components passed: ' + @($results | Where-Object status -eq 'passed').Count),
    ('Components unavailable: ' + @($results | Where-Object status -eq 'unavailable').Count),
    ('Critical component failures: ' + $failed.Count),
    ('Structural failures: ' + $failedStructural.Count),
    '',
    '## Failures',
    ''
)
if ($failed.Count + $failedStructural.Count -eq 0) {
    $report += '- None'
} else {
    $failed | ForEach-Object { $report += ('- ' + $_.name + ': ' + $_.detail) }
    $failedStructural | ForEach-Object { $report += ('- ' + $_.name + ': ' + $_.detail) }
}
$report | Set-Content -LiteralPath (Join-Path $logDir 'LAST_TEST_REPORT.md') -Encoding UTF8
$summary
if ($failed.Count + $failedStructural.Count -gt 0) { exit 1 }
