#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE_SOURCE="${1:-/tmp/local-ai.ovpn}"
CONTROLLER_VPN_CIDR="10.93.0.0/24"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_ROOT="/var/lib/local-ai/rollback/openvpn-client-${STAMP}"

if [[ ${EUID} -ne 0 ]]; then echo "Run as root." >&2; exit 1; fi
[[ -s "${PROFILE_SOURCE}" ]] || { echo "Profile not found: ${PROFILE_SOURCE}" >&2; exit 2; }
grep -Fq 'remote matrix.hometele.com.ru 21200' "${PROFILE_SOURCE}"
grep -Fq 'verify-x509-name local-ai-server name' "${PROFILE_SOURCE}"

install -d -m 0700 "${BACKUP_ROOT}"
cp -a /etc/openvpn "${BACKUP_ROOT}/openvpn.before" 2>/dev/null || \
  : >"${BACKUP_ROOT}/openvpn.was-absent"
cp -a /etc/ufw/user.rules /etc/ufw/user6.rules "${BACKUP_ROOT}/"
ip -4 route >"${BACKUP_ROOT}/routes.before.txt"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends openvpn
install -d -m 0755 /etc/openvpn/client
install -o root -g root -m 0600 "${PROFILE_SOURCE}" \
  /etc/openvpn/client/hometele-local-ai.conf

for port in 22 3000 8000 8080 8188; do
  if ! ufw status | grep -F "${port}/tcp" | grep -Fq "10.93.0.0/24"; then
    ufw allow in on tun93 proto tcp from "${CONTROLLER_VPN_CIDR}" to any port "${port}" \
      comment "Local AI ${port} from VPN"
  fi
done

systemctl enable --now openvpn-client@hometele-local-ai.service
for _ in {1..45}; do
  ip -4 addr show dev tun93 2>/dev/null | grep -Fq '10.93.0.10/24' && break
  systemctl is-active --quiet openvpn-client@hometele-local-ai.service || break
  sleep 2
done
systemctl is-active --quiet openvpn-client@hometele-local-ai.service
ip -4 addr show dev tun93 | grep -F '10.93.0.10/24'
ping -c 2 -W 3 10.93.0.1
ip -4 route show default | tee "${BACKUP_ROOT}/default-route.after.txt"
echo "Backup: ${BACKUP_ROOT}"
