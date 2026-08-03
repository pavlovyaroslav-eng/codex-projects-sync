$ErrorActionPreference = 'Stop'

$remoteCommand = @'
sudo -v && /home/user/ai-station-bootstrap/scripts/98-update-legacy-health-check.sh --apply && grep -F 'Result: 0 error(s)' /var/lib/local-ai/health-latest.txt && test -z "$(systemctl --failed --no-legend)" && echo 'POST_REBOOT_HEALTH_FIX=PASS'
'@

$sshArguments = @(
    '-tt',
    '-o', 'BatchMode=no',
    '-o', 'StrictHostKeyChecking=yes',
    '-i', 'C:\Users\ACER-X-02\.ssh\id_ed25519_local_ai_admin_v2',
    'user@192.168.1.65',
    $remoteCommand.Trim()
)

& ssh.exe @sshArguments
Write-Host ''
Write-Host 'Health-check update session ended. Codex is verifying the result.'
