#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
CUDA_SERIES="13-2"
CUDA_HOME="/usr/local/cuda-13.2"
TORCH_VERSION="2.12.0"
TORCHVISION_VERSION="0.27.0"
TORCH_INDEX="https://download.pytorch.org/whl/cu132"
LLAMA_TAG="b10210"
LLAMA_COMMIT_PREFIX="0005475"
LOCAL_AI_ROOT="/opt/local-ai"
DATA_ROOT="/srv/local-ai"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="/var/lib/local-ai/ubuntu-stage3-${TIMESTAMP}.txt"
LOG="/var/log/local-ai/ubuntu-stage3-${TIMESTAMP}.log"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi
if ! id "${TARGET_USER}" >/dev/null 2>&1; then
  echo "Unknown target user: ${TARGET_USER}" >&2
  exit 1
fi

install -d -m 0755 /var/lib/local-ai /var/log/local-ai
exec > >(tee -a "${LOG}") 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y fwupd cmake ninja-build ccache libcurl4-openssl-dev

if ! dpkg-query -W -f='${Status}' cuda-keyring 2>/dev/null | grep -Fq "install ok installed"; then
  curl -fL --retry 5 \
    -o /tmp/cuda-keyring_1.1-1_all.deb \
    https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  dpkg -i /tmp/cuda-keyring_1.1-1_all.deb
fi
apt-get update
apt-get install -y "cuda-toolkit-${CUDA_SERIES}"

cat >/etc/profile.d/cuda-13-2.sh <<'EOF'
export CUDA_HOME=/usr/local/cuda-13.2
export PATH=/usr/local/cuda-13.2/bin:${PATH}
EOF
printf '%s\n' "${CUDA_HOME}/lib64" >/etc/ld.so.conf.d/cuda-13-2.conf
ldconfig

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  "${LOCAL_AI_ROOT}/venvs" \
  "${LOCAL_AI_ROOT}/src" \
  "${LOCAL_AI_ROOT}/apps" \
  "${DATA_ROOT}/models/llm" \
  "${DATA_ROOT}/models/whisper" \
  "${DATA_ROOT}/models/comfyui" \
  "${DATA_ROOT}/models/sam" \
  "${DATA_ROOT}/cache" \
  "${DATA_ROOT}/input" \
  "${DATA_ROOT}/output"

TORCH_VENV="${LOCAL_AI_ROOT}/venvs/torch-cu132"
if [[ ! -x "${TORCH_VENV}/bin/python" ]]; then
  runuser -u "${TARGET_USER}" -- python3 -m venv "${TORCH_VENV}"
fi
runuser -u "${TARGET_USER}" -- "${TORCH_VENV}/bin/python" -m pip install --upgrade pip setuptools wheel
runuser -u "${TARGET_USER}" -- "${TORCH_VENV}/bin/python" -m pip install --no-cache-dir \
  "torch==${TORCH_VERSION}" "torchvision==${TORCHVISION_VERSION}" \
  --index-url "${TORCH_INDEX}"

LLAMA_SRC="${LOCAL_AI_ROOT}/src/llama.cpp"
if [[ ! -d "${LLAMA_SRC}/.git" ]]; then
  runuser -u "${TARGET_USER}" -- git clone --depth 1 --branch "${LLAMA_TAG}" \
    https://github.com/ggml-org/llama.cpp.git "${LLAMA_SRC}"
fi
LLAMA_COMMIT="$(runuser -u "${TARGET_USER}" -- git -C "${LLAMA_SRC}" rev-parse HEAD)"
if [[ ${LLAMA_COMMIT} != ${LLAMA_COMMIT_PREFIX}* ]]; then
  echo "Unexpected llama.cpp commit ${LLAMA_COMMIT}; expected ${LLAMA_COMMIT_PREFIX}..." >&2
  exit 1
fi

COMPUTE_CAP="$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1 | tr -d '.')"
LLAMA_PREFIX="${LOCAL_AI_ROOT}/apps/llama.cpp-${LLAMA_TAG}"
runuser -u "${TARGET_USER}" -- env \
  PATH="${CUDA_HOME}/bin:${PATH}" \
  CUDA_HOME="${CUDA_HOME}" \
  cmake -S "${LLAMA_SRC}" -B "${LLAMA_SRC}/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${LLAMA_PREFIX}" \
    -DCMAKE_CUDA_ARCHITECTURES="${COMPUTE_CAP}" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DGGML_CUDA=ON \
    -DGGML_NATIVE=ON \
    -DLLAMA_CURL=ON
runuser -u "${TARGET_USER}" -- env PATH="${CUDA_HOME}/bin:${PATH}" \
  cmake --build "${LLAMA_SRC}/build" --parallel 28
runuser -u "${TARGET_USER}" -- cmake --install "${LLAMA_SRC}/build"
ln -sfn "${LLAMA_PREFIX}" "${LOCAL_AI_ROOT}/apps/llama.cpp-current"
printf '%s\n' "${LOCAL_AI_ROOT}/apps/llama.cpp-current/lib" \
  >/etc/ld.so.conf.d/local-ai-llama.conf
ldconfig

cat >/etc/profile.d/local-ai.sh <<'EOF'
export LOCAL_AI_ROOT=/opt/local-ai
export LOCAL_AI_DATA=/srv/local-ai
export PATH=/opt/local-ai/apps/llama.cpp-current/bin:${PATH}
EOF

runuser -u "${TARGET_USER}" -- "${TORCH_VENV}/bin/python" - <<'PY' | tee "${REPORT}"
import time
import torch

assert torch.cuda.is_available(), "PyTorch cannot access CUDA"
device = torch.cuda.get_device_name(0)
capability = torch.cuda.get_device_capability(0)
start = time.perf_counter()
x = torch.randn((4096, 4096), device="cuda")
y = x @ x
torch.cuda.synchronize()
elapsed = time.perf_counter() - start
print(f"torch={torch.__version__}")
print(f"torch_cuda={torch.version.cuda}")
print(f"device={device}")
print(f"compute_capability={capability[0]}.{capability[1]}")
print(f"matmul_4096_seconds={elapsed:.3f}")
print(f"checksum={y[0, 0].item():.6f}")
PY

{
  "${CUDA_HOME}/bin/nvcc" --version | tail -n 1
  nvidia-smi --query-gpu=name,driver_version,temperature.gpu,memory.total --format=csv,noheader
  "${LOCAL_AI_ROOT}/apps/llama.cpp-current/bin/llama-cli" --version
  "${LOCAL_AI_ROOT}/apps/llama.cpp-current/bin/llama-cli" --list-devices
  echo "llama_commit=${LLAMA_COMMIT}"
} | tee -a "${REPORT}"

chmod 0640 "${LOG}" "${REPORT}"
chown root:"${TARGET_USER}" "${LOG}" "${REPORT}"
echo "Ubuntu stage 3 complete. Report: ${REPORT}"
