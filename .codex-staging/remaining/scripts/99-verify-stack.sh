#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly LOG_DIR="${REPO}/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/99-verify-stack-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly LOG_FILE
exec > >(tee -a "$LOG_FILE") 2>&1
on_error() {
  local rc=$?
  printf 'ERROR line=%s rc=%s command=%q\n' \
    "${BASH_LINENO[0]:-unknown}" "$rc" "$BASH_COMMAND" >&2
  exit "$rc"
}
trap on_error ERR

failures=()
check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
  else
    printf 'FAIL: %s\n' "$name" >&2
    failures+=("$name")
  fi
}

check "llama.cpp CUDA build" /opt/ai-stack/bin/llama-server --version
check "Qwen Code" /opt/ai-stack/bin/qwen --version
check "Ghidra headless" test -x /opt/ghidra/current/support/analyzeHeadless
check "pyghidra-mcp environment" /opt/ai-stack/venvs/pyghidra-mcp/bin/python -c \
  'import importlib.metadata as m; assert m.version("pyghidra-mcp") == "0.2.3"'
check "Qwen model checksum" bash -c \
  "sudo -n -u qwenllm bash -c 'cd /srv/ai/models/qwen3-coder-30b-a3b && sha256sum --check --strict SHA256SUMS'"
check "LLM service active" systemctl is-active --quiet qwen3-coder.service
check "LLM service enabled" systemctl is-enabled --quiet qwen3-coder.service
check "MCP service active" systemctl is-active --quiet pyghidra-mcp.service
check "MCP service enabled" systemctl is-enabled --quiet pyghidra-mcp.service
check "LLM health" curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8012/health
check "LLM API tests" "$REPO/tests/test-llm-api.sh"
check "LLM loopback bind" bash -c \
  "ss -ltnH 'sport = :8012' | grep -Fq '127.0.0.1:8012' && ! ss -ltnH 'sport = :8012' | grep -Eq '0\\.0\\.0\\.0:8012|\\[::\\]:8012'"
check "MCP loopback bind" bash -c \
  "ss -ltnH 'sport = :8000' | grep -Fq '127.0.0.1:8000' && ! ss -ltnH 'sport = :8000' | grep -Eq '0\\.0\\.0\\.0:8000|\\[::\\]:8000'"
check "Legacy external LLM port closed" bash -c \
  "! ss -ltnH 'sport = :8080' | grep -q ."
check "Qwen sees Ghidra MCP" bash -c \
  "/opt/ai-stack/bin/qwen mcp list 2>&1 | grep -Eq 'ghidra.*Connected'"
check "rootless Podman" bash -c \
  "podman info --format '{{.Host.Security.Rootless}}' | grep -Fxq true"
check "static-tools image" podman image exists localhost/ai-static-tools:1.0
check "KVM isolated network" bash -c \
  "virsh -c qemu:///system net-info windows-analysis-isolated | grep -q 'Active:.*yes' && ! virsh -c qemu:///system net-dumpxml windows-analysis-isolated | grep -q '<forward'"
check "Windows analysis VM definition" virsh -c qemu:///system dominfo windows-analysis
check "VM isolation policy" bash -c \
  "xml=\$(virsh -c qemu:///system dumpxml windows-analysis) && grep -Fq \"network='windows-analysis-isolated'\" <<<\"\$xml\" && grep -Fq \"copypaste='no'\" <<<\"\$xml\" && grep -Fq \"filetransfer enable='no'\" <<<\"\$xml\" && ! grep -Eq '<filesystem|<redirdev|source file=.*/home/|source dir=.*/home/' <<<\"\$xml\""

if ((${#failures[@]})); then
  printf 'FINAL_VERIFY=FAIL count=%s checks=%s\n' "${#failures[@]}" "${failures[*]}" >&2
  exit 1
fi
printf 'FINAL_VERIFY=PASS log=%s\n' "$LOG_FILE"
