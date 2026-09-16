# Mobile YouTube QUIC fallback — 2026-09-15

## Symptom

For an active ordinary Remnawave user, YouTube worked in a browser but not in
the mobile YouTube application. The same user's generated profile and both VPN
transports passed server-side YouTube HTTPS probes through the Slovak exit.

## Diagnosis

The application/browser split isolates the failure to the preferred transport:
the mobile application tries HTTP/3 over QUIC on UDP/443, while the browser can
continue over HTTPS/TCP. The Remnawave account, limits, two transport outbounds,
Reality default, route final and TUN MTU were valid. This was not a public
direct-route leak and MTU was kept at `1280`.

## Change

One scoped Sing-box route rule was inserted after sniffing and DNS hijacking:

```json
{
  "network": "udp",
  "port": 443,
  "domain_suffix": [
    "youtube.com",
    "youtu.be",
    "googlevideo.com",
    "ytimg.com",
    "youtubei.googleapis.com",
    "ggpht.com"
  ],
  "action": "reject"
}
```

The rule makes YouTube retry over HTTPS/TCP. It does not block unrelated QUIC
and does not match the VPN transport endpoint, so Hysteria2 remains available.
The provisioning source and public/deep tests were updated to preserve and
assert the rule.

## Backup and rollback

Root-only backup on `www`:

```text
/opt/vpn-migration/backup/youtube-quic-fallback-20260915-181020/
```

It contains the pre-change template, exact route-rule diff, apply/rollback
payloads, compressed Remnawave database dump and the previous deployed test and
provisioning scripts. Rollback:

```text
/opt/vpn-migration/backup/youtube-quic-fallback-20260915-181020/restore.sh
```

No credentials, user UUIDs or subscription URLs are stored in this note.

## Verification

- Fresh affected-user response: HTTP 200 and valid JSON.
- Account status: active.
- Generated response: one Hysteria2 and one Reality outbound.
- Main selector: `Yar$$VPN`, Reality default.
- TUN MTU: `1280`.
- YouTube QUIC fallback rules: exactly one.
- Public Remnawave test: pass.
- Deep VPN test: pass.
- Hysteria2 generic and selected-domain egress: `91.242.163.206`.
- YouTube HTTPS probe: HTTP 204.
- Telegram MTProto probes: pass.
- UDP-capable Hysteria2 was not removed or globally blocked.

## Client action

Refresh the subscription in Hiddify, verify that the selected group is
`Yar$$VPN`, then force-stop and reopen YouTube. If an old profile was imported
as a static local copy rather than as a subscription, remove only that stale
profile and import the same user URL again.
