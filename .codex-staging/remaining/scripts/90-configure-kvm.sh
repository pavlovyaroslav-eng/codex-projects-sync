#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
mkdir -p "$REPO/logs"
readonly LOG_FILE="$REPO/logs/90-configure-kvm-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR
packages=(qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients virt-manager virt-viewer ovmf swtpm swtpm-tools)

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: install KVM/libvirt packages and define a non-forwarded isolated network. No passthrough, BIOS, disk-partition, or boot-loader changes."
  apt-get --simulate install "${packages[@]}"
  exit 0
fi

grep -Eq '\b(vmx|svm)\b' /proc/cpuinfo
test -e /dev/kvm
sudo apt-get update
sudo apt-get install -y "${packages[@]}"
sudo systemctl enable --now libvirtd.service
sudo virsh capabilities >/dev/null

network_xml="$REPO/vm/windows-analysis-isolated.xml"
if sudo virsh net-info windows-analysis-isolated >/dev/null 2>&1; then
  current_xml="$(mktemp)"
  trap 'rc=$?; rm -f -- "$current_xml"; exit "$rc"' EXIT
  sudo virsh net-dumpxml windows-analysis-isolated >"$current_xml"
  if grep -q '<forward' "$current_xml"; then
    echo "Existing network unexpectedly has forwarding; refusing to modify it automatically." >&2
    exit 1
  fi
else
  sudo virsh net-define "$network_xml"
fi
sudo virsh net-autostart windows-analysis-isolated
network_info="$(sudo virsh net-info windows-analysis-isolated)"
if ! grep -q 'Active:.*yes' <<<"$network_info"; then
  sudo virsh net-start windows-analysis-isolated
fi
sudo virsh net-dumpxml windows-analysis-isolated | tee "$REPO/reports/KVM_ISOLATED_NETWORK.xml"
network_dump="$(sudo virsh net-dumpxml windows-analysis-isolated)"
if grep -q '<forward' <<<"$network_dump"; then
  echo "Isolated network contains forwarding" >&2
  exit 1
fi
if sudo virsh net-info default >/dev/null 2>&1; then
  sudo virsh net-dumpxml default >"$REPO/reports/KVM_DEFAULT_NETWORK.xml"
  default_info="$(sudo virsh net-info default)"
  if grep -q 'Active:.*yes' <<<"$default_info"; then
    sudo virsh net-destroy default
  fi
  sudo virsh net-autostart default --disable
fi
echo "KVM/libvirt installed; isolated network active with no forwarding."
