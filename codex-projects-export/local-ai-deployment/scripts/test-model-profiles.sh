#!/usr/bin/env bash
set -Eeuo pipefail

OUTPUT_ROOT="${OUTPUT_ROOT:-/srv/local-ai/output/model-tests}"
VL_IMAGE="${VL_IMAGE:-/srv/local-ai/output/comfyui/smoke/sdxl-local-ai_00001_.png}"
ORIGINAL_MODEL="$(cat /etc/local-ai/active-model 2>/dev/null || echo qwen14)"

case "${ORIGINAL_MODEL}" in
  qwen14|coder30|qwen-vl) ;;
  *) ORIGINAL_MODEL=qwen14 ;;
esac

mkdir -p "${OUTPUT_ROOT}"
restore_model() {
  sudo /usr/local/sbin/ai-model start "${ORIGINAL_MODEL}" >/dev/null 2>&1 || true
}
trap restore_model EXIT

record_runtime() {
  local name="$1" elapsed_ms="$2" unit="$3"
  {
    printf 'elapsed_ms=%s\n' "${elapsed_ms}"
    systemctl show "${unit}" -p MemoryCurrent --value | awk '{print "service_memory_bytes=" $1}'
    nvidia-smi --query-gpu=name,memory.used,memory.total,temperature.gpu \
      --format=csv,noheader
  } >"${OUTPUT_ROOT}/${name}-runtime.txt"
}

sudo /usr/local/sbin/ai-model start coder30 >/dev/null
cat >"${OUTPUT_ROOT}/coder-payload.json" <<'EOF'
{"model":"qwen3-coder-30b-a3b-q4km","messages":[{"role":"user","content":"Напиши только корректное определение Python-функции add(a, b), возвращающей сумму, без пояснений и Markdown."}],"temperature":0,"max_tokens":64}
EOF
start_ms="$(date +%s%3N)"
curl -fsS --max-time 300 -H 'Content-Type: application/json' \
  --data-binary @"${OUTPUT_ROOT}/coder-payload.json" \
  http://127.0.0.1:8080/v1/chat/completions >"${OUTPUT_ROOT}/coder-response.json"
elapsed_ms="$(( $(date +%s%3N) - start_ms ))"
record_runtime coder "${elapsed_ms}" local-ai-coder30.service

[[ -s "${VL_IMAGE}" ]]
python3 - "${VL_IMAGE}" "${OUTPUT_ROOT}/vl-payload.json" <<'PY'
import base64
import json
import sys

image, output = sys.argv[1:]
encoded = base64.b64encode(open(image, "rb").read()).decode("ascii")
payload = {
    "model": "qwen3-vl-8b-q4km",
    "messages": [{
        "role": "user",
        "content": [
            {"type": "text", "text": "Опиши изображение по-русски одним коротким предложением."},
            {"type": "image_url", "image_url": {"url": "data:image/png;base64," + encoded}},
        ],
    }],
    "temperature": 0,
    "max_tokens": 96,
}
with open(output, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, ensure_ascii=False)
PY

sudo /usr/local/sbin/ai-model start qwen-vl >/dev/null
start_ms="$(date +%s%3N)"
curl -fsS --max-time 300 -H 'Content-Type: application/json' \
  --data-binary @"${OUTPUT_ROOT}/vl-payload.json" \
  http://127.0.0.1:8080/v1/chat/completions >"${OUTPUT_ROOT}/vl-response.json"
elapsed_ms="$(( $(date +%s%3N) - start_ms ))"
record_runtime vl "${elapsed_ms}" local-ai-qwen-vl.service

jq -n \
  --arg coder "$(jq -r '.choices[0].message.content' "${OUTPUT_ROOT}/coder-response.json")" \
  --arg vl "$(jq -r '.choices[0].message.content' "${OUTPUT_ROOT}/vl-response.json")" \
  --argjson coder_elapsed "$(awk -F= '/elapsed_ms/{print $2}' "${OUTPUT_ROOT}/coder-runtime.txt")" \
  --argjson vl_elapsed "$(awk -F= '/elapsed_ms/{print $2}' "${OUTPUT_ROOT}/vl-runtime.txt")" \
  '{status:"ok",coder:{elapsed_ms:$coder_elapsed,response:$coder},vl:{elapsed_ms:$vl_elapsed,response:$vl}}' \
  | tee "${OUTPUT_ROOT}/result.json"
