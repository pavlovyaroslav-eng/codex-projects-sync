#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV="/opt/local-ai/venvs/whisper"
APP_ROOT="/opt/local-ai/apps/whisper-api"
MODEL_ROOT="/srv/local-ai/models/whisper"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  /opt/local-ai/venvs "${APP_ROOT}" "${MODEL_ROOT}" \
  /srv/local-ai/input/whisper /srv/local-ai/output/whisper /srv/local-ai/cache/huggingface

if [[ ! -x "${VENV}/bin/python" ]]; then
  runuser -u "${TARGET_USER}" -- python3 -m venv "${VENV}"
fi
runuser -u "${TARGET_USER}" -- "${VENV}/bin/python" -m pip install --upgrade pip setuptools wheel
runuser -u "${TARGET_USER}" -- "${VENV}/bin/python" -m pip install --no-cache-dir \
  "faster-whisper==1.2.1" \
  "nvidia-cublas-cu12" \
  "nvidia-cudnn-cu12==9.*" \
  "fastapi==0.116.1" \
  "uvicorn[standard]==0.35.0" \
  "python-multipart==0.0.20" \
  "requests==2.32.4"

install -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0644 \
  "${SCRIPT_DIR}/whisper_api.py" "${APP_ROOT}/whisper_api.py"
install -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  "${SCRIPT_DIR}/whisper_client.py" "${APP_ROOT}/whisper_client.py"

LIB_PATH="$(runuser -u "${TARGET_USER}" -- "${VENV}/bin/python" -c \
  'import nvidia.cublas.lib, nvidia.cudnn.lib; print(next(iter(nvidia.cublas.lib.__path__)) + ":" + next(iter(nvidia.cudnn.lib.__path__)))')"

runuser -u "${TARGET_USER}" -- env \
  LD_LIBRARY_PATH="${LIB_PATH}" \
  HF_HOME=/srv/local-ai/cache/huggingface \
  "${VENV}/bin/python" -c \
  'from faster_whisper import WhisperModel; WhisperModel("turbo", device="cpu", compute_type="int8", download_root="/srv/local-ai/models/whisper"); print("Whisper turbo cached")'

cat >/etc/systemd/system/local-ai-whisper.service <<EOF
[Unit]
Description=Local AI faster-whisper API
After=network-online.target
Wants=network-online.target
Conflicts=local-ai-llama.service local-ai-open-webui.service local-ai-comfyui.service
StartLimitIntervalSec=300
StartLimitBurst=3

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=${APP_ROOT}
Environment=PYTHONUNBUFFERED=1
Environment=LD_LIBRARY_PATH=${LIB_PATH}
Environment=HF_HOME=/srv/local-ai/cache/huggingface
Environment=WHISPER_MODEL=turbo
Environment=WHISPER_COMPUTE_TYPE=int8_float16
Environment=WHISPER_MODEL_ROOT=${MODEL_ROOT}
Environment=WHISPER_INPUT_ROOT=/srv/local-ai/input/whisper
Environment=WHISPER_MAX_UPLOAD_BYTES=536870912
ExecStart=${VENV}/bin/uvicorn whisper_api:app --host 0.0.0.0 --port 8000 --workers 1
Restart=on-failure
RestartSec=5
TimeoutStopSec=60
KillSignal=SIGINT
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=read-only
ReadWritePaths=/srv/local-ai
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

cat >/usr/local/sbin/ai-mode <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-status}" in
  llm)
    systemctl stop local-ai-comfyui.service local-ai-whisper.service
    systemctl start local-ai-llama.service local-ai-open-webui.service
    echo "LLM mode: http://192.168.1.65:3000 (API :8080)"
    ;;
  comfy|image)
    systemctl stop local-ai-open-webui.service local-ai-llama.service local-ai-whisper.service
    systemctl start local-ai-comfyui.service
    echo "ComfyUI mode: http://192.168.1.65:8188"
    ;;
  whisper|speech)
    systemctl stop local-ai-open-webui.service local-ai-llama.service local-ai-comfyui.service
    systemctl start local-ai-whisper.service
    echo "Whisper mode: http://192.168.1.65:8000"
    ;;
  off)
    systemctl stop local-ai-comfyui.service local-ai-open-webui.service local-ai-llama.service local-ai-whisper.service
    echo "GPU services stopped"
    ;;
  status)
    systemctl --no-pager --plain --full status \
      local-ai-llama.service local-ai-open-webui.service local-ai-comfyui.service local-ai-whisper.service || true
    ;;
  *)
    echo "Usage: sudo ai-mode {llm|comfy|image|whisper|speech|off|status}" >&2
    exit 2
    ;;
esac
EOF
chmod 0755 /usr/local/sbin/ai-mode

cat >/usr/local/bin/ai-transcribe <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
sudo /usr/local/sbin/ai-mode whisper >/dev/null
trap 'sudo /usr/local/sbin/ai-mode llm >/dev/null' EXIT
for _ in {1..60}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null; then
    break
  fi
  sleep 2
done
"${VENV}/bin/python" "${APP_ROOT}/whisper_client.py" "\$@"
EOF
chmod 0755 /usr/local/bin/ai-transcribe

ufw allow from "${CONTROLLER_CIDR}" to any port 8000 proto tcp comment "local-ai Whisper API"
systemctl daemon-reload
systemctl disable local-ai-whisper.service >/dev/null 2>&1 || true

echo "Whisper installed. Mode: sudo ai-mode whisper; CLI: ai-transcribe FILE"
