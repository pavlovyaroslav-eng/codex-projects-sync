#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE="${1:-}"
VPN_CIDR="${VPN_CIDR:-10.93.0.0/24}"
if [[ ${EUID} -ne 0 ]]; then echo "Run as root." >&2; exit 1; fi
if [[ -z "${PROFILE}" || ! -f "${PROFILE}" ]]; then
  echo "Usage: sudo $0 /secure/path/local-ai.ovpn" >&2
  exit 2
fi
if ! grep -qE '^[[:space:]]*(client|tls-client)([[:space:]]|$)' "${PROFILE}"; then
  echo "The supplied file is not an OpenVPN client profile." >&2
  exit 2
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn
install -d -o root -g root -m 0700 /etc/openvpn/client
install -o root -g root -m 0600 "${PROFILE}" /etc/openvpn/client/hometele-local-ai.conf
systemctl enable --now openvpn-client@hometele-local-ai.service
for port in 22 3000 8000 8080 8188; do
  ufw allow from "${VPN_CIDR}" to any port "${port}" proto tcp comment "local-ai VPN"
done
echo "Installed local client profile. No server-side changes were made."

