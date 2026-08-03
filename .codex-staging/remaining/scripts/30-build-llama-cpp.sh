#!/usr/bin/env bash
set -Eeuo pipefail

umask 027
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
LOG_DIR="${LOG_DIR:-${REPO_ROOT}/logs}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${LOG_DIR}/30-build-llama-cpp-${TIMESTAMP}.log"

LLAMA_TAG="${LLAMA_TAG:-b10229}"
EXPECTED_COMMIT="${EXPECTED_COMMIT:-c745be2a2c5aefbf9f3ced0440804373731890b6}"
SOURCE_DIR='/opt/ai-stack/src/llama.cpp'
BUILD_DIR="${SOURCE_DIR}/build-cuda"
RELEASE_DIR="/opt/ai-stack/releases/llama-${LLAMA_TAG}"
CUDA_HOME="${CUDA_HOME:-/usr/local/cuda-13.2}"
CMAKE_ARGS=(
    -G Ninja
    -DCMAKE_BUILD_TYPE=Release
    -DGGML_CUDA=ON
    -DCMAKE_CUDA_ARCHITECTURES=120
    -DGGML_NATIVE=ON
    -DLLAMA_BUILD_SERVER=ON
    -DLLAMA_BUILD_TOOLS=ON
    -DLLAMA_BUILD_EXAMPLES=ON
    -DLLAMA_BUILD_TESTS=OFF
)
LINKS=(llama-server llama-cli llama-bench llama-gguf llama-gguf-hash llama-gguf-split llama-quantize)

mkdir -p -- "${LOG_DIR}"
exec > >(tee -a -- "${LOG_FILE}") 2>&1

on_error() {
    local rc=$?
    printf 'ERROR: %s line %s exit %s\n' \
        "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" "${BASH_LINENO[0]:-unknown}" "${rc}" >&2
    exit "${rc}"
}
trap on_error ERR

if [[ "${1:-}" != '--apply' ]]; then
    printf 'Plan: build official llama.cpp %s (%s) with CUDA architecture 120.\n' \
        "${LLAMA_TAG}" "${EXPECTED_COMMIT}"
    printf 'Source: https://github.com/ggml-org/llama.cpp.git\n'
    printf 'Release: %s\nRe-run with --apply to build/install.\n' "${RELEASE_DIR}"
    exit 2
fi

for command_name in cmake git ninja sha256sum sudo; do
    command -v "${command_name}" >/dev/null 2>&1 || {
        printf 'Missing command: %s\n' "${command_name}" >&2
        exit 69
    }
done
[[ -x "${CUDA_HOME}/bin/nvcc" ]] || {
    printf 'nvcc is missing: %s/bin/nvcc\n' "${CUDA_HOME}" >&2
    exit 69
}

if [[ -x "${RELEASE_DIR}/bin/llama-server" && -r "${RELEASE_DIR}/SHA256SUMS" ]]; then
    (cd / && sha256sum -c "${RELEASE_DIR}/SHA256SUMS" >/dev/null)
    "${RELEASE_DIR}/bin/llama-server" --version
    printf 'Requested release is already installed and verified.\n'
    exit 0
fi

if ! getent passwd qwenllm >/dev/null 2>&1; then
    backup_dir="/srv/local-ai/backups/ai-station-bootstrap-${TIMESTAMP}"
    sudo install -d -o root -g root -m 0700 "${backup_dir}"
    sudo tar --acls --xattrs --numeric-owner -C / -czf \
        "${backup_dir}/pre-llama-identity.tar.gz" \
        etc/passwd etc/group etc/shadow etc/gshadow etc/subuid etc/subgid
    sudo chmod 0600 "${backup_dir}/pre-llama-identity.tar.gz"
    sudo useradd --system --home-dir /nonexistent --no-create-home \
        --shell /usr/sbin/nologin qwenllm
fi

sudo install -d -o user -g user -m 0755 /opt/ai-stack/src
sudo install -d -o root -g root -m 0755 /opt/ai-stack/bin /opt/ai-stack/releases

if [[ ! -e "${SOURCE_DIR}" ]]; then
    git clone --depth 1 --branch "${LLAMA_TAG}" \
        https://github.com/ggml-org/llama.cpp.git "${SOURCE_DIR}"
elif [[ ! -d "${SOURCE_DIR}/.git" ]]; then
    printf 'Refusing to overwrite non-Git source directory: %s\n' "${SOURCE_DIR}" >&2
    exit 73
fi

actual_commit="$(git -C "${SOURCE_DIR}" rev-parse HEAD)"
if [[ "${actual_commit}" != "${EXPECTED_COMMIT}" ]]; then
    printf 'Source commit mismatch: expected %s, found %s\n' \
        "${EXPECTED_COMMIT}" "${actual_commit}" >&2
    exit 74
fi

export CUDA_HOME
export PATH="${CUDA_HOME}/bin:${PATH}"
cmake -S "${SOURCE_DIR}" -B "${BUILD_DIR}" "${CMAKE_ARGS[@]}"
cmake --build "${BUILD_DIR}" --parallel "${BUILD_JOBS:-28}"

sudo install -d -o root -g root -m 0755 "${RELEASE_DIR}"
sudo cp -a "${BUILD_DIR}/bin" "${RELEASE_DIR}/bin"
sudo chown -R root:root "${RELEASE_DIR}/bin"
sudo find "${RELEASE_DIR}/bin" -type d -exec chmod 0755 {} \;
sudo find "${RELEASE_DIR}/bin" -type f -exec chmod a+r {} \;
sudo find "${RELEASE_DIR}/bin" -maxdepth 1 -type f -executable -exec chmod 0755 {} \;

for name in "${LINKS[@]}"; do
    link="/opt/ai-stack/bin/${name}"
    target="${RELEASE_DIR}/bin/${name}"
    if [[ -L "${link}" && "$(readlink -f -- "${link}")" == "${target}" ]]; then
        continue
    fi
    if [[ -e "${link}" || -L "${link}" ]]; then
        printf 'Refusing to replace existing path: %s\n' "${link}" >&2
        exit 75
    fi
    sudo ln -s "${target}" "${link}"
done

find "${RELEASE_DIR}/bin" -maxdepth 1 -type f -print0 \
    | sort -z | xargs -0 sha256sum \
    | sudo tee "${RELEASE_DIR}/SHA256SUMS" >/dev/null
sudo chown root:root "${RELEASE_DIR}/SHA256SUMS"
sudo chmod 0644 "${RELEASE_DIR}/SHA256SUMS"
(cd / && sha256sum -c "${RELEASE_DIR}/SHA256SUMS" >/dev/null)
/opt/ai-stack/bin/llama-server --version
/opt/ai-stack/bin/llama-cli --version
/opt/ai-stack/bin/llama-bench --list-devices
printf 'llama.cpp build complete. Log: %s\n' "${LOG_FILE}"
