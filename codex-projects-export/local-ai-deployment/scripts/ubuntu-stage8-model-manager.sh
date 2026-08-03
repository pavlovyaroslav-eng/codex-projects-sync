#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
MODEL_ROOT="/srv/local-ai/models/llm"
LLAMA="/opt/local-ai/apps/llama.cpp-current/bin/llama-server"

CODER_DIR="${MODEL_ROOT}/qwen3-coder-30b-a3b-q4km"
CODER_FILE="Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
CODER_SIZE="18632186176"
CODER_SHA="79ad15a5ee3caddc3f4ff0db33a14454a5a3eb503d7fa1c1e35feafc579de486"
CODER_URL="https://huggingface.co/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/${CODER_FILE}"

VL_DIR="${MODEL_ROOT}/qwen3-vl-8b-q4km"
VL_FILE="Qwen3VL-8B-Instruct-Q4_K_M.gguf"
VL_SIZE="5027784800"
VL_SHA="67d1659bfe71b89d50b45a4ad1a9e5b997e5bb16ce5da66a6a6167abd569e9e2"
VL_URL="https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/${VL_FILE}"
MMPROJ_FILE="mmproj-Qwen3VL-8B-Instruct-Q8_0.gguf"
MMPROJ_SIZE="752289728"
MMPROJ_SHA="c6ba85508d82f42590e6eb77d5340369ab6fecf107a7561d809523d8aa5f3bfd"
MMPROJ_URL="https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/${MMPROJ_FILE}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

if ! command -v aria2c >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y aria2
fi

download_verified() {
  local url="$1" path="$2" size="$3" sha="$4"
  install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 "$(dirname -- "${path}")"
  if [[ -f "${path}" ]] && [[ $(stat -c %s "${path}") == "${size}" ]] && \
     echo "${sha}  ${path}" | sha256sum --check --status; then
    echo "Already verified: ${path}"
    return
  fi
  if ! runuser -u "${TARGET_USER}" -- aria2c \
    --continue=true --allow-overwrite=true --auto-file-renaming=false \
    --max-connection-per-server=8 --split=8 --min-split-size=64M \
    --file-allocation=none --summary-interval=30 \
    --dir="$(dirname -- "${path}")" --out="$(basename -- "${path}").part" "${url}"; then
    # Hugging Face Xet occasionally signs each byte range separately and rejects
    # aria2 parallel ranges with HTTP 403. Discard only that incomplete payload
    # and retry the same verified source as a single stream.
    rm -f -- "${path}.part" "${path}.part.aria2"
    runuser -u "${TARGET_USER}" -- curl -fL --retry 10 --retry-all-errors \
      -o "${path}.part" "${url}"
  fi
  [[ $(stat -c %s "${path}.part") == "${size}" ]]
  echo "${sha}  ${path}.part" | sha256sum --check
  mv -f "${path}.part" "${path}"
}

download_verified "${CODER_URL}" "${CODER_DIR}/${CODER_FILE}" "${CODER_SIZE}" "${CODER_SHA}"
download_verified "${VL_URL}" "${VL_DIR}/${VL_FILE}" "${VL_SIZE}" "${VL_SHA}"
download_verified "${MMPROJ_URL}" "${VL_DIR}/${MMPROJ_FILE}" "${MMPROJ_SIZE}" "${MMPROJ_SHA}"

cat >"${CODER_DIR}/manifest.json" <<EOF
{"base_model":"Qwen/Qwen3-Coder-30B-A3B-Instruct","quantizer":"lmstudio-community (bartowski)","quantization":"Q4_K_M","license":"Apache-2.0","size":${CODER_SIZE},"sha256":"${CODER_SHA}","source":"${CODER_URL}"}
EOF
cat >"${VL_DIR}/manifest.json" <<EOF
{"base_model":"Qwen/Qwen3-VL-8B-Instruct","publisher":"Qwen","quantization":"Q4_K_M + Q8_0 mmproj","license":"Apache-2.0","model_size":${VL_SIZE},"model_sha256":"${VL_SHA}","mmproj_size":${MMPROJ_SIZE},"mmproj_sha256":"${MMPROJ_SHA}","source":"https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF"}
EOF
chown "${TARGET_USER}:${TARGET_USER}" "${CODER_DIR}/manifest.json" "${VL_DIR}/manifest.json"

cat >/etc/systemd/system/local-ai-llama.service <<EOF
[Unit]
Description=Local AI llama.cpp server (Qwen3-14B Q4_K_M)
After=network-online.target
Wants=network-online.target
Conflicts=local-ai-coder30.service local-ai-qwen-vl.service local-ai-comfyui.service local-ai-whisper.service
StartLimitIntervalSec=300
StartLimitBurst=3

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=/srv/local-ai
Environment=HOME=/home/${TARGET_USER}
Environment=CUDA_HOME=/usr/local/cuda-13.2
Environment=LD_LIBRARY_PATH=/opt/local-ai/apps/llama.cpp-current/lib:/usr/local/cuda-13.2/lib64
ExecStart=${LLAMA} --model /srv/local-ai/models/llm/qwen3-14b-q4km/Qwen3-14B-Q4_K_M.gguf --alias qwen3-14b-q4km --host 0.0.0.0 --port 8080 --ctx-size 8192 --n-gpu-layers 99 --threads 28 --threads-batch 28 --parallel 1 --batch-size 1024 --ubatch-size 256 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --jinja --metrics
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

