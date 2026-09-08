#requires -Version 7.0

<#
.SYNOPSIS
    Safely rotates a local HomeBot Matrix session and starts the bot again.

.DESCRIPTION
    1. Stops only Python processes whose command line contains BotScript (or the
       explicitly supplied BotProcessId values).
    2. Logs in to Matrix using a clean bootstrap device.
    3. Lists and, after an explicit confirmation, revokes all old devices except
       IDs supplied through KeepDeviceId.
    4. Moves the old local Matrix state to a timestamped backup.
    5. Starts the bot with stable session and crypto-store paths in environment
       variables.
    6. Lets the bot adopt that bootstrap device, avoiding a second password login.

    The bot must read HOMEBOT_SESSION_FILE and HOMEBOT_CRYPTO_STORE. See the
    accompanying homebot-matrix-config.py.example file.

.EXAMPLE
    # When reset-homebot.ps1 and element_bot.py are in the same directory:
    pwsh -File .\reset-homebot.ps1

.EXAMPLE
    pwsh -File .\reset-homebot.ps1 -BotScript C:\HomeBot\homebot.py -Force
#>

[CmdletBinding()]
param(
    [string]$BotScript = (Join-Path $PSScriptRoot 'element_bot.py'),

    [string]$PythonExe = "python",

    [string]$Homeserver = "https://matrix.hometele.com.ru",

    [string]$UserId = "@deminbot:matrix.hometele.com.ru",

    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA "HomeBot\matrix"),

    [string[]]$KeepDeviceId = @(),

    [int[]]$BotProcessId = @(),

    [securestring]$MatrixPassword,

    [ValidateRange(5, 120)]
    [int]$StartupTimeoutSeconds = 30,

    [switch]$SkipServerCleanup,

    [switch]$SkipConfigCheck,

    [switch]$NoLaunch,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Get-SafeFullPath {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Purpose
    )

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $driveRoot = [IO.Path]::GetPathRoot($fullPath).TrimEnd('\')
    $profileRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')

    if ($fullPath -eq $driveRoot -or $fullPath -eq $profileRoot) {
        throw "$Purpose cannot be a drive root or the user-profile root: $fullPath"
    }

    return $fullPath
}

function Invoke-MatrixJson {
    param(
        [Parameter(Mandatory)] [ValidateSet('GET', 'POST')] [string]$Method,
        [Parameter(Mandatory)] [string]$Path,
        [string]$AccessToken,
        [object]$Body,
        [switch]$AllowHttpError
    )

    $request = @{
        Method = $Method
        Uri = "$script:MatrixBase$Path"
    }

    if ($AccessToken) {
        $request.Headers = @{ Authorization = "Bearer $AccessToken" }
    }

    if ($null -ne $Body) {
        $request.ContentType = 'application/json; charset=utf-8'
        $request.Body = $Body | ConvertTo-Json -Depth 8 -Compress
    }

    # Always capture HTTP errors ourselves so Matrix rate limits can be obeyed.
    $request.SkipHttpErrorCheck = $true
    $request.StatusCodeVariable = 'matrixStatusCode'

    $maximumRateLimitRetries = 4
    for ($attempt = 0; $attempt -le $maximumRateLimitRetries; $attempt++) {
        $matrixStatusCode = $null
        $response = Invoke-RestMethod @request
        $statusCode = [int]$matrixStatusCode

        if ($statusCode -eq 429) {
            $hasRetryAfter = $null -ne $response -and
                $response.PSObject.Properties.Name -contains 'retry_after_ms'
            $retryAfterMs = if ($hasRetryAfter -and [long]$response.retry_after_ms -gt 0) {
                [long]$response.retry_after_ms
            } else {
                5000L
            }

            if ($attempt -ge $maximumRateLimitRetries) {
                throw "Matrix rate limit is still active after $maximumRateLimitRetries retries. Last retry_after_ms=$retryAfterMs"
            }

            $waitSeconds = [math]::Ceiling($retryAfterMs / 1000.0)
            Write-Warning "Matrix rate limit reached. Waiting $waitSeconds seconds before retry $($attempt + 1)/$maximumRateLimitRetries ..."

            # Sleep in bounded chunks so the wait remains interruptible with Ctrl+C.
            $remainingMs = $retryAfterMs + 250
            while ($remainingMs -gt 0) {
                $sleepMs = [math]::Min($remainingMs, 30000)
                Start-Sleep -Milliseconds $sleepMs
                $remainingMs -= $sleepMs
            }
            continue
        }

        if ($AllowHttpError) {
            return [pscustomobject]@{
                StatusCode = $statusCode
                Body = $response
            }
        }

        if ($statusCode -lt 200 -or $statusCode -ge 300) {
            $hasErrorCode = $null -ne $response -and
                $response.PSObject.Properties.Name -contains 'errcode'
            $matrixError = if ($hasErrorCode) {
                "$($response.errcode): $($response.error)"
            } else {
                $response | ConvertTo-Json -Depth 5 -Compress
            }
            throw "Matrix request failed (HTTP $statusCode): $matrixError"
        }

        return $response
    }
}

