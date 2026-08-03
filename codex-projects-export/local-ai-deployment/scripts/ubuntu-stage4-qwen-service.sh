#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
MODEL_REPO="ggml-org/Qwen3-14B-GGUF"
MODEL_NAME="Qwen3-14B-Q4_K_M.gguf"
MODEL_SHA256="5ff1fe7a07aebc8d090682d01b17cf268a1b4680c6477050ce75a600aecb9efb"
MODEL_SIZE="9001753376"
MODEL_DIR="/srv/local-ai/models/llm/qwen3-14b-q4km"
MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"
MODEL_URL="https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_NAME}"
LLAMA_BIN="/opt/local-ai/apps/llama.cpp-current/bin/llama-server"
SERVICE_FILE="/etc/systemd/system/local-ai-llama.service"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 "${MODEL_DIR}"

if [[ -f "${MODEL_PATH}" ]] && \
   echo "${MODEL_SHA256}  ${MODEL_PATH}" | sha256sum --check --status; then
  echo "Model already present and verified."
else
  rm -f "${MODEL_PATH}.part"
  runuser -u "${TARGET_USER}" -- curl -fL --retry 10 --retry-all-errors \
    --output "${MODEL_PATH}.part" "${MODEL_URL}"
  actual_size="$(stat -c %s "${MODEL_PATH}.part")"
  if [[ ${actual_size} != "${MODEL_SIZE}" ]]; then
    echo "Unexpected model size: ${actual_size}; expected ${MODEL_SIZE}." >&2
    exit 1
  fi
  echo "${MODEL_SHA256}  ${MODEL_PATH}.part" | sha256sum --check
  mv "${MODEL_PATH}.part" "${MODEL_PATH}"
fi

cat >"${MODEL_DIR}/MODEL-MANIFEST.txt" <<EOF
repository=${MODEL_REPO}
file=${MODEL_NAME}
size_bytes=${MODEL_SIZE}
sha256=${MODEL_SHA256}
source=${MODEL_URL}
base_model=Qwen/Qwen3-14B
license=Apache-2.0
EOF
chown -R "${TARGET_USER}:${TARGET_USER}" "${MODEL_DIR}"

cat >"${SERVICE_FILE}" <<EOF
[Unit]
Description=Local AI llama.cpp server (Qwen3-14B Q4_K_M)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=/srv/local-ai
Environment=HOME=/home/${TARGET_USER}
Environment=CUDA_HOME=/usr/local/cuda-13.2
Environment=LD_LIBRARY_PATH=/opt/local-ai/apps/llama.cpp-current/lib:/usr/local/cuda-13.2/lib64
ExecStart=${LLAMA_BIN} \\
  --model ${MODEL_PATH} \\
  --alias qwen3-14b-q4km \\
  --host 0.0.0.0 \\
  --port 8080 \\
  --ctx-size 8192 \\
  --n-gpu-layers 99 \\
  --threads 28 \\
  --threads-batch 28 \\
  --parallel 1 \\
  --batch-size 1024 \\
  --ubatch-size 256 \\
  --flash-attn on \\
  --cache-type-k q8_0 \\
  --cache-type-v q8_0 \\
  --jinja \\
  --metrics
Restart=on-failure
RestartSec=5
TimeoutStopSec=90
KillSignal=SIGINT
LimitNOFILE=1048576
LimitMEMLOCK=infinity
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
EOF

ufw allow from "${CONTROLLER_CIDR}" to any port 8080 proto tcp \
  comment "local-ai llama API"
systemctl daemon-reload
systemctl enable --now local-ai-llama.service

for _ in $(seq 1 90); do
  if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
    break
  fi
  sleep 2
done
curl -fsS http://127.0.0.1:8080/health
echo
curl -fsS http://127.0.0.1:8080/v1/models
echo
echo "Qwen service ready: http://192.168.1.65:8080"
