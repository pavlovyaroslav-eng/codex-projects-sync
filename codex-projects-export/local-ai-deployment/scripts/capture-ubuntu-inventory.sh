#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then echo "Run as root." >&2; exit 1; fi

section() { printf '\n===== %s =====\n' "$1"; }

section identity
date --iso-8601=seconds
hostnamectl
cat /etc/os-release
uname -a

section boot
efibootmgr -v
grub-editenv list || true
grep -E '^(GRUB_DEFAULT|GRUB_SAVEDEFAULT|GRUB_TIMEOUT|GRUB_TIMEOUT_STYLE)=' /etc/default/grub

section storage
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,MOUNTPOINTS,PARTUUID,MODEL
df -hT / /srv/local-ai
free -h
swapon --show
systemctl is-enabled fstrim.timer unattended-upgrades.service

section network
ip -brief address
ip route
interface="$(ip route show default | awk 'NR==1 {print $5}')"
ethtool "${interface}" 2>/dev/null | grep -E 'Speed:|Duplex:|Link detected:' || true
ss -lntup | grep -E ':(22|3000|8000|8080|8188)\b' || true
ufw status numbered

section security
sshd -T | grep -E '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|pubkeyauthentication) '
fail2ban-client status sshd || true
visudo -c

section gpu
nvidia-smi
/usr/local/cuda-13.2/bin/nvcc --version
/opt/local-ai/venvs/torch-cu132/bin/python - <<'PY'
import torch
print("torch", torch.__version__)
print("torch_cuda", torch.version.cuda)
print("cuda_available", torch.cuda.is_available())
print("device", torch.cuda.get_device_name(0))
print("capability", torch.cuda.get_device_capability(0))
PY

section applications
/opt/local-ai/apps/llama.cpp-current/bin/llama-server --version
/opt/local-ai/venvs/open-webui-0.9.5/bin/python -c 'import importlib.metadata as m; print("open-webui", m.version("open-webui"))' || true
/opt/local-ai/venvs/whisper/bin/python -c 'import faster_whisper; print("faster-whisper", faster_whisper.__version__)'
git -C /opt/local-ai/apps/ComfyUI-current rev-parse HEAD
git -C /opt/local-ai/src/sam2 rev-parse HEAD 2>/dev/null || true

section services
systemctl is-enabled local-ai-autostart.service local-ai-llama.service local-ai-open-webui.service \
  local-ai-coder30.service local-ai-qwen-vl.service local-ai-comfyui.service local-ai-whisper.service || true
systemctl is-active local-ai-autostart.service local-ai-llama.service local-ai-open-webui.service \
  local-ai-coder30.service local-ai-qwen-vl.service local-ai-comfyui.service local-ai-whisper.service || true
systemctl list-timers --all --no-pager | grep local-ai || true
/usr/local/sbin/ai-model status || true

section models
find /srv/local-ai/models -maxdepth 4 -type f \( -name '*.gguf' -o -name '*.safetensors' -o -name '*.pt' -o -name 'manifest.json' -o -name '*.manifest.json' \) \
  -printf '%s\t%p\n' | sort -n
cat /srv/local-ai/models/comfyui/custom-nodes-manifest.json 2>/dev/null || true
cat /srv/local-ai/output/sam2-test/result.json 2>/dev/null || true

section health
/usr/local/sbin/local-ai-health-check
