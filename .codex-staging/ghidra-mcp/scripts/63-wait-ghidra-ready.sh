#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly SOURCE="${REPO}/scripts/ai-mode"
readonly TARGET="/usr/local/sbin/ai-mode"
LOG="${REPO}/logs/63-wait-ghidra-ready-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

test -r "$SOURCE"
bash -n "$SOURCE"
grep -Fq 'PyGhidra MCP did not become ready.' "$SOURCE"

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up ai-mode, add a real MCP listener readiness wait, and verify the installed script."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/ai-mode-ghidra-ready-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$TARGET" "$backup/ai-mode.before"
sudo install -o root -g root -m 0755 "$SOURCE" "$TARGET"
bash -n "$TARGET"

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for ai-mode Ghidra readiness wait ${stamp}:
  sudo install -o root -g root -m 0755 ${backup}/ai-mode.before ${TARGET}
EOF

echo "ai-mode now waits for the real PyGhidra listener."
echo "Backup: $backup"
echo "Log: $LOG"