function Remove-MatrixDevices {
    param(
        [Parameter(Mandatory)] [string]$AccessToken,
        [Parameter(Mandatory)] [string[]]$DeviceIds,
        [Parameter(Mandatory)] [string]$LoginUser,
        [Parameter(Mandatory)] [string]$PlainPassword
    )

    if ($DeviceIds.Count -eq 0) {
        return
    }

    $initial = Invoke-MatrixJson `
        -Method POST `
        -Path '/_matrix/client/v3/delete_devices' `
        -AccessToken $AccessToken `
        -Body @{ devices = $DeviceIds } `
        -AllowHttpError

    if ($initial.StatusCode -ge 200 -and $initial.StatusCode -lt 300) {
        return
    }

    if ($initial.StatusCode -ne 401) {
        throw "Matrix returned HTTP $($initial.StatusCode) while requesting device deletion."
    }

    $auth = @{
        type = 'm.login.password'
        identifier = @{
            type = 'm.id.user'
            user = $LoginUser
        }
        password = $PlainPassword
    }

    if ($initial.Body.PSObject.Properties.Name -contains 'session' -and $initial.Body.session) {
        $auth.session = $initial.Body.session
    }

    $final = Invoke-MatrixJson `
        -Method POST `
        -Path '/_matrix/client/v3/delete_devices' `
        -AccessToken $AccessToken `
        -Body @{
            devices = $DeviceIds
            auth = $auth
        } `
        -AllowHttpError

    if ($final.StatusCode -lt 200 -or $final.StatusCode -ge 300) {
        $hasErrorCode = $null -ne $final.Body -and
            $final.Body.PSObject.Properties.Name -contains 'errcode'
        $matrixError = if ($hasErrorCode -and $final.Body.errcode) {
            "$($final.Body.errcode): $($final.Body.error)"
        } else {
            $final.Body | ConvertTo-Json -Depth 5 -Compress
        }
        throw "Matrix rejected device deletion (HTTP $($final.StatusCode)): $matrixError"
    }
}

$botScriptFull = [IO.Path]::GetFullPath($BotScript)
if (-not (Test-Path -LiteralPath $botScriptFull -PathType Leaf)) {
    throw "Bot script not found: $botScriptFull"
}

$stateRootFull = Get-SafeFullPath -Path $StateRoot -Purpose 'StateRoot'
$botDirectory = Split-Path -Parent $botScriptFull
$pythonCommand = Get-Command $PythonExe -ErrorAction Stop
$pythonPath = $pythonCommand.Source
$script:MatrixBase = $Homeserver.TrimEnd('/')
$loginUser = if ($UserId -match '^@([^:]+):') { $Matches[1] } else { $UserId }

