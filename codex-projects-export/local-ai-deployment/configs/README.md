# Configuration inventory

Runtime configuration is generated on Ubuntu and backed up by
`local-ai-backup`:

- `/etc/local-ai/active-model`;
- `/etc/systemd/system/local-ai-*`;
- `/opt/local-ai/apps/ComfyUI-v0.29.2/extra_model_paths.yaml`;
- `/srv/local-ai/models/**/manifest.json`;
- `/etc/ufw` rules shown by `ufw status numbered`.

Secrets are deliberately not mirrored here. The Windows `.rdp` artifact is
historical and does not contain a password.

