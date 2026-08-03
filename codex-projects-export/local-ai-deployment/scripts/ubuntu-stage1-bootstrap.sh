#!/usr/bin/env bash
set -Eeuo pipefail

# First post-install Ubuntu 24.04 bootstrap. Run locally once as:
#   sudo bash ubuntu-stage1-bootstrap.sh <ubuntu-user>
# It establishes limited key-only SSH access and collects a read-only baseline.
# It does not install NVIDIA/CUDA, AI applications, models, VPN, or alter GRUB.

TARGET_USER="${1:-${SUDO_USER:-}}"
CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
EXPECTED_UBUNTU_VERSION="24.04"
PUBLIC_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUcNxSfwsut+b1yvhX8j0yMcorD6pR2GVI4wfkFLaxd ACER-X-02 local-ai admin v2'
AUDIT_ROOT='/var/lib/local-ai/bootstrap'

if [[ ${EUID} -ne 0 ]]; then
  echo 'Run this script with sudo.' >&2
  exit 1
fi

if [[ -z ${TARGET_USER} || ${TARGET_USER} == root ]] || ! id "${TARGET_USER}" >/dev/null 2>&1; then
  echo 'Pass the existing non-root Ubuntu username as argument 1.' >&2
  exit 1
fi

source /etc/os-release
if [[ ${ID:-} != ubuntu || ${VERSION_ID:-} != "${EXPECTED_UBUNTU_VERSION}" ]]; then
  echo "Expected Ubuntu ${EXPECTED_UBUNTU_VERSION}; found ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  openssh-server ufw fail2ban ca-certificates curl git jq \
  pciutils usbutils ethtool nvme-cli smartmontools lm-sensors \
  numactl efibootmgr dmidecode \
  python3 python3-venv python3-pip python3-dev build-essential cmake ninja-build \
  pkg-config wget aria2 nvtop htop pipx ffmpeg

hostnamectl set-hostname local-ai

install -d -m 0755 /opt/local-ai /srv/local-ai /etc/local-ai /var/log/local-ai "${AUDIT_ROOT}"
chown "${TARGET_USER}:${TARGET_USER}" /opt/local-ai /srv/local-ai

USER_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0700 "${USER_HOME}/.ssh"
AUTHORIZED_KEYS="${USER_HOME}/.ssh/authorized_keys"
touch "${AUTHORIZED_KEYS}"
chown "${TARGET_USER}:${TARGET_USER}" "${AUTHORIZED_KEYS}"
chmod 0600 "${AUTHORIZED_KEYS}"
if ! grep -Fqx "${PUBLIC_KEY}" "${AUTHORIZED_KEYS}"; then
  printf '%s\n' "${PUBLIC_KEY}" >>"${AUTHORIZED_KEYS}"
fi

cat >/etc/ssh/sshd_config.d/60-local-ai.conf <<'EOF'
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
X11Forwarding no
EOF

sshd -t
systemctl enable ssh
systemctl restart ssh

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from "${CONTROLLER_CIDR}" to any port 22 proto tcp comment 'local-ai controller SSH'
ufw --force enable
systemctl enable --now fail2ban

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="${AUDIT_ROOT}/ubuntu-stage1-${TIMESTAMP}.txt"
{
  echo '===== OS ====='
  cat /etc/os-release
  uname -a
  echo '===== CPU / NUMA ====='
  lscpu
  numactl --hardware 2>&1 || true
  echo '===== MEMORY ====='
  free -h
  echo '===== PCI / GPU ====='
  lspci -nnk | grep -A4 -Ei 'VGA|3D|NVIDIA' || true
  echo '===== STORAGE ====='
  lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,LABEL,UUID,PARTUUID,MOUNTPOINTS,MODEL,SERIAL
  findmnt --real
  nvme list 2>&1 || true
  nvme smart-log /dev/nvme0 2>&1 || true
  echo '===== UEFI / BOOT ====='
  test -d /sys/firmware/efi && echo 'UEFI=yes' || echo 'UEFI=no'
  efibootmgr -v 2>&1 || true
  echo '===== NETWORK ====='
  ip -brief address
  ip route
  ethtool "$(ip route show default | awk '{print $5; exit}')" 2>&1 || true
  echo '===== SERVICES / FIREWALL ====='
  systemctl --no-pager --full status ssh fail2ban 2>&1 || true
  ufw status verbose
} >"${REPORT}"

chmod 0640 "${REPORT}"
chown root:"${TARGET_USER}" "${REPORT}"

echo "Ubuntu stage 1 ready. Audit: ${REPORT}"
echo "SSH is allowed only from ${CONTROLLER_CIDR} for user ${TARGET_USER}."