if (-not $SkipConfigCheck) {
    $candidateFiles = @($botScriptFull)
    $helperPath = Join-Path $botDirectory 'homebot_matrix_config.py'
    if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
        $candidateFiles += $helperPath
    }

    $combinedSource = ($candidateFiles | ForEach-Object {
        Get-Content -LiteralPath $_ -Raw
    }) -join "`n"

    # The outer @() is intentional: Where-Object returns a scalar when exactly
    # one marker is missing, and StrictMode then rejects the .Count access.
    $missingMarkers = @(
        @(
            'HOMEBOT_SESSION_FILE',
            'HOMEBOT_CRYPTO_STORE',
            'MATRIX_PASSWORD',
            'MATRIX_ACCESS_TOKEN'
        ) | Where-Object { $combinedSource -notmatch [regex]::Escape($_) }
    )

    if ($missingMarkers.Count -gt 0) {
        throw @"
The bot is not yet configured to use the persistent state supplied by this script.
Missing markers: $($missingMarkers -join ', ')
Copy homebot-matrix-config.py.example next to the bot as homebot_matrix_config.py,
use create_bot() from it, or update the bot equivalently. Use -SkipConfigCheck only
after manually confirming the same settings exist.
"@
    }
}

Write-Host "Checking Matrix endpoint $script:MatrixBase ..."
$null = Invoke-MatrixJson -Method GET -Path '/_matrix/client/versions'

if ($null -eq $MatrixPassword) {
    $MatrixPassword = Read-Host "Matrix password for $UserId" -AsSecureString
}

$credential = [pscredential]::new($loginUser, $MatrixPassword)
$plainPassword = $credential.GetNetworkCredential().Password
if ([string]::IsNullOrWhiteSpace($plainPassword)) {
    throw 'The Matrix password is empty.'
}

$maintenanceToken = $null
$bootstrapSessionAdopted = $false
$oldEnvironment = @{
    HOMEBOT_SESSION_FILE = $env:HOMEBOT_SESSION_FILE
    HOMEBOT_CRYPTO_STORE = $env:HOMEBOT_CRYPTO_STORE
    MATRIX_HOMESERVER = $env:MATRIX_HOMESERVER
    MATRIX_USER_ID = $env:MATRIX_USER_ID
    MATRIX_USERNAME = $env:MATRIX_USERNAME
    MATRIX_PASSWORD = $env:MATRIX_PASSWORD
    MATRIX_ACCESS_TOKEN = $env:MATRIX_ACCESS_TOKEN
    PYTHONUNBUFFERED = $env:PYTHONUNBUFFERED
}

