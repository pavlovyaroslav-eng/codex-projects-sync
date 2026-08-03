#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly MODE_SOURCE="${REPO}/scripts/ai-mode"
readonly MODE_TARGET="/usr/local/sbin/ai-mode"
readonly WHISPER_SOURCE="${REPO}/services/local-ai-whisper.service.d/30-ghidra-port.conf"
readonly WHISPER_TARGET="/etc/systemd/system/local-ai-whisper.service.d/30-ghidra-port.conf"
readonly GHIDRA_SOURCE="${REPO}/services/pyghidra-mcp.service.d/30-whisper-port.conf"
readonly GHIDRA_TARGET="/etc/systemd/system/pyghidra-mcp.service.d/30-whisper-port.conf"
readonly SOCKET_SOURCE="${REPO}/services/local-ai-ghidra-mcp-proxy.socket.d/30-whisper-port.conf"
readonly SOCKET_TARGET="/etc/systemd/system/local-ai-ghidra-mcp-proxy.socket.d/30-whisper-port.conf"
LOG="${REPO}/logs/60-integrate-ghidra-whisper-modes-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

for source in "$MODE_SOURCE" "$WHISPER_SOURCE" "$GHIDRA_SOURCE" "$SOCKET_SOURCE"; do
  test -r "$source"
done
bash -n "$MODE_SOURCE"

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up ai-mode, add mutual Ghidra/Whisper port conflicts, install the mode-aware switcher, and verify systemd units."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/ghidra-whisper-modes-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$MODE_TARGET" "$backup/ai-mode.before"
for target in "$WHISPER_TARGET" "$GHIDRA_TARGET" "$SOCKET_TARGET"; do
  name="$(basename "$(dirname "$target")")-$(basename "$target")"
  if sudo test -e "$target"; then
    sudo cp -a "$target" "$backup/${name}.before"
  else
    sudo touch "$backup/${name}.was-absent"
  fi
done
sudo systemctl cat local-ai-whisper.service pyghidra-mcp.service \
  local-ai-ghidra-mcp-proxy.socket \
  | sudo tee "$backup/systemd.before" >/dev/null

sudo install -o root -g root -m 0755 "$MODE_SOURCE" "$MODE_TARGET"
sudo install -d -o root -g root -m 0755 "$(dirname "$WHISPER_TARGET")" \
  "$(dirname "$GHIDRA_TARGET")" "$(dirname "$SOCKET_TARGET")"
sudo install -o root -g root -m 0644 "$WHISPER_SOURCE" "$WHISPER_TARGET"
sudo install -o root -g root -m 0644 "$GHIDRA_SOURCE" "$GHIDRA_TARGET"
sudo install -o root -g root -m 0644 "$SOCKET_SOURCE" "$SOCKET_TARGET"
sudo systemctl daemon-reload
sudo systemd-analyze --no-pager verify local-ai-whisper.service \
  pyghidra-mcp.service local-ai-ghidra-mcp-proxy.socket
bash -n "$MODE_TARGET"
systemctl show local-ai-whisper.service -p Conflicts --value | grep -Fq pyghidra-mcp.service
systemctl show pyghidra-mcp.service -p Conflicts --value | grep -Fq local-ai-whisper.service
systemctl show local-ai-ghidra-mcp-proxy.socket -p Conflicts --value | grep -Fq local-ai-whisper.service

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for Ghidra/Whisper mode integration ${stamp}:
  sudo install -o root -g root -m 0755 ${backup}/ai-mode.before ${MODE_TARGET}
  sudo rm -f ${WHISPER_TARGET} ${GHIDRA_TARGET} ${SOCKET_TARGET}
  sudo systemctl daemon-reload
EOF

echo "Ghidra and Whisper port ownership is integrated into ai-mode."
echo "Backup: $backup"
echo "Log: $LOG"
