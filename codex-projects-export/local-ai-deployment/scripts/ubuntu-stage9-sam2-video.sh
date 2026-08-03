#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SAM2_COMMIT="2b90b9f5ceec907a1c18123530e92e794ad901a4"
SAM2_SRC="/opt/local-ai/src/sam2"
SAM2_VENV="/opt/local-ai/venvs/sam2"
CHECKPOINT_DIR="/srv/local-ai/models/sam2"
CHECKPOINT="${CHECKPOINT_DIR}/sam2.1_hiera_small.pt"
CHECKPOINT_URL="https://huggingface.co/facebook/sam2.1-hiera-small/resolve/main/sam2.1_hiera_small.pt"
CHECKPOINT_SIZE="184416285"
CHECKPOINT_SHA="6d1aa6f30de5c92224f8172114de081d104bbd23dd9dc5c58996f0cad5dc4d38"
TORCH_INDEX="https://download.pytorch.org/whl/cu132"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  /opt/local-ai/src /opt/local-ai/venvs "${CHECKPOINT_DIR}" /srv/local-ai/output/sam2-test

if [[ ! -d "${SAM2_SRC}/.git" ]]; then
  runuser -u "${TARGET_USER}" -- git clone --filter=blob:none https://github.com/facebookresearch/sam2.git "${SAM2_SRC}"
fi
if [[ $(runuser -u "${TARGET_USER}" -- git -C "${SAM2_SRC}" rev-parse HEAD) != "${SAM2_COMMIT}" ]]; then
  runuser -u "${TARGET_USER}" -- git -C "${SAM2_SRC}" fetch --depth 1 origin "${SAM2_COMMIT}"
  runuser -u "${TARGET_USER}" -- git -C "${SAM2_SRC}" checkout --detach "${SAM2_COMMIT}"
fi
[[ $(runuser -u "${TARGET_USER}" -- git -C "${SAM2_SRC}" rev-parse HEAD) == "${SAM2_COMMIT}" ]]

if [[ ! -x "${SAM2_VENV}/bin/python" ]]; then
  runuser -u "${TARGET_USER}" -- python3 -m venv "${SAM2_VENV}"
fi
runuser -u "${TARGET_USER}" -- "${SAM2_VENV}/bin/python" -m pip install --upgrade pip setuptools wheel
runuser -u "${TARGET_USER}" -- "${SAM2_VENV}/bin/python" -m pip install --no-cache-dir \
  "torch==2.12.0" "torchvision==0.27.0" --index-url "${TORCH_INDEX}"
runuser -u "${TARGET_USER}" -- env \
  CUDA_HOME=/usr/local/cuda-13.2 \
  TORCH_CUDA_ARCH_LIST=12.0 \
  SAM2_BUILD_ALLOW_ERRORS=0 \
  "${SAM2_VENV}/bin/python" -m pip install --no-build-isolation -e "${SAM2_SRC}"
runuser -u "${TARGET_USER}" -- "${SAM2_VENV}/bin/python" -m pip install --no-cache-dir pillow

if [[ ! -f "${CHECKPOINT}" ]] || [[ $(stat -c %s "${CHECKPOINT}") != "${CHECKPOINT_SIZE}" ]] || \
   ! echo "${CHECKPOINT_SHA}  ${CHECKPOINT}" | sha256sum --check --status; then
  rm -f -- "${CHECKPOINT}.part"
  runuser -u "${TARGET_USER}" -- curl -fL --retry 10 --retry-all-errors \
    --connect-timeout 30 --speed-limit 1024 --speed-time 60 \
    -o "${CHECKPOINT}.part" "${CHECKPOINT_URL}"
  [[ $(stat -c %s "${CHECKPOINT}.part") == "${CHECKPOINT_SIZE}" ]]
  echo "${CHECKPOINT_SHA}  ${CHECKPOINT}.part" | sha256sum --check
  mv "${CHECKPOINT}.part" "${CHECKPOINT}"
fi
cat >"${CHECKPOINT}.manifest.json" <<EOF
{"model":"SAM 2.1 Hiera Small","publisher":"Meta AI","license":"Apache-2.0","size":${CHECKPOINT_SIZE},"sha256":"${CHECKPOINT_SHA}","source":"${CHECKPOINT_URL}","sam2_commit":"${SAM2_COMMIT}"}
EOF
chown "${TARGET_USER}:${TARGET_USER}" "${CHECKPOINT}.manifest.json"

install -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  "${SCRIPT_DIR}/sam2_video_test.py" /opt/local-ai/apps/sam2-video-test.py

cat >/usr/local/bin/sam2-video-test <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
sudo /usr/local/sbin/ai-mode off >/dev/null
trap 'sudo /usr/local/sbin/ai-mode llm >/dev/null' EXIT
cd "${SAM2_SRC}"
"${SAM2_VENV}/bin/python" /opt/local-ai/apps/sam2-video-test.py "\$@"
EOF
chmod 0755 /usr/local/bin/sam2-video-test

echo "SAM 2 ${SAM2_COMMIT} installed. Test: sam2-video-test"
