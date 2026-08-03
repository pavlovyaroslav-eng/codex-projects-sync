#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly VM="windows-analysis"
readonly DISK="/var/lib/libvirt/images/windows-analysis.qcow2"
readonly ISO="/var/lib/libvirt/boot/windows-analysis.iso"
mkdir -p "$REPO/logs"
readonly LOG_FILE="$REPO/logs/95-create-analysis-vm-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR

if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: create a sparse 120 GiB qcow2 disk and define an isolated Windows VM. An owned Windows ISO must be copied manually to $ISO before OS installation."
  exit 0
fi

network_info="$(sudo virsh net-info windows-analysis-isolated)"
grep -q 'Active:.*yes' <<<"$network_info"
if [[ ! -e "$DISK" ]]; then
  sudo qemu-img create -f qcow2 -o cluster_size=2M,lazy_refcounts=on "$DISK" 120G
  sudo chown libvirt-qemu:kvm "$DISK"
  sudo chmod 0660 "$DISK"
fi
sudo qemu-img info --output=json "$DISK" | jq -e '.format == "qcow2" and .["virtual-size"] == 128849018880' >/dev/null

if ! sudo virsh dominfo "$VM" >/dev/null 2>&1; then
  sudo virsh define "$REPO/vm/windows-analysis.xml"
fi
sudo virsh dumpxml "$VM" >"$REPO/reports/WINDOWS_ANALYSIS_VM.xml"
if grep -Eq '<filesystem|<redirdev|source file=.*/home/|source dir=.*/home/' "$REPO/reports/WINDOWS_ANALYSIS_VM.xml"; then
  echo "Unsafe host sharing or USB redirection found" >&2
  exit 1
fi
grep -Fq "network='windows-analysis-isolated'" "$REPO/reports/WINDOWS_ANALYSIS_VM.xml"
grep -Fq "copypaste='no'" "$REPO/reports/WINDOWS_ANALYSIS_VM.xml"
grep -Fq "filetransfer enable='no'" "$REPO/reports/WINDOWS_ANALYSIS_VM.xml"

if [[ -f "$ISO" ]]; then
  sudo virsh attach-disk "$VM" "$ISO" sda --type cdrom --mode readonly --config
  echo "Owned Windows ISO attached read-only."
else
  echo "Windows ISO is absent at $ISO; VM definition is ready but Windows installation is intentionally not attempted."
fi
echo "Defined $VM with isolated networking and no host shares."
