#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly MODEL="/srv/ai/models/qwen3-coder-30b-a3b/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
readonly PORT=18012
readonly BASE_URL="http://127.0.0.1:${PORT}"
readonly OUTPUT_DIR="${REPO}/logs/llm-context-matrix-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUTPUT_DIR"
current_unit=""

cleanup() {
  if [[ -n "$current_unit" ]]; then
    sudo systemctl stop "$current_unit" >/dev/null 2>&1 || : # optional cleanup after an earlier failure
    sudo systemctl reset-failed "$current_unit" >/dev/null 2>&1 || : # optional cleanup
  fi
}
trap cleanup EXIT
trap 'rc=$?; printf "context-matrix: error line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit "$rc"' ERR

test ! -e "$OUTPUT_DIR/complete"
for ctx in 8192 16384 32768; do
  case "$ctx" in
    8192) prompt_tokens=4096 ;;
    16384) prompt_tokens=8192 ;;
    32768) prompt_tokens=16384 ;;
  esac
  current_unit="qwen3-context-${ctx}.service"
  started_ns="$(date +%s%N)"
  sudo systemd-run --unit="${current_unit%.service}" --collect --service-type=simple \
    --property=User=qwenllm --property=Group=qwenllm \
    --property=NoNewPrivileges=true --property=PrivateTmp=true \
    --property=ProtectSystem=strict --property=ProtectHome=true \
    --property=IPAddressDeny=any --property=IPAddressAllow=localhost \
    /opt/ai-stack/bin/llama-server --model "$MODEL" \
    --alias qwen3-coder-30b-a3b-q4km --host 127.0.0.1 --port "$PORT" \
    --ctx-size "$ctx" --parallel 1 --threads 28 --batch-size 512 --ubatch-size 128 \
    --n-gpu-layers 99 --n-cpu-moe 32 --flash-attn on \
    --cache-type-k q8_0 --cache-type-v q8_0 --no-kv-offload --load-mode mmap --metrics

  ready=false
  for _ in {1..180}; do
    if curl --fail --silent --max-time 2 "$BASE_URL/health" >/dev/null; then
      ready=true
      break
    fi
    sleep 1
  done
  [[ "$ready" == true ]]
  ready_ns="$(date +%s%N)"
  awk -v start="$started_ns" -v ready="$ready_ns" \
    'BEGIN { printf "startup_seconds=%.3f\n", (ready-start)/1000000000 }' \
    >"$OUTPUT_DIR/context-${ctx}-startup.txt"
  systemctl show "$current_unit" -p ActiveState -p SubState -p MainPID -p MemoryCurrent \
    >"$OUTPUT_DIR/context-${ctx}-systemd.txt"
  nvidia-smi --query-gpu=memory.used,memory.free,temperature.gpu,utilization.gpu \
    --format=csv >"$OUTPUT_DIR/context-${ctx}-gpu.csv"
  "$REPO/tests/test-llm-contexts.py" "$BASE_URL" "$prompt_tokens" \
    >"$OUTPUT_DIR/context-${ctx}-request.json"
  journalctl --no-pager -u "$current_unit" >"$OUTPUT_DIR/context-${ctx}-journal.txt"
  sudo systemctl stop "$current_unit"
  sudo systemctl reset-failed "$current_unit" >/dev/null 2>&1 || : # unit may already be collected
  current_unit=""
done
touch "$OUTPUT_DIR/complete"
printf '%s\n' "$OUTPUT_DIR"
