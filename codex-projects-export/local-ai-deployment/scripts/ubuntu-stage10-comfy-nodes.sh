#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMFY_ROOT="/opt/local-ai/apps/ComfyUI-v0.29.2"
CUSTOM_ROOT="${COMFY_ROOT}/custom_nodes"
PYTHON="/opt/local-ai/venvs/torch-cu132/bin/python"
SAM_PYTHON="/opt/local-ai/venvs/sam2/bin/python"
SAM_PT="/srv/local-ai/models/sam2/sam2.1_hiera_small.pt"
SAM_COMFY_DIR="/srv/local-ai/models/comfyui/sam2"

MANAGER_COMMIT="2b40deba7d04afeee29ee70c88f6c336e43dc9ca"
VHS_COMMIT="4ee72c065db22c9d96c2427954dc69e7b908444b"
SAM_NODE_COMMIT="0c35fff5f382803e2310103357b5e985f5437f32"
RIFE_COMMIT="26545cc2dd95bc3d27f056016300673bdeee78f5"
CONTROL_AUX_COMMIT="e8b689a513c3e6b63edc44066560ca5919c0576e"
WAN_COMMIT="088128b224242e110d3906c6750e9a3a348a659b"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi
if [[ ! -f "${SAM_PT}" ]]; then
  echo "Install SAM 2 before ComfyUI SAM nodes." >&2
  exit 1
fi

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 "${CUSTOM_ROOT}" "${SAM_COMFY_DIR}"

clone_pinned() {
  local url="$1" directory="$2" commit="$3"
  if [[ ! -d "${directory}/.git" ]]; then
    runuser -u "${TARGET_USER}" -- git clone --filter=blob:none "${url}" "${directory}"
  fi
  runuser -u "${TARGET_USER}" -- git -C "${directory}" fetch --depth 1 origin "${commit}"
  runuser -u "${TARGET_USER}" -- git -C "${directory}" checkout --detach "${commit}"
  [[ $(runuser -u "${TARGET_USER}" -- git -C "${directory}" rev-parse HEAD) == "${commit}" ]]
}

clone_pinned https://github.com/ltdrdata/ComfyUI-Manager.git \
  "${CUSTOM_ROOT}/ComfyUI-Manager" "${MANAGER_COMMIT}"
clone_pinned https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
  "${CUSTOM_ROOT}/ComfyUI-VideoHelperSuite" "${VHS_COMMIT}"
clone_pinned https://github.com/kijai/ComfyUI-segment-anything-2.git \
  "${CUSTOM_ROOT}/ComfyUI-segment-anything-2" "${SAM_NODE_COMMIT}"
clone_pinned https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git \
  "${CUSTOM_ROOT}/ComfyUI-Frame-Interpolation" "${RIFE_COMMIT}"
clone_pinned https://github.com/Fannovel16/comfyui_controlnet_aux.git \
  "${CUSTOM_ROOT}/comfyui_controlnet_aux" "${CONTROL_AUX_COMMIT}"
clone_pinned https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
  "${CUSTOM_ROOT}/ComfyUI-WanVideoWrapper" "${WAN_COMMIT}"

# Dependencies were reviewed before installation; none of these commands runs node install scripts.
# Keep the known-working CUDA 13.2 Torch, torchvision and OpenCV wheels intact.
runuser -u "${TARGET_USER}" -- "${PYTHON}" -m pip install --no-cache-dir \
  opencv-python imageio-ffmpeg kornia scipy tqdm
runuser -u "${TARGET_USER}" -- "${PYTHON}" -m pip install --no-cache-dir \
  -r "${CUSTOM_ROOT}/ComfyUI-Manager/requirements.txt"
grep -Ev '^(torch|torchvision|opencv-python|numpy|Pillow)([<>=!~].*)?$' \
  "${CUSTOM_ROOT}/comfyui_controlnet_aux/requirements.txt" >/tmp/local-ai-control-aux-requirements.txt
runuser -u "${TARGET_USER}" -- "${PYTHON}" -m pip install --no-cache-dir \
  -r /tmp/local-ai-control-aux-requirements.txt
runuser -u "${TARGET_USER}" -- "${PYTHON}" -m pip install --no-cache-dir \
  -r "${CUSTOM_ROOT}/ComfyUI-WanVideoWrapper/requirements.txt"

runuser -u "${TARGET_USER}" -- "${SAM_PYTHON}" -m pip install --no-cache-dir safetensors
install -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  "${SCRIPT_DIR}/sam2_convert_checkpoint.py" /opt/local-ai/apps/sam2-convert-checkpoint.py

SAM_FP16="${SAM_COMFY_DIR}/sam2.1_hiera_small-fp16.safetensors"
if [[ ! -s "${SAM_FP16}" ]]; then
  runuser -u "${TARGET_USER}" -- "${SAM_PYTHON}" \
    /opt/local-ai/apps/sam2-convert-checkpoint.py "${SAM_PT}" "${SAM_FP16}" --half
fi
sha256sum "${SAM_FP16}" >"${SAM_FP16}.sha256"
chown "${TARGET_USER}:${TARGET_USER}" "${SAM_FP16}" "${SAM_FP16}.sha256"

if ! grep -q '^  sam2: sam2$' "${COMFY_ROOT}/extra_model_paths.yaml"; then
  printf '  sam2: sam2\n' >>"${COMFY_ROOT}/extra_model_paths.yaml"
fi
chown "${TARGET_USER}:${TARGET_USER}" "${COMFY_ROOT}/extra_model_paths.yaml"

cat >/srv/local-ai/models/comfyui/custom-nodes-manifest.json <<EOF
{"ComfyUI-Manager":"${MANAGER_COMMIT}","ComfyUI-VideoHelperSuite":"${VHS_COMMIT}","ComfyUI-segment-anything-2":"${SAM_NODE_COMMIT}","ComfyUI-Frame-Interpolation":"${RIFE_COMMIT}","comfyui_controlnet_aux":"${CONTROL_AUX_COMMIT}","ComfyUI-WanVideoWrapper":"${WAN_COMMIT}"}
EOF
chown "${TARGET_USER}:${TARGET_USER}" /srv/local-ai/models/comfyui/custom-nodes-manifest.json

echo "Pinned ComfyUI nodes installed: Manager, VHS, SAM 2, RIFE, ControlNet Aux, WanVideoWrapper."
