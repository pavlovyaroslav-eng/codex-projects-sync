# OpenCode / Cline rules for VPN Server project

Goal: allow OpenCode/Cline to edit WIKI, scripts and audit-only logic without touching live server configs directly.

## Agent may edit

```text
/opt/vpn-server-wiki/
/opt/vpn-server-wiki/scripts/
/opt/vpn-server-wiki/notes/
/opt/vpn-server-wiki/sanitized-configs/
```

## Agent must not edit directly

```text
/etc/
/usr/local/etc/
/root/
/home/*/.ssh/
/opt/git/vpn-server-wiki.git/
/var/lib/
/var/log/
```

## Live config rule

Live configs are described in WIKI/scripts first, then applied manually by a reviewed command.

OpenCode/Cline must not autonomously run:

```text
restore
restart
reload
systemctl restart
service restart
overwrite /etc configs
change private keys / tokens / secrets
```

## Audit-only stage

Allowed actions now:

```text
read hashes
compare with baseline
write report to WIKI
commit report to Git
```