cat >/usr/local/sbin/local-ai-coder30-start <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

available_kib="$(awk '$1 == "MemAvailable:" { print $2 }' /proc/meminfo)"

listen_host=0.0.0.0
listen_port=8080
if [[ -x /opt/local-ai/apps/qwen3-coder-tool-proxy.py ]] && \
   [[ -f /etc/systemd/system/local-ai-qwen3-tool-proxy.service ]]; then
  listen_host=127.0.0.1
  listen_port=8082
fi

if (( available_kib >= 36 * 1024 * 1024 )); then
  context_size=32768
elif (( available_kib >= 24 * 1024 * 1024 )); then
  context_size=24576
elif (( available_kib >= 16 * 1024 * 1024 )); then
  context_size=16384
else
  context_size=8192
fi

printf 'auto-context: selected %s tokens (MemAvailable=%s KiB, KV cache in system RAM)\n' \
  "${context_size}" "${available_kib}" >&2

exec /opt/local-ai/apps/llama.cpp-current/bin/llama-server \
  --model /srv/local-ai/models/llm/qwen3-coder-30b-a3b-q4km/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf \
  --alias qwen3-coder-30b-a3b-q4km \
  --host "${listen_host}" \
  --port "${listen_port}" \
  --ctx-size "${context_size}" \
  --n-gpu-layers 99 \
  --n-cpu-moe 32 \
  --numa distribute \
  --threads 28 \
  --threads-batch 28 \
  --parallel 1 \
  --batch-size 512 \
  --ubatch-size 128 \
  --flash-attn on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --no-kv-offload \
  --temp 0.2 \
  --jinja \
  --metrics
EOF
chmod 0755 /usr/local/sbin/local-ai-coder30-start

cat >/etc/systemd/system/local-ai-coder30.service <<EOF
[Unit]
Description=Local AI llama.cpp server (Qwen3-Coder-30B-A3B Q4_K_M)
After=network-online.target
Wants=network-online.target
Conflicts=local-ai-llama.service local-ai-qwen-vl.service local-ai-comfyui.service local-ai-whisper.service
StartLimitIntervalSec=300
StartLimitBurst=3

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=/srv/local-ai
Environment=HOME=/home/${TARGET_USER}
Environment=CUDA_HOME=/usr/local/cuda-13.2
Environment=LD_LIBRARY_PATH=/opt/local-ai/apps/llama.cpp-current/lib:/usr/local/cuda-13.2/lib64
ExecStart=/usr/local/sbin/local-ai-coder30-start
Restart=on-failure
RestartSec=5
TimeoutStopSec=120
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

cat >/etc/systemd/system/local-ai-qwen-vl.service <<EOF
[Unit]
Description=Local AI llama.cpp server (Qwen3-VL-8B Q4_K_M)
After=network-online.target
Wants=network-online.target
Conflicts=local-ai-llama.service local-ai-coder30.service local-ai-comfyui.service local-ai-whisper.service
StartLimitIntervalSec=300
StartLimitBurst=3

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=/srv/local-ai
Environment=HOME=/home/${TARGET_USER}
Environment=CUDA_HOME=/usr/local/cuda-13.2
Environment=LD_LIBRARY_PATH=/opt/local-ai/apps/llama.cpp-current/lib:/usr/local/cuda-13.2/lib64
ExecStart=${LLAMA} --model ${VL_DIR}/${VL_FILE} --mmproj ${VL_DIR}/${MMPROJ_FILE} --alias qwen3-vl-8b-q4km --host 0.0.0.0 --port 8080 --ctx-size 8192 --n-gpu-layers 99 --threads 28 --threads-batch 28 --parallel 1 --batch-size 512 --ubatch-size 128 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --jinja --metrics
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

mkdir -p /etc/systemd/system/local-ai-comfyui.service.d /etc/systemd/system/local-ai-whisper.service.d
cat >/etc/systemd/system/local-ai-comfyui.service.d/20-model-conflicts.conf <<'EOF'
[Unit]
Conflicts=local-ai-coder30.service local-ai-qwen-vl.service
EOF
cat >/etc/systemd/system/local-ai-whisper.service.d/20-model-conflicts.conf <<'EOF'
[Unit]
Conflicts=local-ai-coder30.service local-ai-qwen-vl.service
EOF

mkdir -p /etc/systemd/system/local-ai-open-webui.service.d
# Remove the legacy hard dependency created before multiple LLM profiles existed.
sed -i '/^Requires=local-ai-llama\.service$/d; s/^After=network-online\.target local-ai-llama\.service$/After=network-online.target/' \
  /etc/systemd/system/local-ai-open-webui.service
