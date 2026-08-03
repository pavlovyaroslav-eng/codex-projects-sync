#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly UNIT_SOURCE="${REPO}/services/local-ai-qwen3-tool-proxy.service"
readonly UNIT_TARGET="/etc/systemd/system/local-ai-qwen3-tool-proxy.service"
readonly HEALTH_SOURCE="${REPO}/configs/bin/local-ai-health-check-v3"
readonly HEALTH_TARGET="/usr/local/sbin/local-ai-health-check"
readonly CONTROLLER_CIDR="192.168.1.41"
readonly VPN_CIDR="10.93.0.0/24"
LOG="${REPO}/logs/55-api-compat-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

on_error() {
  local rc=$?
  printf 'api-compat: error line=%s rc=%s command=%q\n' \
    "${BASH_LINENO[0]:-unknown}" "$rc" "$BASH_COMMAND" >&2
  exit "$rc"
}
trap on_error ERR

test -r "$UNIT_SOURCE"
test -r "$HEALTH_SOURCE"
test -r /opt/local-ai/apps/qwen3-coder-tool-proxy.py
bash -n "$HEALTH_SOURCE"
/usr/bin/python3 /opt/local-ai/apps/qwen3-coder-tool-proxy.py --self-test
systemd-analyze --no-pager verify "$UNIT_SOURCE"
curl -fsS --max-time 10 http://127.0.0.1:8012/health >/dev/null

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: restore the WIKI-compatible API on :8080 via the existing Qwen tool-call adapter, keep the model on 127.0.0.1:8012, preserve controller/VPN-only UFW scope, and add both endpoints to health monitoring."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/api-compat-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"

sudo cp -a "$UNIT_TARGET" "$backup/local-ai-qwen3-tool-proxy.service.before"
sudo cp -a "$HEALTH_TARGET" "$backup/local-ai-health-check.before"
sudo sha256sum \
  "$backup/local-ai-qwen3-tool-proxy.service.before" \
  "$backup/local-ai-health-check.before" \
  | sudo tee "$backup/SHA256SUMS" >/dev/null
sudo systemctl is-active local-ai-qwen3-tool-proxy.service \
  | sudo tee "$backup/proxy-active.before" >/dev/null || true
sudo systemctl is-enabled local-ai-qwen3-tool-proxy.service \
  | sudo tee "$backup/proxy-enabled.before" >/dev/null || true
sudo ufw status verbose | sudo tee "$backup/ufw.before" >/dev/null

sudo diff -u --label local-ai-qwen3-tool-proxy.service.before \
  --label local-ai-qwen3-tool-proxy.service.after \
  "$backup/local-ai-qwen3-tool-proxy.service.before" "$UNIT_SOURCE" \
  | sudo tee "$backup/proxy-unit.diff" >/dev/null || true
sudo diff -u --label local-ai-health-check.before \
  --label local-ai-health-check.after \
  "$backup/local-ai-health-check.before" "$HEALTH_SOURCE" \
  | sudo tee "$backup/health-check.diff" >/dev/null || true

ufw_status="$(sudo ufw status)"
sudo ufw status >/dev/null
lan_rule_added=0
vpn_rule_added=0
if ! grep -E "8080/tcp.*${CONTROLLER_CIDR}" <<<"$ufw_status" >/dev/null; then
  sudo ufw allow from "$CONTROLLER_CIDR" to any port 8080 proto tcp \
    comment 'local-ai API controller'
  lan_rule_added=1
fi
if ! grep -E "8080/tcp on tun93.*10\.93\.0\.0/24" <<<"$ufw_status" >/dev/null; then
  sudo ufw allow in on tun93 from "$VPN_CIDR" to any port 8080 proto tcp \
    comment 'local-ai API VPN'
  vpn_rule_added=1
fi

sudo install -o root -g root -m 0644 "$UNIT_SOURCE" "$UNIT_TARGET"
sudo install -o root -g root -m 0755 "$HEALTH_SOURCE" "$HEALTH_TARGET"
sudo systemctl daemon-reload
sudo systemctl enable --now local-ai-qwen3-tool-proxy.service

for _ in {1..20}; do
  if curl -fsS --max-time 5 http://127.0.0.1:8080/health >/dev/null; then
    break
  fi
  sleep 1
done
curl -fsS --max-time 10 http://127.0.0.1:8080/health >/dev/null
curl -fsS --max-time 10 http://127.0.0.1:8080/v1/models \
  | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data["data"][0]["id"])'

sudo systemctl start local-ai-health.service
grep -Fq 'Result: 0 error(s)' /var/lib/local-ai/health-latest.txt
sudo systemctl reset-failed local-ai-health.service local-ai-qwen3-tool-proxy.service
sudo ufw status verbose | sudo tee "$backup/ufw.after" >/dev/null

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for API compatibility change ${stamp}:
  sudo systemctl disable --now local-ai-qwen3-tool-proxy.service
  sudo install -o root -g root -m 0644 ${backup}/local-ai-qwen3-tool-proxy.service.before ${UNIT_TARGET}
  sudo install -o root -g root -m 0755 ${backup}/local-ai-health-check.before ${HEALTH_TARGET}
  sudo systemctl daemon-reload
  sudo systemctl start local-ai-health.service
EOF
if (( lan_rule_added )); then
  echo "  sudo ufw --force delete allow from ${CONTROLLER_CIDR} to any port 8080 proto tcp" \
    | sudo tee -a "$backup/ROLLBACK.txt" >/dev/null
fi
if (( vpn_rule_added )); then
  echo "  sudo ufw --force delete allow in on tun93 from ${VPN_CIDR} to any port 8080 proto tcp" \
    | sudo tee -a "$backup/ROLLBACK.txt" >/dev/null
fi

echo "API compatibility restored. Backup: $backup"
echo "LAN rule added: $lan_rule_added; VPN rule added: $vpn_rule_added"
echo "Log: $LOG"
