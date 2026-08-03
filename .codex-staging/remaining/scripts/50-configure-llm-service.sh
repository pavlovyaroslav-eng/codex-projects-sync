#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly UNIT_SRC="$REPO/services/qwen3-coder.service"
readonly UNIT_DST="/etc/systemd/system/qwen3-coder.service"
readonly BACKUP_ROOT="/srv/local-ai/backups"
readonly LOG_DIR="$REPO/logs"
mkdir -p "$LOG_DIR"
readonly LOG_FILE="$LOG_DIR/50-configure-llm-service-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: validate and install qwen3-coder.service, then enable localhost API on 127.0.0.1:8012."
  exit 0
fi

test -x /opt/ai-stack/bin/llama-server
id qwenllm >/dev/null
sudo -u qwenllm test -r /srv/ai/models/qwen3-coder-30b-a3b/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
systemd-analyze verify "$UNIT_SRC"

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="$BACKUP_ROOT/ai-station-bootstrap-${stamp}/pre-qwen-service.tar.gz"
sudo install -d -o root -g root -m 0700 "$(dirname "$backup")"
paths=()
for path in /etc/systemd/system/qwen3-coder.service /etc/systemd/system/local-ai-llama.service /etc/systemd/system/local-ai-autostart.service; do
  [[ -e "$path" || -L "$path" ]] && paths+=("${path#/}")
done
if ((${#paths[@]})); then
  sudo tar -C / -czf "$backup" "${paths[@]}"
else
  printf 'No pre-existing unit files\n' | sudo tee "${backup}.empty" >/dev/null
fi

sudo install -o root -g root -m 0644 "$UNIT_SRC" "$UNIT_DST"
sudo install -o root -g root -m 0755 "$REPO"/configs/bin/ai-model-* /usr/local/bin/
sudo systemctl daemon-reload
for legacy_unit in local-ai-autostart.service local-ai-llama.service; do
  if systemctl cat "$legacy_unit" >/dev/null 2>&1; then
    sudo systemctl disable --now "$legacy_unit"
  fi
done
sudo systemctl enable --now qwen3-coder.service

for _ in {1..60}; do
  if curl -fsS http://127.0.0.1:8012/health >/dev/null; then
    break
  fi
  sleep 2
done
curl -fsS http://127.0.0.1:8012/health >/dev/null
systemctl is-active --quiet qwen3-coder.service
ss -ltnH 'sport = :8012' | grep -F '127.0.0.1:8012'
if ss -ltnH 'sport = :8012' | grep -Fq '0.0.0.0:8012'; then
  echo "Unsafe wildcard API bind detected" >&2
  exit 1
fi
echo "Backup: $backup"
echo "qwen3-coder.service is active on localhost only."
