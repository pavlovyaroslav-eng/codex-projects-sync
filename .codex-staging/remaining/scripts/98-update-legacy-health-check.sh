#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly SOURCE="$REPO/configs/bin/local-ai-health-check-v2"
readonly TARGET="/usr/local/sbin/local-ai-health-check"
LOG="$REPO/logs/98-update-legacy-health-check-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1
on_error() {
  local rc=$?
  printf 'health-migration: error line=%s rc=%s command=%q\n' \
    "${BASH_LINENO[0]:-unknown}" "$rc" "$BASH_COMMAND" >&2
  exit "$rc"
}
trap on_error ERR

bash -n "$SOURCE"
if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up the legacy health checker, switch it from retired port 8080 to Qwen 8012/MCP 8000, then run the oneshot service."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/ai-station-bootstrap-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$TARGET" "$backup/local-ai-health-check"
sudo sha256sum "$backup/local-ai-health-check" \
  | sudo tee "$backup/local-ai-health-check.sha256" >/dev/null
sudo install -o root -g root -m 0755 "$SOURCE" "$TARGET"
sudo systemctl start local-ai-health.service
sudo systemctl reset-failed local-ai-health.service
if systemctl is-failed --quiet local-ai-health.service; then
  exit 1
fi
grep -Fq 'Result: 0 error(s)' /var/lib/local-ai/health-latest.txt
echo "Legacy health timer migrated successfully. Backup: $backup"