cat >/etc/systemd/system/local-ai-open-webui.service.d/20-model-manager.conf <<'EOF'
[Unit]
After=network-online.target
Wants=network-online.target
EOF

install -d -m 0755 /etc/local-ai
[[ -f /etc/local-ai/active-model ]] || echo qwen14 >/etc/local-ai/active-model

cat >/usr/local/sbin/ai-model <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

active_file=/etc/local-ai/active-model

service_for() {
  case "$1" in
    qwen14) echo local-ai-llama.service ;;
    coder30) echo local-ai-coder30.service ;;
    qwen-vl|vl) echo local-ai-qwen-vl.service ;;
    *) return 2 ;;
  esac
}

stop_gpu() {
  systemctl stop local-ai-open-webui.service local-ai-llama.service \
    local-ai-coder30.service local-ai-qwen-vl.service \
    local-ai-comfyui.service local-ai-whisper.service
}

wait_gpu_free() {
  local used
  for _ in {1..60}; do
    used="$(nvidia-smi --query-compute-apps=used_memory --format=csv,noheader,nounits 2>/dev/null | awk '{s+=$1} END {print s+0}')"
    if (( used < 768 )); then return 0; fi
    sleep 1
  done
  echo "GPU memory did not become free in time." >&2
  return 1
}

wait_api() {
  local unit="$1"
  for _ in {1..180}; do
    if curl -fsS http://127.0.0.1:8080/health >/dev/null 2>&1; then return 0; fi
    if ! systemctl is-active --quiet "${unit}"; then
      journalctl -u "${unit}" -n 40 --no-pager >&2
      return 1
    fi
    sleep 2
  done
  echo "Model API did not become ready." >&2
  return 1
}

wait_webui() {
  for _ in {1..90}; do
    if curl -fsS http://127.0.0.1:3000/health >/dev/null 2>&1; then return 0; fi
    if ! systemctl is-active --quiet local-ai-open-webui.service; then
      journalctl -u local-ai-open-webui.service -n 40 --no-pager >&2
      return 1
    fi
    sleep 2
  done
  echo "Open WebUI did not become ready." >&2
  return 1
}

case "${1:-status}" in
  start)
    model="${2:-qwen14}"
    unit="$(service_for "${model}")" || { echo "Unknown model: ${model}" >&2; exit 2; }
    [[ ${model} == vl ]] && model=qwen-vl
    stop_gpu
    wait_gpu_free
    systemctl start "${unit}"
    wait_api "${unit}"
    echo "${model}" >"${active_file}"
    systemctl start local-ai-open-webui.service
    wait_webui
    echo "Active model: ${model} (http://192.168.1.65:3000, API :8080)"
    ;;
  stop)
    stop_gpu
    echo "GPU services stopped"
    ;;
  status)
    echo "Selected: $(cat "${active_file}" 2>/dev/null || echo qwen14)"
    for unit in local-ai-llama local-ai-coder30 local-ai-qwen-vl local-ai-open-webui local-ai-comfyui local-ai-whisper; do
      printf '%-25s %s\n' "${unit}" "$(systemctl is-active "${unit}.service" 2>/dev/null || true)"
    done
    nvidia-smi --query-gpu=name,memory.used,memory.total,temperature.gpu --format=csv,noheader
    ;;
  *)
    echo "Usage: sudo ai-model {status|start qwen14|start coder30|start qwen-vl|stop}" >&2
    exit 2
    ;;
esac
EOF
chmod 0755 /usr/local/sbin/ai-model

cat >/usr/local/sbin/ai-mode <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

case "${1:-status}" in
  llm)
    /usr/local/sbin/ai-model start "$(cat /etc/local-ai/active-model 2>/dev/null || echo qwen14)"
    ;;
  comfy|image|video)
    /usr/local/sbin/ai-model stop >/dev/null
    systemctl start local-ai-comfyui.service
    echo "ComfyUI mode: http://192.168.1.65:8188"
    ;;
  whisper|speech)
    /usr/local/sbin/ai-model stop >/dev/null
    systemctl start local-ai-whisper.service
    echo "Whisper mode: http://192.168.1.65:8000"
    ;;
  off)
    /usr/local/sbin/ai-model stop
    ;;
  status)
    /usr/local/sbin/ai-model status
    ;;
  *)
    echo "Usage: sudo ai-mode {llm|comfy|image|video|whisper|speech|off|status}" >&2
    exit 2
    ;;
esac
EOF
chmod 0755 /usr/local/sbin/ai-mode

cat >/etc/systemd/system/local-ai-autostart.service <<'EOF'
[Unit]
Description=Start the selected Local AI LLM profile
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/usr/local/sbin/ai-model start "$(cat /etc/local-ai/active-model 2>/dev/null || echo qwen14)"'
RemainAfterExit=yes
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl disable local-ai-coder30.service local-ai-qwen-vl.service >/dev/null 2>&1 || true
systemctl disable local-ai-llama.service local-ai-open-webui.service >/dev/null 2>&1 || true
systemctl enable local-ai-autostart.service >/dev/null

echo "Models installed. Switch with: sudo ai-model start {qwen14|coder30|qwen-vl}"
