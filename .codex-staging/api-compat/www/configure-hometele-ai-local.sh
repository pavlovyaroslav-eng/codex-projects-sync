#!/usr/bin/env bash
set -Eeuo pipefail

readonly SOURCE_ROOT="/home/suazzzi/hometele-ai-local-stage"
readonly CODE_SOURCE="${SOURCE_ROOT}/hometele-ai.py"
readonly UNIT_SOURCE="${SOURCE_ROOT}/hometele-ai.service"
readonly CODE_TARGET="/opt/hometele-ai/hometele-ai.py"
readonly UNIT_TARGET="/etc/systemd/system/hometele-ai.service"
readonly CONFIG_TARGET="/etc/hometele-ai.conf"
readonly API_BASE="http://10.93.0.10:8080/v1"
readonly MODEL="qwen3-coder-30b-a3b-q4km"
validation_since="$(date --iso-8601=seconds)"

python3 -m py_compile "$CODE_SOURCE"
systemd-analyze --no-pager verify "$UNIT_SOURCE"
curl -fsS --max-time 10 "${API_BASE%/v1}/health" >/dev/null
curl -fsS --max-time 10 "${API_BASE}/models" \
  | python3 -c 'import json,sys; assert json.load(sys.stdin)["data"][0]["id"] == "qwen3-coder-30b-a3b-q4km"'

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: back up the Matrix AI bot, point !ai at the local Qwen API over tun93, prevent replay of stale messages, and enable the service."
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/var/backups/hometele-ai-local-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup"
sudo cp -a "$CODE_TARGET" "$backup/hometele-ai.py.before"
sudo cp -a "$UNIT_TARGET" "$backup/hometele-ai.service.before"
sudo cp -a "$CONFIG_TARGET" "$backup/hometele-ai.conf.before"
sudo sha256sum \
  "$backup/hometele-ai.py.before" \
  "$backup/hometele-ai.service.before" \
  "$backup/hometele-ai.conf.before" \
  | sudo tee "$backup/SHA256SUMS" >/dev/null
sudo systemctl is-active hometele-ai.service \
  | sudo tee "$backup/service-active.before" >/dev/null || true
sudo systemctl is-enabled hometele-ai.service \
  | sudo tee "$backup/service-enabled.before" >/dev/null || true
sudo diff -u --label hometele-ai.py.before --label hometele-ai.py.after \
  "$backup/hometele-ai.py.before" "$CODE_SOURCE" \
  | sudo tee "$backup/hometele-ai.py.diff" >/dev/null || true
sudo diff -u --label hometele-ai.service.before --label hometele-ai.service.after \
  "$backup/hometele-ai.service.before" "$UNIT_SOURCE" \
  | sudo tee "$backup/hometele-ai.service.diff" >/dev/null || true

sudo install -o root -g root -m 0755 "$CODE_SOURCE" "$CODE_TARGET"
sudo install -o root -g root -m 0644 "$UNIT_SOURCE" "$UNIT_TARGET"

if sudo grep -q '^LOCAL_AI_BASE_URL=' "$CONFIG_TARGET"; then
  sudo sed -i "s|^LOCAL_AI_BASE_URL=.*|LOCAL_AI_BASE_URL=${API_BASE}|" "$CONFIG_TARGET"
else
  printf '\nLOCAL_AI_BASE_URL=%s\n' "$API_BASE" | sudo tee -a "$CONFIG_TARGET" >/dev/null
fi
if sudo grep -q '^LOCAL_AI_MODEL=' "$CONFIG_TARGET"; then
  sudo sed -i "s|^LOCAL_AI_MODEL=.*|LOCAL_AI_MODEL=${MODEL}|" "$CONFIG_TARGET"
else
  printf 'LOCAL_AI_MODEL=%s\n' "$MODEL" | sudo tee -a "$CONFIG_TARGET" >/dev/null
fi
sudo chmod 0600 "$CONFIG_TARGET"
sudo chown root:root "$CONFIG_TARGET"

sudo systemctl daemon-reload
sudo systemctl enable --now hometele-ai.service
for _ in {1..20}; do
  if systemctl is-active --quiet hometele-ai.service; then
    break
  fi
  sleep 1
done
systemctl is-active --quiet hometele-ai.service
systemctl is-enabled --quiet hometele-ai.service
sleep 2
if journalctl -u hometele-ai.service --since "$validation_since" --no-pager -o cat \
  | grep -Eq 'Traceback|Loop error|Login.*failed'; then
  journalctl -u hometele-ai.service -n 30 --no-pager -o cat >&2
  exit 1
fi

sudo tee "$backup/ROLLBACK.txt" >/dev/null <<EOF
Rollback for Matrix local-AI switch ${stamp}:
  sudo systemctl disable --now hometele-ai.service
  sudo install -o root -g root -m 0755 ${backup}/hometele-ai.py.before ${CODE_TARGET}
  sudo install -o root -g root -m 0644 ${backup}/hometele-ai.service.before ${UNIT_TARGET}
  sudo install -o root -g root -m 0600 ${backup}/hometele-ai.conf.before ${CONFIG_TARGET}
  sudo systemctl daemon-reload
EOF

echo "Matrix AI now uses ${API_BASE} model ${MODEL}."
echo "Backup: $backup"
