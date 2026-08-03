$ErrorActionPreference = 'Stop'

$remoteCommand = @'
sudo -v && /home/user/ai-station-bootstrap/scripts/98-update-legacy-health-check.sh --apply && systemctl is-active qwen3-coder.service pyghidra-mcp.service && curl -fsS http://127.0.0.1:8012/health && grep -F 'Result: 0 error(s)' /var/lib/local-ai/health-latest.txt && test -z "$(systemctl --failed --no-legend)" && echo 'PRE_REBOOT_CHECKS=PASS; rebooting local-ai now' && sudo systemctl reboot
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
Write-Host 'SSH session ended. Codex is monitoring the station restart.'
