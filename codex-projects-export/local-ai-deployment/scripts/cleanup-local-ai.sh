#!/usr/bin/env bash
set -Eeuo pipefail

for directory in /srv/local-ai/cache/comfyui-temp /srv/local-ai/input/whisper; do
  [[ -d "${directory}" ]] || continue
  find "${directory}" -xdev -type f -mtime +2 -delete
  find "${directory}" -xdev -type d -empty -mindepth 1 -delete
done
find /srv/local-ai/models -xdev -type f \( -name '*.part' -o -name '*.aria2' \) -mtime +14 -delete
find /var/log/local-ai -xdev -type f -name '*.log.*' -mtime +35 -delete

