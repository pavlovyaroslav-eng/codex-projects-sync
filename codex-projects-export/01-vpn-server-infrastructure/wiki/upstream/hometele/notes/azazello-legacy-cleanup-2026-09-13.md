# Legacy cleanup on azazello — 2026-09-13

## Scope

The cleanup removed live remnants of the retired 3x-ui stack and package/image
artifacts proven unused by the current Remnawave architecture. Existing
disaster-recovery archives and migration lock/retirement scripts were kept.

## Removed 3x-ui remnants

- the inactive `/root/3x-ui` source/build/database tree;
- old standalone 3x-ui database and maintenance scripts under `/root`;
- the obsolete five-minute `3xui-client-sync` cron and its repeatedly growing
  error log;
- stale `3xui.log`;
- inactive Fail2Ban jail, filter and action files for `3x-ipl`;
- the unused `ghcr.io/mhsanaei/3x-ui` Docker image;
- obsolete `x-ui` candidates in the local Matrix command agent and remote
  monitor service lists.

The useful BBR settings were retained unchanged. Their file was renamed from
`99-bbr-x-ui.conf` to `/etc/sysctl.d/99-bbr.conf`.

## Other unused artifacts

- unused Docker images `linuxserver/wireguard` and `ortuman/jackal` were
  removed after confirming that no container or live compose file referenced
  them;
- 27 packages already in dpkg `rc` state had their residual configuration
  purged;
- APT reported no installed packages eligible for autoremove;
- the APT download cache was cleaned.

The `amneziavpn/amneziawg-go` image was retained because the active
`amnezia-awg2` build definition references it. Current Remnawave, Amnezia,
MTProto and Certbot images were retained.

## Result

- approximately 770 MiB became available on `/`;
- filesystem usage changed from 71% to 67%;
- Fail2Ban configuration test and runtime ping passed;
- active Fail2Ban jails remain `sshd`, `recidive`, and `ufw-portscan`;
- nginx validation passed;
- `remnanode`, `amnezia-awg2` and `mtproto-telegram` stayed active with zero
  container restarts;
- Fail2Ban and the Matrix command agent were intentionally restarted after
  their configuration changes and returned to active state;
- the public VPN quick test passed;
- the removed cron/log did not reappear after the next five-minute boundary.

## Backup and rollback

Cleanup backup:

```text
/root/cleanup-backups/legacy-3x-ui-20260913-105912/
```

The directory contains the compressed file archive, checksums, dpkg state,
package list, Docker image digests, before/after disk reports and service
validation output.

Restore removed files on `azazello`:

```bash
sudo tar -C / -xzpf /root/cleanup-backups/legacy-3x-ui-20260913-105912/legacy-files.tar.gz
sudo systemctl restart fail2ban
```

Restore the two monitoring scripts separately from their `.before` copies in
the same backup directory, then restart `hometele-command-agent`. Removed
Docker images are recoverable by the exact immutable digests recorded in
`docker-images-before.json`.

Do not restore the legacy cron, jail or 3x-ui runtime unless the entire old VPN
stack is intentionally restored.

## Intentionally retained historical material

- pre-Remnawave and server recovery archives under `/root`;
- `/opt/vpn-migration/scripts/lock-legacy-services.sh`;
- `/opt/vpn-migration/scripts/retire-azazello-legacy.sh`;
- Git WIKI history and sanitized audit records.

These are rollback/safety artifacts, not active services or scheduled jobs.
