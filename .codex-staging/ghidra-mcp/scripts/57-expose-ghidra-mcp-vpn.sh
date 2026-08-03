#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly SOCKET_SOURCE="${REPO}/services/local-ai-ghidra-mcp-proxy.socket"
readonly SERVICE_SOURCE="${REPO}/services/local-ai-ghidra-mcp-proxy.service"
readonly SOCKET_TARGET="/etc/systemd/system/local-ai-ghidra-mcp-proxy.socket"
readonly SERVICE_TARGET="/etc/systemd/system/local-ai-ghidra-mcp-proxy.service"
LOG="${REPO}/logs/57-expose-ghidra-mcp-vpn-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

on_error() {
  local rc=$?
  printf 'ghidra-mcp-vpn: error line=%s rc=%s command=%q\n' \
    "${BASH_LINENO[0]:-unknown}" "$rc" "$BASH_COMMAND" >&2
  exit "$rc"
}
trap on_error ERR

test -x /lib/systemd/systemd-socket-proxyd
test -r "$SOCKET_SOURCE"
test -r "$SERVICE_SOURCE"
systemd-analyze --no-pager verify "$SOCKET_SOURCE" "$SERVICE_SOURCE"
systemctl is-active --quiet pyghidra-mcp.service
ip -4 addr show dev tun93 | grep -Fq '10.93.0.10/24'

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: expose PyGhidra MCP only on VPN address 10.93.0.10:8000 through systemd-socket-proxyd, retain the loopback backend, preserve UFW scope, and create an exact rollback."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/ghidra-mcp-vpn-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
for target in "$SOCKET_TARGET" "$SERVICE_TARGET"; do
  name="$(basename "$target")"
  if sudo test -e "$target"; then
    sudo cp -a "$target" "$backup/${name}.before"
  else
    sudo touch "$backup/${name}.was-absent"
  fi
done
sudo ufw status verbose | sudo tee "$backup/ufw.before" >/dev/null
ufw_status="$(sudo ufw status)"
grep -E '8000/tcp on tun93.*10\.93\.0\.0/24' <<<"$ufw_status" >/dev/null

sudo install -o root -g root -m 0644 "$SOCKET_SOURCE" "$SOCKET_TARGET"
sudo install -o root -g root -m 0644 "$SERVICE_SOURCE" "$SERVICE_TARGET"
sudo systemctl daemon-reload
sudo systemctl enable --now local-ai-ghidra-mcp-proxy.socket
systemctl is-active --quiet local-ai-ghidra-mcp-proxy.socket
systemctl is-enabled --quiet local-ai-ghidra-mcp-proxy.socket
ss -ltnH 'sport = :8000' | grep -Fq '10.93.0.10:8000'
sudo ufw status verbose | sudo tee "$backup/ufw.after" >/dev/null

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for VPN PyGhidra MCP publication ${stamp}:
  sudo systemctl disable --now local-ai-ghidra-mcp-proxy.socket
  sudo rm -f ${SOCKET_TARGET} ${SERVICE_TARGET}
  sudo systemctl daemon-reload
  sudo systemctl reset-failed local-ai-ghidra-mcp-proxy.service
EOF

echo "PyGhidra MCP VPN endpoint ready: http://10.93.0.10:8000/mcp"
echo "UFW unchanged; existing tun93 source rule reused."
echo "Backup: $backup"
