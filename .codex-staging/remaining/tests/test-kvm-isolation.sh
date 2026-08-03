#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; printf "test-kvm-isolation: error line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit "$rc"' ERR

readonly VM="windows-analysis"
readonly REPO="${HOME}/ai-station-bootstrap"
readonly USER_ISO="${HOME}/AI-Workbench/samples-iso/ai-safe-test.iso"
readonly LIBVIRT_ISO="/var/lib/libvirt/boot/ai-safe-test.iso"

xorriso -as mkisofs -quiet -o "$USER_ISO" "$REPO/tests/safe_add.c"
sudo install -o root -g root -m 0644 "$USER_ISO" "$LIBVIRT_ISO"
sudo virsh attach-disk "$VM" "$LIBVIRT_ISO" sda --type cdrom --mode readonly --config
xml="$(sudo virsh dumpxml "$VM")"
grep -Fq "source file='$LIBVIRT_ISO'" <<<"$xml"
grep -Fq '<readonly/>' <<<"$xml"
sudo virsh detach-disk "$VM" sda --config

sudo virsh start "$VM"
sleep 8
state="$(sudo virsh domstate "$VM")"
grep -Eqi 'running|работает' <<<"$state"
interfaces="$(sudo virsh domiflist "$VM")"
grep -Fq 'windows-analysis-isolated' <<<"$interfaces"
display="$(sudo virsh domdisplay "$VM")"
grep -Fq '127.0.0.1' <<<"$display"
xml="$(sudo virsh dumpxml "$VM")"
if grep -Eq '<filesystem|<redirdev|source file=.*/home/|source dir=.*/home/' <<<"$xml"; then
  echo "Unsafe host sharing or USB redirection found" >&2
  exit 1
fi
sudo virsh destroy "$VM"

if ! sudo virsh snapshot-info "$VM" empty-template >/dev/null 2>&1; then
  sudo virsh snapshot-create-as "$VM" empty-template --description 'Empty isolated VM template before Windows installation'
fi
sudo virsh snapshot-revert "$VM" empty-template
sudo virsh snapshot-info "$VM" empty-template
sudo rm -f -- "$LIBVIRT_ISO" "$USER_ISO"
echo "KVM start, isolated interface, loopback display, read-only ISO, snapshot, and revert checks passed."
