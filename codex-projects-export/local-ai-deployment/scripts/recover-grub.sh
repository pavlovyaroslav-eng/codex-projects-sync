#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run from an Ubuntu live session with sudo after mounting the installed system." >&2
  exit 1
fi
if [[ ! -d /sys/firmware/efi ]]; then
  echo "Boot the recovery media in UEFI mode." >&2
  exit 1
fi
if ! mountpoint -q /boot/efi; then
  echo "/boot/efi is not mounted; mount the existing EFI System Partition first." >&2
  exit 1
fi

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
update-grub
efibootmgr -v

