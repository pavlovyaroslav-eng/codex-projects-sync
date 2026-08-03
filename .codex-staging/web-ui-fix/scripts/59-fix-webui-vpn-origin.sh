#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly SOURCE="${REPO}/services/local-ai-open-webui.service.d/40-allowed-origins.conf"
readonly TARGET_DIR="/etc/systemd/system/local-ai-open-webui.service.d"
readonly TARGET="${TARGET_DIR}/40-allowed-origins.conf"
LOG="${REPO}/logs/59-fix-webui-vpn-origin-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

test -r "$SOURCE"
grep -Fq 'http://10.93.0.10:3000' "$SOURCE"

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up the Open WebUI origin policy, add the VPN and loopback origins, restart Open WebUI, and verify health."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/webui-origin-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo systemctl cat local-ai-open-webui.service \
  | sudo tee "$backup/local-ai-open-webui.systemd.before" >/dev/null
if sudo test -e "$TARGET"; then
  sudo cp -a "$TARGET" "$backup/40-allowed-origins.conf.before"
else
  sudo touch "$backup/40-allowed-origins.conf.was-absent"
fi

sudo install -d -o root -g root -m 0755 "$TARGET_DIR"
sudo install -o root -g root -m 0644 "$SOURCE" "$TARGET"
sudo systemctl daemon-reload
sudo systemctl restart local-ai-open-webui.service

for _ in {1..120}; do
  if curl -fsS --max-time 3 http://127.0.0.1:3000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -fsS --max-time 15 http://127.0.0.1:3000/health >/dev/null
systemctl is-active --quiet local-ai-open-webui.service
systemctl show local-ai-open-webui.service -p Environment --value \
  | grep -Fq 'http://10.93.0.10:3000'
sudo systemctl reset-failed local-ai-open-webui.service

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for Open WebUI VPN origin fix ${stamp}:
  sudo rm -f ${TARGET}
  sudo systemctl daemon-reload
  sudo systemctl restart local-ai-open-webui.service
EOF

echo "Open WebUI accepts the LAN and VPN origins."
echo "Backup: $backup"
echo "Log: $LOG"
