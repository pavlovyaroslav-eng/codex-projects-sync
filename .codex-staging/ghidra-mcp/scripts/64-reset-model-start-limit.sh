#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly SOURCE="${REPO}/scripts/ai-model"
readonly TARGET="/usr/local/sbin/ai-model"
LOG="${REPO}/logs/64-reset-model-start-limit-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

test -r "$SOURCE"
bash -n "$SOURCE"
grep -Fq 'systemctl reset-failed "${unit}"' "$SOURCE"

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up ai-model, reset only managed AI start limits before a requested start, and verify syntax."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/ai-model-start-limit-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$TARGET" "$backup/ai-model.before"
sudo install -o root -g root -m 0755 "$SOURCE" "$TARGET"
bash -n "$TARGET"

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for ai-model start-limit handling ${stamp}:
  sudo install -o root -g root -m 0755 ${backup}/ai-model.before ${TARGET}
EOF

echo "ai-model now clears managed service start limits before an explicit start."
echo "Backup: $backup"
echo "Log: $LOG"
