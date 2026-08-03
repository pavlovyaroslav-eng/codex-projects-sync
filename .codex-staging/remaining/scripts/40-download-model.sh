#!/usr/bin/env bash
set -Eeuo pipefail

umask 027
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
LOG_DIR="${LOG_DIR:-${REPO_ROOT}/logs}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${LOG_DIR}/40-download-model-${TIMESTAMP}.log"

MODEL_REPO='unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF'
MODEL_REVISION='b17cb02dd882d5b6ab62fc777ad2995f19668350'
MODEL_FILE='Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf'
EXPECTED_SIZE=18556689568
EXPECTED_SHA256='fadc3e5f8d42bf7e894a785b05082e47daee4df26680389817e2093056f088ad'
MODEL_DIR='/srv/ai/models/qwen3-coder-30b-a3b'
FINAL_PATH="${MODEL_DIR}/${MODEL_FILE}"
PART_PATH="${FINAL_PATH}.part"
MODEL_URL="https://huggingface.co/${MODEL_REPO}/resolve/${MODEL_REVISION}/${MODEL_FILE}"
MIN_FREE_BYTES=$((150 * 1024 * 1024 * 1024))

mkdir -p -- "${LOG_DIR}"
exec > >(tee -a -- "${LOG_FILE}") 2>&1

on_error() {
    local rc=$?
    printf 'ERROR: %s line %s exit %s\n' \
        "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" "${BASH_LINENO[0]:-unknown}" "${rc}" >&2
    exit "${rc}"
}
trap on_error ERR

printf 'Repository: %s\nRevision: %s\nFile: %s\n' \
    "${MODEL_REPO}" "${MODEL_REVISION}" "${MODEL_FILE}"
printf 'Expected size: %s bytes\nExpected SHA-256: %s\n' \
    "${EXPECTED_SIZE}" "${EXPECTED_SHA256}"

if [[ -r "${FINAL_PATH}" ]]; then
    actual_size="$(stat -c %s "${FINAL_PATH}")"
    actual_hash="$(sha256sum "${FINAL_PATH}" | awk '{print $1}')"
    if [[ "${actual_size}" == "${EXPECTED_SIZE}" && "${actual_hash}" == "${EXPECTED_SHA256}" ]]; then
        printf 'Preferred model already exists and is verified.\n'
        exit 0
    fi
    printf 'Refusing to overwrite mismatched final model: %s\n' "${FINAL_PATH}" >&2
    exit 76
fi

available="$(df -B1 --output=avail /srv | awk 'NR==2{print $1}')"
if ((available - EXPECTED_SIZE < MIN_FREE_BYTES)); then
    printf 'Insufficient free-space reserve: %s bytes available\n' "${available}" >&2
    exit 77
fi

if [[ "${1:-}" != '--apply' ]]; then
    printf 'Plan only. Re-run with --apply to download with resume support.\n'
    exit 2
fi

sudo install -d -o root -g root -m 0755 /srv/ai /srv/ai/models
sudo install -d -o user -g qwenllm -m 0750 "${MODEL_DIR}"
curl --fail --location --retry 5 --retry-delay 5 --continue-at - \
    --output "${PART_PATH}" --progress-bar "${MODEL_URL}"

actual_size="$(stat -c %s "${PART_PATH}")"
[[ "${actual_size}" == "${EXPECTED_SIZE}" ]] || {
    printf 'Size mismatch: expected %s, got %s\n' "${EXPECTED_SIZE}" "${actual_size}" >&2
    exit 78
}
actual_hash="$(sha256sum "${PART_PATH}" | awk '{print $1}')"
[[ "${actual_hash}" == "${EXPECTED_SHA256}" ]] || {
    printf 'SHA-256 mismatch: expected %s, got %s\n' "${EXPECTED_SHA256}" "${actual_hash}" >&2
    exit 79
}

mv -- "${PART_PATH}" "${FINAL_PATH}"
sudo chown root:qwenllm "${FINAL_PATH}"
sudo chmod 0640 "${FINAL_PATH}"
printf '%s  %s\n' "${EXPECTED_SHA256}" "${MODEL_FILE}" \
    | sudo tee "${MODEL_DIR}/SHA256SUMS" >/dev/null
sudo chown root:qwenllm "${MODEL_DIR}/SHA256SUMS"
sudo chmod 0640 "${MODEL_DIR}/SHA256SUMS"
sudo -u qwenllm bash -c \
    'cd /srv/ai/models/qwen3-coder-30b-a3b && sha256sum --check --strict SHA256SUMS'
printf 'Model download complete. Log: %s\n' "${LOG_FILE}"
