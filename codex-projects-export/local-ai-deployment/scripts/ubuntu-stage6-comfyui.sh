#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
COMFY_TAG="v0.29.2"
COMFY_COMMIT_PREFIX="3221224"
COMFY_ROOT="/opt/local-ai/apps/ComfyUI-${COMFY_TAG}"
COMFY_CURRENT="/opt/local-ai/apps/ComfyUI-current"
PYTHON="/opt/local-ai/venvs/torch-cu132/bin/python"
TORCHAUDIO_INDEX="https://download.pytorch.org/whl/cpu"
MODEL_DIR="/srv/local-ai/models/comfyui/checkpoints"
MODEL_NAME="sd_xl_base_1.0.safetensors"
MODEL_SIZE="6938078334"
MODEL_SHA256="31e35c80fc4829d14f90153f4c74cd59c90b779f6afe05a74cd6120b893f7e5b"
MODEL_URL="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/${MODEL_NAME}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  /opt/local-ai/apps \
  "${MODEL_DIR}" \
  /srv/local-ai/models/comfyui/vae \
  /srv/local-ai/models/comfyui/loras \
  /srv/local-ai/models/comfyui/controlnet \
  /srv/local-ai/models/comfyui/upscale_models \
  /srv/local-ai/comfyui/user \
  /srv/local-ai/cache/comfyui-temp \
  /srv/local-ai/input/comfyui \
  /srv/local-ai/output/comfyui

if [[ ! -d "${COMFY_ROOT}/.git" ]]; then
  runuser -u "${TARGET_USER}" -- git clone --depth 1 --branch "${COMFY_TAG}" \
    https://github.com/Comfy-Org/ComfyUI.git "${COMFY_ROOT}"
fi
COMFY_COMMIT="$(runuser -u "${TARGET_USER}" -- git -C "${COMFY_ROOT}" rev-parse HEAD)"
if [[ ${COMFY_COMMIT} != ${COMFY_COMMIT_PREFIX}* ]]; then
  echo "Unexpected ComfyUI commit: ${COMFY_COMMIT}" >&2
  exit 1
fi

runuser -u "${TARGET_USER}" -- "${PYTHON}" -m pip install --no-cache-dir \
  -r "${COMFY_ROOT}/requirements.txt"
runuser -u "${TARGET_USER}" -- "${PYTHON}" -m pip install --no-cache-dir \
  --force-reinstall --no-deps "torchaudio==2.11.0+cpu" \
  --index-url "${TORCHAUDIO_INDEX}"
ln -sfn "${COMFY_ROOT}" "${COMFY_CURRENT}"

cat >"${COMFY_ROOT}/extra_model_paths.yaml" <<'EOF'
local_ai:
  base_path: /srv/local-ai/models/comfyui
  checkpoints: checkpoints
  vae: vae
  loras: loras
  controlnet: controlnet
  upscale_models: upscale_models
EOF
chown "${TARGET_USER}:${TARGET_USER}" "${COMFY_ROOT}/extra_model_paths.yaml"

MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"
if [[ -f "${MODEL_PATH}" ]] && \
   echo "${MODEL_SHA256}  ${MODEL_PATH}" | sha256sum --check --status; then
  echo "SDXL model already present and verified."
else
  rm -f "${MODEL_PATH}.part"
  runuser -u "${TARGET_USER}" -- curl -fL --retry 10 --retry-all-errors \
    --output "${MODEL_PATH}.part" "${MODEL_URL}"
  [[ $(stat -c %s "${MODEL_PATH}.part") == "${MODEL_SIZE}" ]]
  echo "${MODEL_SHA256}  ${MODEL_PATH}.part" | sha256sum --check
  mv "${MODEL_PATH}.part" "${MODEL_PATH}"
fi

cat >"${MODEL_DIR}/SDXL-MANIFEST.txt" <<EOF
repository=stabilityai/stable-diffusion-xl-base-1.0
file=${MODEL_NAME}
size_bytes=${MODEL_SIZE}
sha256=${MODEL_SHA256}
source=${MODEL_URL}
license=CreativeML-Open-RAIL++-M
comfyui_tag=${COMFY_TAG}
comfyui_commit=${COMFY_COMMIT}
EOF
chown -R "${TARGET_USER}:${TARGET_USER}" /srv/local-ai/models/comfyui

cat >/etc/systemd/system/local-ai-comfyui.service <<EOF
[Unit]
Description=Local AI ComfyUI
After=network-online.target
Wants=network-online.target
Conflicts=local-ai-llama.service local-ai-open-webui.service

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=${COMFY_CURRENT}
Environment=HOME=/home/${TARGET_USER}
Environment=CUDA_HOME=/usr/local/cuda-13.2
Environment=HF_HOME=/srv/local-ai/cache/huggingface
ExecStart=${PYTHON} ${COMFY_CURRENT}/main.py \\
  --listen 0.0.0.0 \\
  --port 8188 \\
  --disable-auto-launch \\
  --disable-api-nodes \\
  --extra-model-paths-config ${COMFY_ROOT}/extra_model_paths.yaml \\
  --input-directory /srv/local-ai/input/comfyui \\
  --output-directory /srv/local-ai/output/comfyui \\
  --temp-directory /srv/local-ai/cache/comfyui-temp \\
  --user-directory /srv/local-ai/comfyui/user
Restart=on-failure
RestartSec=5
TimeoutStopSec=90
KillSignal=SIGINT
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=read-only
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

cat >/usr/local/sbin/ai-mode <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-status}" in
  llm)
    systemctl stop local-ai-comfyui.service
    systemctl start local-ai-llama.service
    systemctl start local-ai-open-webui.service
    echo "LLM mode: http://192.168.1.65:3000 (API :8080)"
    ;;
  comfy)
    systemctl stop local-ai-open-webui.service local-ai-llama.service
    systemctl start local-ai-comfyui.service
    echo "ComfyUI mode: http://192.168.1.65:8188"
    ;;
  off)
    systemctl stop local-ai-comfyui.service local-ai-open-webui.service local-ai-llama.service
    echo "GPU services stopped"
    ;;
  status)
    systemctl --no-pager --plain --full status \
      local-ai-llama.service local-ai-open-webui.service local-ai-comfyui.service || true
    ;;
  *)
    echo "Usage: sudo ai-mode {llm|comfy|off|status}" >&2
    exit 2
    ;;
esac
EOF
chmod 0755 /usr/local/sbin/ai-mode

ufw allow from "${CONTROLLER_CIDR}" to any port 8188 proto tcp \
  comment "local-ai ComfyUI"
systemctl daemon-reload
systemctl disable local-ai-comfyui.service >/dev/null 2>&1 || true

echo "ComfyUI ${COMFY_TAG} installed. Switch with: sudo ai-mode comfy"
