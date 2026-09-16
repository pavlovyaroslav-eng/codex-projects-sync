# VPN routing recovery — 2026-09-15

## Symptom

Mobile clients intermittently failed to connect, and generic foreign sites
observed the Russian entry IP instead of the Slovak exit.

## Root cause

The active `hometele-entry-hy2` server profile ended with
`CATCH_ALL_DIRECT -> direct`. Only maintained domain and Telegram IP lists used
`azazello-hy2`; unclassified public traffic therefore exited from hometele.

The Hiddify template was not leaking public traffic locally. Its two direct
rules are scoped to HomeMesh address ranges and `ip_is_private: true`; the
first outbound is the `Yar$$VPN` selector and defaults to Reality.

## Change

The final server rule was changed to:

```text
CATCH_ALL_FOREIGN -> azazello-hy2 (tcp,udp)
```

The infrastructure-direct rule, Russian-domain direct list, DNS rule, private
and BitTorrent blocks, and IPv6 block were preserved. The source base profile
was updated so reprovisioning cannot restore the obsolete direct catch-all.

The transport monitor now uses a neutral 25 MB Cloudflare object for general
throughput. GitHub and OVH remain separate route-specific diagnostics because
their paths from azazello were substantially slower during this incident.

## Backup and rollback

Root-only backup on `www`:

```text
/opt/vpn-migration/backup/default-foreign-egress-20260915-140405/
```

It contains the complete pre-change profile, base profile, routing diff and a
compressed Remnawave database dump. Rollback:

```text
/opt/vpn-migration/rollback/default-foreign-egress-20260915-140405/restore.sh
```

No credentials, UUIDs, private keys or subscription URLs are stored here.

## Verification

- Remnawave health check: all checks passed.
- Deep VPN test: passed.
- Generic Hysteria2 egress: `91.242.163.206`.
- Selected-domain Hysteria2 egress: `91.242.163.206`.
- Telegram MTProto tests: two independent DC addresses passed.
- All 45 non-bridge profiles, including the protected synthetic test account:
  HTTP 200, valid JSON, Hysteria2 + Reality, Reality default, MTU 1280. The one
  intentionally different profile is the internal
  `bridge-hometele-azazello` account.
- Neutral-CDN sample: Hysteria2 50.71 Mbit/s, Reality 69.18 Mbit/s.
- Availability sample after correction: Hysteria2 10/10, Reality 10/10.
- UDP receive/send error deltas during the test: zero.
- Path MTU payload 1472 passed in both directions; client MTU remains 1280.
- ICMP between hometele and azazello showed 5--8.3% loss. Application probes
  passed after the correction, but this provider-path loss remains a condition
  to monitor.
- IPinfo, ipwho.is and ip-api returned `SK` / Slovakia for the exit address.
