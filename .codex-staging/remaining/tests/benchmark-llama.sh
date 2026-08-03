#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; printf "benchmark-llama: error line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit "$rc"' ERR

readonly MODEL="/srv/ai/models/qwen3-coder-30b-a3b/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
readonly BENCH="/opt/ai-stack/bin/llama-bench"
readonly OUTPUT_DIR="${OUTPUT_DIR:-${HOME}/ai-station-bootstrap/logs/llama-benchmark-$(date -u +%Y%m%dT%H%M%SZ)}"
test -r "$MODEL"
test -x "$BENCH"
if pgrep -x llama-server >/dev/null; then
  echo "Stop all llama-server instances before the benchmark to avoid invalid resource measurements." >&2
  exit 70
fi
mkdir -p "$OUTPUT_DIR"
nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used,memory.free,temperature.gpu --format=csv >"$OUTPUT_DIR/gpu-before.csv"
lscpu >"$OUTPUT_DIR/lscpu.txt"
free -h >"$OUTPUT_DIR/memory-before.txt"

nvidia-smi dmon -s pucvmet -d 1 -o DT >"$OUTPUT_DIR/gpu-telemetry.txt" 2>&1 &
gpu_monitor_pid=$!
mpstat -P ALL 1 >"$OUTPUT_DIR/cpu-telemetry.txt" 2>&1 &
cpu_monitor_pid=$!
stop_monitors() {
  local pid rc
  for pid in "$gpu_monitor_pid" "$cpu_monitor_pid"; do
    if kill "$pid" 2>/dev/null; then
      if wait "$pid" 2>/dev/null; then
        rc=0
      else
        rc=$?
      fi
      if [[ "$rc" -ne 0 && "$rc" -ne 130 && "$rc" -ne 143 ]]; then
        echo "Unexpected monitor exit status: pid=$pid rc=$rc" >&2
        return "$rc"
      fi
    fi
  done
}
trap 'stop_monitors' EXIT

run_profile() {
  local name="$1" ngl="$2" ncmoe="$3" threads="$4" batch="$5" ubatch="$6"
  echo "Running $name"
  /usr/bin/time -v "$BENCH" --model "$MODEL" --n-gpu-layers "$ngl" --n-cpu-moe "$ncmoe" \
    --threads "$threads" --batch-size "$batch" --ubatch-size "$ubatch" \
    --cache-type-k q8_0 --cache-type-v q8_0 --no-kv-offload 1 --flash-attn on \
    --load-mode mmap --n-prompt 512 --n-gen 32 --repetitions 1 --output json \
    >"$OUTPUT_DIR/${name}.json" 2>"$OUTPUT_DIR/${name}.stderr"
}

run_profile balanced 99 32 28 512 128
run_profile lower_gpu_layers 70 32 28 512 128
run_profile more_cpu_moe 99 36 28 512 128
run_profile smaller_batch_more_threads 99 32 32 256 64

stop_monitors
trap - EXIT
nvidia-smi --query-gpu=memory.used,memory.free,temperature.gpu --format=csv >"$OUTPUT_DIR/gpu-after.csv"
free -h >"$OUTPUT_DIR/memory-after.txt"
printf '%s\n' "$OUTPUT_DIR"
