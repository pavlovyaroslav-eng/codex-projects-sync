#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${1:---check} != --check ]]; then
  echo "This tool is check-only. Change pinned versions in the deployment repository, review the diff, back up, then rerun the relevant stage." >&2
  exit 2
fi

check_repo() {
  local name="$1" path="$2" remote="$3"
  if [[ ! -d "${path}/.git" ]]; then
    printf '%-12s not installed\n' "${name}"
    return
  fi
  local current upstream
  current="$(git -C "${path}" rev-parse HEAD)"
  upstream="$(git ls-remote "${remote}" refs/heads/main | awk '{print $1}')"
  printf '%-12s current=%s upstream-main=%s\n' "${name}" "${current}" "${upstream}"
}

check_repo llama.cpp /opt/local-ai/src/llama.cpp https://github.com/ggml-org/llama.cpp.git
check_repo ComfyUI /opt/local-ai/apps/ComfyUI-current https://github.com/Comfy-Org/ComfyUI.git
check_repo SAM2 /opt/local-ai/src/sam2 https://github.com/facebookresearch/sam2.git
echo "No files or services were changed."

