#!/usr/bin/env bash
set -Eeuo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ ${EUID} -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
bash "${DIR}/ubuntu-stage9-sam2-video.sh" "$@"
bash "${DIR}/ubuntu-stage10-comfy-nodes.sh" "$@"

