# VPN Server WIKI — Git start

This repo is the living documentation base for the VPN server project.

## Files

```text
README-VPN-SERVER.md   — main mini-WIKI / source of truth
REMNAWAVE-HYSTERIA2.md — current production VPN architecture and operations
HOMEMESH-USER-ONBOARDING.md — isolated remote-computer access over Headscale
01-INVENTORY.md        — stable inventory description
02-RUNBOOK.md          — operational commands and checks
03-SELF-HEALING.md     — Git/audit/restore/self-healing plan
notes/vpn-monitoring-2026-09-08.md — latest transport and packet-loss baseline
scripts/collect-inventory.sh — safe inventory collector
```

## First install

```bash
sudo bash scripts/install-wiki-repo.sh /opt/vpn-server-wiki
```

## Collect inventory on a server

```bash
cd /opt/vpn-server-wiki
sudo ./scripts/collect-inventory.sh inventory
git add inventory
git commit -m "inventory: $(hostname -s) $(date +%F)"
```

## Safety rule

Do not commit passwords, tokens, private keys, UUIDs, MTProto secrets, Reality/WARP private keys, SSH private keys, ready VPN links, raw x-ui DB, or unsanitized config dumps.
