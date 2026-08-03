#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y sqlite3 zstd
install -d -m 0755 /var/lib/local-ai /var/log/local-ai
install -d -m 0700 /srv/local-ai/backups
install -o root -g root -m 0755 "${SCRIPT_DIR}/health-check.sh" /usr/local/sbin/local-ai-health-check
install -o root -g root -m 0755 "${SCRIPT_DIR}/backup-config.sh" /usr/local/sbin/local-ai-backup
install -o root -g root -m 0755 "${SCRIPT_DIR}/cleanup-local-ai.sh" /usr/local/sbin/local-ai-cleanup
install -o root -g root -m 0755 "${SCRIPT_DIR}/recover-grub.sh" /usr/local/sbin/local-ai-recover-grub
install -o root -g root -m 0755 "${SCRIPT_DIR}/update-safe.sh" /usr/local/sbin/local-ai-update-safe
install -o root -g root -m 0755 "${SCRIPT_DIR}/rollback.sh" /usr/local/sbin/local-ai-rollback
install -o root -g root -m 0755 "${SCRIPT_DIR}/test-model-profiles.sh" /usr/local/sbin/local-ai-test-models

cat >/etc/systemd/system/local-ai-health.service <<'EOF'
[Unit]
Description=Local AI read-only health check
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/usr/local/sbin/local-ai-health-check > /var/lib/local-ai/health-latest.txt 2>&1'
EOF
cat >/etc/systemd/system/local-ai-health.timer <<'EOF'
[Unit]
Description=Run Local AI health check every five minutes

[Timer]
OnBootSec=3min
OnUnitActiveSec=5min
RandomizedDelaySec=20
Persistent=true

[Install]
WantedBy=timers.target
EOF
cat >/etc/systemd/system/local-ai-cleanup.service <<'EOF'
[Unit]
Description=Clean Local AI temporary files

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/local-ai-cleanup
EOF
cat >/etc/systemd/system/local-ai-cleanup.timer <<'EOF'
[Unit]
Description=Daily Local AI temporary-file cleanup

[Timer]
OnCalendar=daily
RandomizedDelaySec=20min
Persistent=true

[Install]
WantedBy=timers.target
EOF
cat >/etc/systemd/system/local-ai-backup.service <<'EOF'
[Unit]
Description=Back up Local AI configuration and Open WebUI database

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/local-ai-backup
EOF
cat >/etc/systemd/system/local-ai-backup.timer <<'EOF'
[Unit]
Description=Weekly Local AI configuration backup

[Timer]
OnCalendar=weekly
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF

cat >/etc/logrotate.d/local-ai <<'EOF'
/var/log/local-ai/*.log {
  weekly
  rotate 8
  compress
  delaycompress
  missingok
  notifempty
  copytruncate
}
EOF

systemctl daemon-reload
systemctl enable --now local-ai-health.timer local-ai-cleanup.timer local-ai-backup.timer
echo "Operations timers installed."
