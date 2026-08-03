#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
LOG="${REPO}/logs/58-finalize-web-ui-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

systemctl is-active --quiet local-ai-qwen3-tool-proxy.service
systemctl is-active --quiet local-ai-open-webui.service
systemctl is-enabled --quiet local-ai-open-webui.service
curl -fsS --max-time 15 http://127.0.0.1:8080/ | grep -Eiq '<!doctype html|<html'
curl -fsS --max-time 15 http://127.0.0.1:3000/health >/dev/null
curl -fsS --max-time 15 http://127.0.0.1:3000/ | grep -Eiq '<title>Open WebUI</title>|<html'

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: finish the interrupted post-check, run health monitoring, and add rollback instructions to the existing pre-change backup."
  exit 0
fi

backup="$(sudo find /srv/local-ai/backups -maxdepth 1 -mindepth 1 -type d \
  -name 'web-ui-fix-*' -printf '%p\n' | sort | tail -1)"
[[ -n "$backup" && "$backup" == /srv/local-ai/backups/web-ui-fix-* ]]
sudo test -f "$backup/qwen3-coder-tool-proxy.py.before"
sudo systemctl start local-ai-health.service
grep -Fq 'Result: 0 error(s)' /var/lib/local-ai/health-latest.txt
sudo systemctl reset-failed local-ai-qwen3-tool-proxy.service \
  local-ai-open-webui.service local-ai-health.service

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for web UI/gzip fix:
  sudo systemctl disable --now local-ai-open-webui.service
  sudo install -o root -g root -m 0755 ${backup}/qwen3-coder-tool-proxy.py.before /opt/local-ai/apps/qwen3-coder-tool-proxy.py
  sudo rm -f /etc/systemd/system/local-ai-open-webui.service.d/30-qwen3-api.conf
  sudo systemctl daemon-reload
  sudo systemctl restart local-ai-qwen3-tool-proxy.service
  sudo systemctl start local-ai-health.service
EOF

echo "Web UI fix finalized. Backup: $backup"
