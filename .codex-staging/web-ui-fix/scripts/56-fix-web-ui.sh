#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly PROXY_SOURCE="${REPO}/scripts/qwen3-coder-tool-proxy.py"
readonly PROXY_TARGET="/opt/local-ai/apps/qwen3-coder-tool-proxy.py"
readonly DROPIN_SOURCE="${REPO}/services/local-ai-open-webui.service.d/30-qwen3-api.conf"
readonly DROPIN_DIR="/etc/systemd/system/local-ai-open-webui.service.d"
readonly DROPIN_TARGET="${DROPIN_DIR}/30-qwen3-api.conf"
LOG="${REPO}/logs/56-fix-web-ui-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

on_error() {
  local rc=$?
  printf 'web-ui-fix: error line=%s rc=%s command=%q\n' \
    "${BASH_LINENO[0]:-unknown}" "$rc" "$BASH_COMMAND" >&2
  exit "$rc"
}
trap on_error ERR

test -r "$PROXY_SOURCE"
test -r "$DROPIN_SOURCE"
/usr/bin/python3 "$PROXY_SOURCE" --self-test
/usr/bin/python3 -m py_compile "$PROXY_SOURCE"
systemd-analyze --no-pager verify /etc/systemd/system/local-ai-open-webui.service
curl -fsS --max-time 10 http://127.0.0.1:8012/health >/dev/null

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up the live proxy/Open WebUI state, install transparent gzip handling, link Open WebUI to the compatibility API, enable :3000, and verify browser/API paths."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/web-ui-fix-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$PROXY_TARGET" "$backup/qwen3-coder-tool-proxy.py.before"
sudo cp -a /etc/systemd/system/local-ai-open-webui.service \
  "$backup/local-ai-open-webui.service.before"
if sudo test -e "$DROPIN_TARGET"; then
  sudo cp -a "$DROPIN_TARGET" "$backup/30-qwen3-api.conf.before"
else
  sudo touch "$backup/30-qwen3-api.conf.was-absent"
fi
sudo systemctl is-active local-ai-open-webui.service \
  | sudo tee "$backup/open-webui-active.before" >/dev/null || true
sudo systemctl is-enabled local-ai-open-webui.service \
  | sudo tee "$backup/open-webui-enabled.before" >/dev/null || true
sudo ufw status verbose | sudo tee "$backup/ufw.before" >/dev/null
sudo sha256sum "$backup/qwen3-coder-tool-proxy.py.before" \
  "$backup/local-ai-open-webui.service.before" \
  | sudo tee "$backup/SHA256SUMS" >/dev/null
sudo diff -u --label qwen3-coder-tool-proxy.py.before \
  --label qwen3-coder-tool-proxy.py.after \
  "$backup/qwen3-coder-tool-proxy.py.before" "$PROXY_SOURCE" \
  | sudo tee "$backup/proxy.diff" >/dev/null || true

sudo install -o root -g root -m 0755 "$PROXY_SOURCE" "$PROXY_TARGET"
sudo install -d -o root -g root -m 0755 "$DROPIN_DIR"
sudo install -o root -g root -m 0644 "$DROPIN_SOURCE" "$DROPIN_TARGET"
sudo systemctl daemon-reload
sudo systemctl restart local-ai-qwen3-tool-proxy.service
sudo systemctl enable --now local-ai-open-webui.service

for _ in {1..120}; do
  if curl -fsS --max-time 3 http://127.0.0.1:3000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -fsS --max-time 10 http://127.0.0.1:8080/health >/dev/null
curl -fsS --max-time 20 http://127.0.0.1:8080/ \
  | grep -Eiq '<!doctype html|<html'
curl -fsS --max-time 10 http://127.0.0.1:8080/v1/models \
  | python3 -c 'import json,sys; assert json.load(sys.stdin)["data"][0]["id"] == "qwen3-coder-30b-a3b-q4km"'
curl -fsS --max-time 10 http://127.0.0.1:3000/health >/dev/null
curl -fsS --max-time 20 http://127.0.0.1:3000/ \
  | grep -Eiq '<title>Open WebUI</title>|<html'

sudo systemctl start local-ai-health.service
grep -Fq 'Result: 0 error(s)' /var/lib/local-ai/health-latest.txt
sudo systemctl reset-failed local-ai-qwen3-tool-proxy.service \
  local-ai-open-webui.service local-ai-health.service
sudo ufw status verbose | sudo tee "$backup/ufw.after" >/dev/null

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for web UI/gzip fix ${stamp}:
  sudo systemctl disable --now local-ai-open-webui.service
  sudo install -o root -g root -m 0755 ${backup}/qwen3-coder-tool-proxy.py.before ${PROXY_TARGET}
  sudo rm -f ${DROPIN_TARGET}
  sudo systemctl daemon-reload
  sudo systemctl restart local-ai-qwen3-tool-proxy.service
  sudo systemctl start local-ai-health.service
EOF

echo "Web UI and gzip proxy paths are healthy."
echo "Backup: $backup"
echo "Log: $LOG"
