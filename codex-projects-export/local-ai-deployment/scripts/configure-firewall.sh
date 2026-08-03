#!/usr/bin/env bash
set -Eeuo pipefail

CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
if [[ ${EUID} -ne 0 ]]; then echo "Run as root." >&2; exit 1; fi

ufw default deny incoming
ufw default allow outgoing
for port in 22 3000 8000 8080 8188; do
  ufw allow from "${CONTROLLER_CIDR}" to any port "${port}" proto tcp comment "local-ai controller"
done
ufw --force enable
ufw status numbered

