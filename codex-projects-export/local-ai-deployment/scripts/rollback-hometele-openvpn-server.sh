#!/usr/bin/env bash
set -Eeuo pipefail

STATE_ROOT=/var/lib/local-ai-openvpn
BACKUP_ROOT="${1:-$(cat "${STATE_ROOT}/last-backup" 2>/dev/null || true)}"
if [[ ${EUID} -ne 0 ]]; then echo "Run as root." >&2; exit 1; fi
case "${BACKUP_ROOT}" in
  /var/backups/openvpn-local-ai-*) ;;
  *) echo "Refusing unexpected backup path: ${BACKUP_ROOT}" >&2; exit 2 ;;
esac
[[ -d "${BACKUP_ROOT}" ]] || { echo "Backup not found: ${BACKUP_ROOT}" >&2; exit 2; }

systemctl disable --now openvpn-server@local-ai.service 2>/dev/null || true
systemctl disable --now openvpn.service 2>/dev/null || true
if [[ -f "${BACKUP_ROOT}/openvpn.was-absent" ]]; then
  rm -rf -- /etc/openvpn
else
  rm -rf -- /etc/openvpn
  cp -a "${BACKUP_ROOT}/openvpn.before" /etc/openvpn
fi
install -m 0644 "${BACKUP_ROOT}/user.rules" /etc/ufw/user.rules
install -m 0640 "${BACKUP_ROOT}/user6.rules" /etc/ufw/user6.rules
ufw reload
rm -rf -- "${STATE_ROOT}/export"
systemctl daemon-reload
echo "Restored ${BACKUP_ROOT}; OpenVPN packages were left installed."
