#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly MODEL_SOURCE="${REPO}/scripts/ai-model"
readonly MODEL_TARGET="/usr/local/sbin/ai-model"
readonly MODE_SOURCE="${REPO}/scripts/ai-mode"
readonly MODE_TARGET="/usr/local/sbin/ai-mode"
readonly WEBUI_SOURCE="${REPO}/services/local-ai-open-webui.service.d/30-qwen3-api.conf"
readonly WEBUI_TARGET="/etc/systemd/system/local-ai-open-webui.service.d/30-qwen3-api.conf"
readonly QWEN_SOURCE="${REPO}/services/qwen3-coder.service.d/30-gpu-conflicts.conf"
readonly QWEN_TARGET="/etc/systemd/system/qwen3-coder.service.d/30-gpu-conflicts.conf"
readonly LEGACY_DROPIN="/etc/systemd/system/local-ai-coder30.service.d/30-tool-proxy.conf"
LOG="${REPO}/logs/62-fix-model-mode-manager-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG
exec > >(tee -a "$LOG") 2>&1

for source in "$MODEL_SOURCE" "$MODE_SOURCE" "$WEBUI_SOURCE" "$QWEN_SOURCE"; do
  test -r "$source"
done
bash -n "$MODEL_SOURCE"
bash -n "$MODE_SOURCE"

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up and repair ai-model/ai-mode for qwen3-coder, remove the contradictory legacy dependency, and verify systemd."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/srv/local-ai/backups/model-mode-manager-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$MODEL_TARGET" "$backup/ai-model.before"
sudo cp -a "$MODE_TARGET" "$backup/ai-mode.before"
sudo cp -a "$WEBUI_TARGET" "$backup/30-qwen3-api.conf.before"
sudo cp -a /etc/local-ai/active-model "$backup/active-model.before"
if sudo test -e "$QWEN_TARGET"; then
  sudo cp -a "$QWEN_TARGET" "$backup/30-gpu-conflicts.conf.before"
else
  sudo touch "$backup/30-gpu-conflicts.conf.was-absent"
fi
if sudo test -e "$LEGACY_DROPIN"; then
  sudo cp -a "$LEGACY_DROPIN" "$backup/30-tool-proxy.conf.before"
else
  sudo touch "$backup/30-tool-proxy.conf.was-absent"
fi

sudo install -o root -g root -m 0755 "$MODEL_SOURCE" "$MODEL_TARGET"
sudo install -o root -g root -m 0755 "$MODE_SOURCE" "$MODE_TARGET"
sudo install -o root -g root -m 0644 "$WEBUI_SOURCE" "$WEBUI_TARGET"
sudo install -d -o root -g root -m 0755 "$(dirname "$QWEN_TARGET")"
sudo install -o root -g root -m 0644 "$QWEN_SOURCE" "$QWEN_TARGET"
sudo rm -f "$LEGACY_DROPIN"
printf '%s\n' coder30 | sudo tee /etc/local-ai/active-model >/dev/null
sudo systemctl daemon-reload
sudo systemd-analyze --no-pager verify qwen3-coder.service \
  local-ai-qwen3-tool-proxy.service local-ai-open-webui.service \
  local-ai-coder30.service local-ai-whisper.service
bash -n "$MODEL_TARGET"
bash -n "$MODE_TARGET"
! systemctl show local-ai-open-webui.service -p Wants --value | grep -Fq local-ai-qwen3-tool-proxy.service
systemctl show qwen3-coder.service -p Conflicts --value | grep -Fq local-ai-whisper.service

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for model/mode manager ${stamp}:
  sudo install -o root -g root -m 0755 ${backup}/ai-model.before ${MODEL_TARGET}
  sudo install -o root -g root -m 0755 ${backup}/ai-mode.before ${MODE_TARGET}
  sudo install -o root -g root -m 0644 ${backup}/30-qwen3-api.conf.before ${WEBUI_TARGET}
  sudo install -o root -g root -m 0644 ${backup}/active-model.before /etc/local-ai/active-model
  sudo rm -f ${QWEN_TARGET}
  if test -f ${backup}/30-tool-proxy.conf.before; then sudo install -o root -g root -m 0644 ${backup}/30-tool-proxy.conf.before ${LEGACY_DROPIN}; fi
  sudo systemctl daemon-reload
EOF

echo "Model and mode managers now control qwen3-coder correctly."
echo "Backup: $backup"
echo "Log: $LOG"
