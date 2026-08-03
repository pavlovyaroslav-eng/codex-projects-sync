#!/usr/bin/env bash
set -Eeuo pipefail

# Reproducible Ubuntu 24.04 system-base configuration for the local AI host.
# Run as root after ubuntu-stage1-bootstrap.sh.

EXPECTED_UBUNTU_VERSION="24.04"
EXPECTED_WINDOWS_EFI="/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi"
SWAP_FILE="/swap.img"
SWAP_SIZE="16G"
STATE_ROOT="/var/lib/local-ai"
LOG_ROOT="/var/log/local-ai"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ROLLBACK_ROOT="${STATE_ROOT}/rollback/stage2-${TIMESTAMP}"
LOG_FILE="${LOG_ROOT}/ubuntu-stage2-${TIMESTAMP}.log"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

source /etc/os-release
if [[ ${ID:-} != ubuntu || ${VERSION_ID:-} != "${EXPECTED_UBUNTU_VERSION}" ]]; then
  echo "Expected Ubuntu ${EXPECTED_UBUNTU_VERSION}; found ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

if [[ ! -d /sys/firmware/efi || ! -f "${EXPECTED_WINDOWS_EFI}" ]]; then
  echo "UEFI boot or Windows Boot Manager was not detected; refusing GRUB changes." >&2
  exit 1
fi

install -d -m 0755 "${STATE_ROOT}" "${LOG_ROOT}"
install -d -m 0700 "${ROLLBACK_ROOT}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[$(date --iso-8601=seconds)] Ubuntu stage 2 started"
cp -a /etc/default/grub "${ROLLBACK_ROOT}/grub.before"
cp -a /etc/fstab "${ROLLBACK_ROOT}/fstab.before"
efibootmgr -v >"${ROLLBACK_ROOT}/efibootmgr.before.txt"
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,UUID,PARTUUID,MOUNTPOINTS \
  >"${ROLLBACK_ROOT}/lsblk.before.txt"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y --no-install-recommends os-prober unattended-upgrades

if ! grep -Eq '^/swap\.img[[:space:]]+none[[:space:]]+swap[[:space:]]' /etc/fstab; then
  echo "Expected /swap.img entry is missing from /etc/fstab; refusing swap replacement." >&2
  exit 1
fi
if [[ ! -f "${SWAP_FILE}" ]]; then
  echo "Expected regular swap file ${SWAP_FILE} was not found." >&2
  exit 1
fi

if swapon --noheadings --show=NAME | grep -Fxq "${SWAP_FILE}"; then
  swapoff "${SWAP_FILE}"
fi
fallocate -l "${SWAP_SIZE}" "${SWAP_FILE}"
chmod 0600 "${SWAP_FILE}"
mkswap -f "${SWAP_FILE}"
swapon "${SWAP_FILE}"

set_grub_value() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" /etc/default/grub; then
    sed -i "s|^${key}=.*|${key}=${value}|" /etc/default/grub
  else
    printf '%s=%s\n' "${key}" "${value}" >>/etc/default/grub
  fi
}

set_grub_value GRUB_DEFAULT saved
set_grub_value GRUB_SAVEDEFAULT true
set_grub_value GRUB_TIMEOUT_STYLE menu
set_grub_value GRUB_TIMEOUT 10

if ! os-prober | grep -Fq "Windows Boot Manager"; then
  echo "Windows Boot Manager was not detected by os-prober; refusing update-grub." >&2
  exit 1
fi

update-grub
grub-script-check /boot/grub/grub.cfg
if ! grep -Fq "Windows Boot Manager" /boot/grub/grub.cfg; then
  echo "Generated GRUB menu does not contain Windows Boot Manager." >&2
  exit 1
fi

systemctl enable --now fstrim.timer
systemctl enable --now unattended-upgrades.service

{
  echo "===== SWAP ====="
  swapon --show --bytes
  echo "===== GRUB DEFAULTS ====="
  grep -E '^GRUB_(DEFAULT|SAVEDEFAULT|TIMEOUT_STYLE|TIMEOUT)=' /etc/default/grub
  echo "===== WINDOWS MENU ENTRY ====="
  grep -n -F "Windows Boot Manager" /boot/grub/grub.cfg
  echo "===== EFI BOOT ORDER ====="
  efibootmgr
  echo "===== SERVICES ====="
  systemctl is-enabled fstrim.timer unattended-upgrades.service
  systemctl is-active fstrim.timer unattended-upgrades.service
} | tee "${STATE_ROOT}/ubuntu-stage2-${TIMESTAMP}.txt"

chmod 0640 "${LOG_FILE}" "${STATE_ROOT}/ubuntu-stage2-${TIMESTAMP}.txt"
chown root:user "${LOG_FILE}" "${STATE_ROOT}/ubuntu-stage2-${TIMESTAMP}.txt"

echo "[$(date --iso-8601=seconds)] Ubuntu stage 2 complete"
echo "Rollback files: ${ROLLBACK_ROOT}"
echo "Log: ${LOG_FILE}"
