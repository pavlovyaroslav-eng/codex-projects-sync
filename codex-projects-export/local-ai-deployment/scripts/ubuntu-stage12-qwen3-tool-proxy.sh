#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PROXY_SOURCE="${SCRIPT_DIR}/qwen3-coder-tool-proxy.py"
UNIT_SOURCE="${PROJECT_DIR}/systemd/local-ai-qwen3-tool-proxy.service"
DROPIN_SOURCE="${PROJECT_DIR}/systemd/local-ai-coder30.service.d/30-tool-proxy.conf"
WRAPPER=/usr/local/sbin/local-ai-coder30-start

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

for path in "${PROXY_SOURCE}" "${UNIT_SOURCE}" "${DROPIN_SOURCE}" "${WRAPPER}"; do
  if [[ ! -f ${path} ]]; then
    echo "Required file is missing: ${path}" >&2
    exit 1
  fi
done

id "${TARGET_USER}" >/dev/null
python3 "${PROXY_SOURCE}" --self-test

stamp="$(date +%Y%m%d-%H%M%S)"
backup="/srv/local-ai/backups/qwen3-tool-proxy-${stamp}"
install -d -m 0750 -o root -g root "${backup}"
cp -a "${WRAPPER}" "${backup}/local-ai-coder30-start"

for path in \
  /opt/local-ai/apps/qwen3-coder-tool-proxy.py \
  /etc/systemd/system/local-ai-qwen3-tool-proxy.service \
  /etc/systemd/system/local-ai-coder30.service.d/30-tool-proxy.conf; do
  if [[ -e ${path} ]]; then
    cp -a --parents "${path}" "${backup}"
  else
    printf 'ABSENT %s\n' "${path}" >>"${backup}/absent-before.txt"
  fi
done

install -m 0755 -o root -g root "${PROXY_SOURCE}" \
  /opt/local-ai/apps/qwen3-coder-tool-proxy.py

if [[ ${TARGET_USER} == user ]]; then
  install -m 0644 -o root -g root "${UNIT_SOURCE}" \
    /etc/systemd/system/local-ai-qwen3-tool-proxy.service
else
  tmp_unit="$(mktemp /tmp/local-ai-qwen3-tool-proxy.XXXXXX)"
  sed "s/^User=user$/User=${TARGET_USER}/; s/^Group=user$/Group=${TARGET_USER}/" \
    "${UNIT_SOURCE}" >"${tmp_unit}"
  install -m 0644 -o root -g root "${tmp_unit}" \
    /etc/systemd/system/local-ai-qwen3-tool-proxy.service
  rm -f "${tmp_unit}"
fi

install -d -m 0755 -o root -g root \
  /etc/systemd/system/local-ai-coder30.service.d
install -m 0644 -o root -g root "${DROPIN_SOURCE}" \
  /etc/systemd/system/local-ai-coder30.service.d/30-tool-proxy.conf

if grep -q -- '--host 0.0.0.0' "${WRAPPER}" && \
   grep -q -- '--port 8080' "${WRAPPER}"; then
  tmp="$(mktemp /tmp/local-ai-coder30-start.XXXXXX)"
  sed \
    -e 's/--host 0\.0\.0\.0/--host 127.0.0.1/' \
    -e 's/--port 8080/--port 8082/' \
    "${WRAPPER}" >"${tmp}"
  bash -n "${tmp}"
  install -m 0755 -o root -g root "${tmp}" "${WRAPPER}"
  rm -f "${tmp}"
elif ! grep -q -- '--host 127.0.0.1' "${WRAPPER}" || \
     ! grep -q -- '--port 8082' "${WRAPPER}"; then
  if grep -Fq -- '--host "${listen_host}"' "${WRAPPER}" && \
     grep -Fq -- '--port "${listen_port}"' "${WRAPPER}"; then
    : # Dynamic wrapper from stage 8 already selects the proxy backend port.
  else
    echo "Unexpected llama.cpp listen arguments in ${WRAPPER}; refusing to edit." >&2
    exit 1
  fi
fi

bash -n "${WRAPPER}"
python3 /opt/local-ai/apps/qwen3-coder-tool-proxy.py --self-test
systemctl daemon-reload

if systemctl is-active --quiet local-ai-coder30.service; then
  systemctl restart local-ai-coder30.service
  for _ in {1..180}; do
    if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
      break
    fi
    sleep 1
  done
  curl -fsS http://127.0.0.1:8080/health
  systemctl is-active --quiet local-ai-qwen3-tool-proxy.service
fi

echo "Installed Qwen3-Coder tool proxy. Backup: ${backup}"
echo "Rollback: restore ${backup}/local-ai-coder30-start, remove the proxy unit/drop-in, daemon-reload, and restart local-ai-coder30.service."
