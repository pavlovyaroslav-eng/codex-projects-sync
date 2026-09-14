# Fail2Ban recovery on azazello — 2026-09-13

## Symptom

`fail2ban.service` exited with status 255. Restarting it did not help.
`fail2ban-client -t` reported:

```text
Have not found any log file for 3x-ipl jail
```

## Root cause

The legacy 3x-ui service and `/var/log/x-ui` were removed during migration to
Remnawave, but `/etc/fail2ban/jail.d/3x-ipl.conf` still had `enabled=true` and
referenced `/var/log/x-ui/3xipl.log`. Fail2Ban refuses to start when an enabled
jail has no matching log file.

## Applied change

Only the orphaned jail was disabled:

```diff
-enabled=true
+enabled=false
```

No VPN container, listener, firewall policy, SSH configuration or other jail
configuration was changed.

## Validation

- Fail2Ban 1.0.2 configuration test: successful;
- service state: active/running and enabled;
- client ping: `pong`;
- active jails: `sshd`, `recidive`, `ufw-portscan`;
- existing `ufw-portscan` ban state was restored into the firewall;
- `remnanode`, `amnezia-awg2` and `mtproto-telegram` remained running with zero
  restarts.

## Backup and rollback

Backup:

```text
/root/fail2ban-repair-azazello/20260913-093438/
```

Rollback on `azazello`:

```bash
sudo cp -a /root/fail2ban-repair-azazello/20260913-093438/3x-ipl.conf.before /etc/fail2ban/jail.d/3x-ipl.conf
sudo systemctl restart fail2ban
```

The rollback intentionally restores the broken legacy jail and is only useful
if 3x-ui and its log producer are restored at the same time.

## Follow-up cleanup

After the service recovery was verified, all three inactive `3x-ipl` files
(jail, filter and action) were removed from `/etc/fail2ban`. The configuration
test and service restart passed without them. The complete cleanup and its new
rollback archive are documented in
[`azazello-legacy-cleanup-2026-09-13.md`](azazello-legacy-cleanup-2026-09-13.md).
