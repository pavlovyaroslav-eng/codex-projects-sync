#!/usr/bin/env bash
set -Eeuo pipefail

errors=0
check_url() {
  local name="$1" url="$2"
  if curl -fsS --max-time 10 "${url}" >/dev/null; then
    echo "OK   ${name} ${url}"
  else
    echo "FAIL ${name} ${url}"
    errors=$((errors + 1))
  fi
}

echo "Local AI health $(date --iso-8601=seconds)"
echo "Host: $(hostname)  Kernel: $(uname -r)"

if systemctl is-active --quiet local-ai-comfyui.service; then
  echo "Mode: comfy"
  check_url ComfyUI http://127.0.0.1:8188/system_stats
elif systemctl is-active --quiet local-ai-whisper.service; then
  echo "Mode: whisper"
  check_url Whisper http://127.0.0.1:8000/health
else
  echo "Mode: llm ($(cat /etc/local-ai/active-model 2>/dev/null || echo qwen14))"
check_url Qwen3-Coder http://127.0.0.1:8012/health
check_url Qwen3-API-compat http://127.0.0.1:8080/health
  check_url Open-WebUI http://127.0.0.1:3000/health
fi

if nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total,temperature.gpu \
  --format=csv,noheader; then
  echo "OK   NVIDIA"
else
  echo "FAIL NVIDIA"
  errors=$((errors + 1))
fi

available_kib="$(df --output=avail /srv/local-ai | tail -1 | tr -d ' ')"
echo "Disk available: $((available_kib / 1024 / 1024)) GiB"
if (( available_kib < 50 * 1024 * 1024 )); then
  echo "FAIL less than 50 GiB free"
  errors=$((errors + 1))
fi

echo "Result: ${errors} error(s)"
exit "${errors}"