try {
    # Stop the bot and its Python watchdog/child processes. Some launchers use
    # py.exe or versioned names such as python3.11.exe, not only python.exe.
    $processIds = [Collections.Generic.HashSet[int]]::new()
    foreach ($id in $BotProcessId) {
        $null = $processIds.Add($id)
    }

    $escapedScript = [regex]::Escape($botScriptFull)
    $escapedScriptName = [regex]::Escape((Split-Path -Leaf $botScriptFull))
    $escapedBotDirectory = [regex]::Escape($botDirectory.TrimEnd('\') + '\')
    $pythonInterpreterPattern = '^(python|pythonw|py|pyw)(\d+(\.\d+)*)?\.exe$'
    $matchingProcesses = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match $pythonInterpreterPattern -and
        $_.CommandLine -and
        (
            $_.CommandLine -match $escapedScript -or
            $_.CommandLine -match $escapedScriptName -or
            $_.CommandLine -match $escapedBotDirectory
        )
    })

    $matchingProcesses | ForEach-Object {
        $null = $processIds.Add([int]$_.ProcessId)
    }

    if ($processIds.Count -gt 0) {
        Write-Host "`nHomeBot processes selected for stopping:"
        Get-CimInstance Win32_Process | Where-Object {
            $processIds.Contains([int]$_.ProcessId)
        } | Select-Object ProcessId, Name, CommandLine | Format-Table -Wrap | Out-Host

        if (-not $Force) {
            $stopConfirmation = Read-Host 'Type STOP to terminate these processes'
            if ($stopConfirmation -cne 'STOP') {
                throw 'Operation cancelled; no HomeBot process was stopped.'
            }
        }
    }

    if ($processIds.Count -eq 0) {
        Write-Warning 'No running HomeBot/watchdog process was found.'
    } else {
        # Repeat discovery after termination: a watchdog may create one last
        # child process between the first process listing and its own exit.
        for ($stopRound = 1; $stopRound -le 5; $stopRound++) {
            $currentProcesses = @(Get-CimInstance Win32_Process | Where-Object {
                $isExplicitId = $processIds.Contains([int]$_.ProcessId)
                $isBotPython = $_.Name -match $pythonInterpreterPattern -and
                    $_.CommandLine -and
                    (
                        $_.CommandLine -match $escapedScript -or
                        $_.CommandLine -match $escapedScriptName -or
                        $_.CommandLine -match $escapedBotDirectory
                    )
                $isExplicitId -or $isBotPython
            })

            if ($currentProcesses.Count -eq 0) {
                break
            }

            foreach ($process in $currentProcesses) {
                Write-Host "Stopping HomeBot/watchdog PID $($process.ProcessId) ($($process.Name)) ..."
                $null = $processIds.Add([int]$process.ProcessId)
            }
            Stop-Process -Id @($currentProcesses.ProcessId) -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }

        $survivors = @(Get-CimInstance Win32_Process | Where-Object {
            $_.Name -match $pythonInterpreterPattern -and
            $_.CommandLine -and
            (
                $_.CommandLine -match $escapedScript -or
                $_.CommandLine -match $escapedScriptName -or
                $_.CommandLine -match $escapedBotDirectory
            )
        })
        if ($survivors.Count -gt 0) {
            throw 'HomeBot/watchdog is still running after five stop attempts. Stop it manually before retrying.'
        }
    }

    if (-not $SkipServerCleanup) {
        Write-Host 'Creating a clean Matrix bootstrap session ...'
        $login = Invoke-MatrixJson -Method POST -Path '/_matrix/client/v3/login' -Body @{
            type = 'm.login.password'
            identifier = @{
                type = 'm.id.user'
                user = $loginUser
            }
            password = $plainPassword
            device_display_name = 'HomeBot local bot (clean session)'
        }

        $maintenanceToken = $login.access_token
        $maintenanceDeviceId = $login.device_id
        if (-not $maintenanceToken -or -not $maintenanceDeviceId) {
            throw 'Matrix login succeeded without returning an access token and device ID.'
        }

        $deviceResponse = Invoke-MatrixJson `
            -Method GET `
            -Path '/_matrix/client/v3/devices' `
            -AccessToken $maintenanceToken

        $oldDevices = @($deviceResponse.devices | Where-Object {
            $_.device_id -ne $maintenanceDeviceId -and
            $KeepDeviceId -notcontains $_.device_id
        })

        Write-Host "`nDevices selected for revocation:"
        if ($oldDevices.Count -eq 0) {
            Write-Host '  none'
        } else {
            $oldDevices |
                Select-Object device_id, display_name, last_seen_ts, last_seen_ip |
                Format-Table -AutoSize |
                Out-Host
        }

        if ($oldDevices.Count -gt 0 -and -not $Force) {
            $confirmation = Read-Host "Type DELETE to revoke these $($oldDevices.Count) devices"
            if ($confirmation -cne 'DELETE') {
                throw 'Operation cancelled; no old Matrix devices were revoked.'
            }
        }

        if ($oldDevices.Count -gt 0) {
            Remove-MatrixDevices `
                -AccessToken $maintenanceToken `
                -DeviceIds @($oldDevices.device_id) `
                -LoginUser $loginUser `
                -PlainPassword $plainPassword
            Write-Host "Revoked $($oldDevices.Count) old Matrix devices."
        }
    }

    # Move the old state only after server cleanup succeeds. The move is the backup.
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    if (Test-Path -LiteralPath $stateRootFull) {
        $stateParent = Split-Path -Parent $stateRootFull
        $stateLeaf = Split-Path -Leaf $stateRootFull
        $backupPath = Join-Path $stateParent "$stateLeaf.stale-$timestamp"
        $backupPathFull = Get-SafeFullPath -Path $backupPath -Purpose 'Backup path'

        if ((Split-Path -Parent $backupPathFull) -ne $stateParent) {
            throw 'Refusing to move Matrix state outside its current parent directory.'
        }

        Write-Host "Moving old local Matrix state to $backupPathFull"
        Move-Item -LiteralPath $stateRootFull -Destination $backupPathFull
    }

    $cryptoStore = Join-Path $stateRootFull 'crypto_store'
    $sessionFile = Join-Path $stateRootFull 'session.txt'
    $logDirectory = Join-Path $stateRootFull 'logs'
    $null = New-Item -ItemType Directory -Path $cryptoStore -Force
    $null = New-Item -ItemType Directory -Path $logDirectory -Force

    if ($NoLaunch) {
        Write-Host "New empty Matrix state prepared at $stateRootFull"
        return
    }

    $stdoutLog = Join-Path $logDirectory 'homebot.stdout.log'
    $stderrLog = Join-Path $logDirectory 'homebot.stderr.log'

    $env:HOMEBOT_SESSION_FILE = $sessionFile
    $env:HOMEBOT_CRYPTO_STORE = $cryptoStore
    $env:MATRIX_HOMESERVER = $script:MatrixBase
    $env:MATRIX_USER_ID = $UserId
    $env:MATRIX_USERNAME = $loginUser
    $env:MATRIX_PASSWORD = $plainPassword
    if ($maintenanceToken) {
        # The bot adopts this already-authenticated device. This avoids a second
        # password login immediately after cleanup and therefore avoids Synapse's
        # per-account login rate limit.
        $env:MATRIX_ACCESS_TOKEN = $maintenanceToken
    } else {
        Remove-Item -LiteralPath 'Env:MATRIX_ACCESS_TOKEN' -ErrorAction SilentlyContinue
    }
    $env:PYTHONUNBUFFERED = '1'

    Write-Host "Starting a clean HomeBot instance ..."
    $quotedBotScript = '"' + $botScriptFull + '"'
    $newProcess = Start-Process `
        -FilePath $pythonPath `
        -ArgumentList $quotedBotScript `
        -WorkingDirectory $botDirectory `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -WindowStyle Hidden `
        -PassThru

    $deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if ($newProcess.HasExited) {
            $errorTail = if (Test-Path -LiteralPath $stderrLog) {
                (Get-Content -LiteralPath $stderrLog -Tail 30) -join "`n"
            } else {
                '(no stderr log)'
            }
            throw "HomeBot exited during startup with code $($newProcess.ExitCode).`n$errorTail"
        }

        if (Test-Path -LiteralPath $sessionFile -PathType Leaf) {
            $sessionInfo = Get-Item -LiteralPath $sessionFile
            if ($sessionInfo.Length -gt 0) {
                break
            }
        }
    }

    if (-not (Test-Path -LiteralPath $sessionFile -PathType Leaf)) {
        Stop-Process -Id $newProcess.Id -Force -ErrorAction SilentlyContinue
        throw "HomeBot did not create session.txt within $StartupTimeoutSeconds seconds. It was stopped to prevent it from running with an unsaved bootstrap token. Check $stderrLog"
    } else {
        $bootstrapSessionAdopted = [bool]$maintenanceToken
        Write-Host "HomeBot started as PID $($newProcess.Id)."
        Write-Host "Session file: $sessionFile"
        Write-Host "Crypto store: $cryptoStore"
        Write-Host "Logs: $logDirectory"
    }
}
finally {
    if ($maintenanceToken -and -not $bootstrapSessionAdopted) {
        try {
            $null = Invoke-MatrixJson `
                -Method POST `
                -Path '/_matrix/client/v3/logout' `
                -AccessToken $maintenanceToken `
                -Body @{}
            Write-Host 'Unused Matrix bootstrap session logged out.'
        } catch {
            Write-Warning "Could not log out the unused bootstrap session: $($_.Exception.Message)"
        }
    } elseif ($bootstrapSessionAdopted) {
        Write-Host 'The bootstrap Matrix session is now the persistent HomeBot session.'
    }

    foreach ($name in $oldEnvironment.Keys) {
        $oldValue = $oldEnvironment[$name]
        if ($null -eq $oldValue) {
            Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
        } else {
            Set-Item -LiteralPath "Env:$name" -Value $oldValue
        }
    }

    $plainPassword = $null
    $credential = $null
    $MatrixPassword = $null
    [GC]::Collect()
}
