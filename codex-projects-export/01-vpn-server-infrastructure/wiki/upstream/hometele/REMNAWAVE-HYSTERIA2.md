# Remnawave + Hysteria2 infrastructure

Status date: 2026-09-08

This document describes the production replacement of the former host-level
Xray/3x-ui cascade. It intentionally contains no passwords, API tokens,
subscription identifiers, UUIDs, private keys, or client credentials.

## Architecture

```text
                           Internet
                              |
                  +-----------+-----------+
                  |                       |
              DIRECT                  AZAZELLO
          185.71.196.110            91.242.163.206
                  ^                       ^
                  |                       |
                  +------ HOMETELE -------+
                         Hysteria2 bridge
                            UDP/24443
                              ^
                              |
                +-------------+-------------+
                |                           |
       Hysteria2 / UDP/443       VLESS Reality / TCP/443
          preferred path          automatic fallback
                |                           |
                +--------- hometele.com.ru--+
                              ^
                              |
                       Hiddify `Auto`
```

The client sees one host only: `hometele.com.ru`. Hiddify automatically tests
Hysteria2 and Reality and normally prefers Hysteria2. Remnawave/Xray on
hometele selects either the local `direct` outbound or the private Hysteria2
bridge to azazello. Users never choose azazello themselves.

The private Windows overlay is separate from the proxy path:

```text
REMOTE-PC (Hiddify + Tailscale)
                |
      Tailscale/WireGuard overlay
                |
  Headscale: mesh.hometele.com.ru
                |
HOME-PC (Hiddify + Tailscale)
```

## Servers and versions

| Server | Role | Components |
|---|---|---|
| `www` (`93.183.106.203`) | Management | Remnawave Panel `3.4.3`, PostgreSQL `18.4`, Valkey `9`, Subscription Page `8.0.0`, Nginx |
| `hometele` (`185.71.196.110`) | User entry and mesh coordinator | Remnawave Node `3.4.1`, Xray-core `26.7.28` inside the node, Hysteria2 entry, Nginx, Headscale `0.29.3` |
| `azazello` (`91.242.163.206`) | Selected foreign exit | Remnawave Node `3.4.1`, Xray-core `26.7.28` inside the node, Hysteria2 bridge |

Matrix, Element, coturn and Synapse Admin on `www` were not moved and remain
independent of the VPN stack.

## DNS and HTTPS

| Name | Address | Purpose |
|---|---|---|
| `hometele.com.ru` | `185.71.196.110` | Normal web on TCP/443 and Hysteria2 on UDP/443 |
| `panel.hometele.com.ru` | `93.183.106.203` | Remnawave administration |
| `sub.hometele.com.ru` | `93.183.106.203` | Public subscription URLs |
| `mesh.hometele.com.ru` | `185.71.196.110` | Headscale reverse proxy |

The records are DNS-only. Certificates are issued by Let's Encrypt and renew
through the existing Certbot integration. The admin panel uses its native
Remnawave authentication. Do not add Nginx Basic Auth over the whole SPA: it
blocks unauthenticated `/api/auth/status` requests and leaves only the page
background visible.

## Ports

### hometele

- TCP `80`: Nginx and the ordinary website.
- TCP `443`: Nginx stream SNI router.
- TCP `127.0.0.1:10443`: Remnawave/Xray VLESS Reality backend.
- TCP `127.0.0.1:8443`: Nginx HTTPS backend for the ordinary site and Headscale.
- UDP `443`: public Hysteria2 inbound managed by Remnawave Node.
- TCP `52000`: SSH.
- TCP `127.0.0.1:8081`: Headscale API behind Nginx.
- TCP `127.0.0.1:9091`: Headscale metrics; never public.

### azazello

- UDP `24443`: private Hysteria2 bridge; firewall permits the hometele source.
- UDP `39425`: separate Amnezia service; it is not part of the Remnawave path.
- TCP `52000`: SSH.
- Existing unrelated MTProto and Amnezia services were preserved.

### www

- TCP `80`, `443`: Nginx public endpoints.
- TCP `127.0.0.1:3000-3001`: Remnawave API and metrics.
- TCP `127.0.0.1:3010`: Subscription Page.
- Existing coturn ports remain unchanged.

Remnawave Node management endpoints are not published to the whole Internet.

## Remnawave objects

- Config profiles: `hometele-entry-hy2`, `azazello-exit-hy2`.
- Internal squads: `hometele-users`, `hometele-azazello-bridge`.
- Public host shown to users: `hometele.com.ru` only.
- Connected nodes: `hometele-entry`, `azazello-exit`.
- Migrated users: 42 created, 5 collision-safe renames, 0 failures.
- Migration report: `/opt/vpn-migration/reports/migration-report.{json,md}` on `www`, mode `0600`.

Usernames, status, expiry and applicable limits were migrated. Plaintext
passwords were not collected.

## Routing

Routing is server-side and is stored as dedicated lists under:

```text
/opt/vpn-migration/configs/routing/direct-domains.json
/opt/vpn-migration/configs/routing/foreign-domains.json
/opt/vpn-migration/configs/routing/telegram-networks.json
```

Selected foreign domains include YouTube/GoogleVideo, Telegram, OpenAI,
Discord and other maintained entries. Russian services and the default
catch-all leave directly through hometele, except for explicit foreign-list
overrides. Private destinations and BitTorrent are blocked. IPv6 egress is
blocked until an explicitly tested IPv6 design is introduced.

Telegram native clients connect to MTProto data centres directly by IP, not
only by DNS name. Rule `TELEGRAM_NETWORKS` therefore sends the maintained
Telegram IPv4 ranges through `azazello-hy2` before the direct catch-all.

Verified result on 2026-09-03:

- direct egress: `185.71.196.110`;
- selected foreign egress: `91.242.163.206`;
- YouTube: HTTP `204`;
- Telegram: HTTP `200`;
- Telegram MTProto direct-IP connections to two independent data centres:
  `PASS`, with the traffic observed leaving from azazello;
- OpenAI: HTTP `403`, confirming reachability through the selected exit.

Reports on `www`:

```text
/opt/vpn-migration/reports/hysteria-routing-test.json
/opt/vpn-migration/reports/telegram-mtproto-route.json
```

## Subscriptions and Hiddify

Each user has one URL under `https://sub.hometele.com.ru/`. Never store the
full URL in Git or shared documentation. Copy it from the user row in the
Remnawave panel.

The Hiddify response rule emits native Sing-box JSON and contains one
Hysteria2 outbound, one VLESS Reality outbound and an `Auto` URL-test group.
The TUN MTU is `1280`. The client template also contains direct bypass rules
for:

```text
100.64.0.0/10
fd7a:115c:a1e0::/48
```

It enables automatic interface detection and DNS hijacking. A real Windows
Hiddify client imported and used the generated profile successfully. The
prepared Windows installer version is `4.1.1`; the installer binary is
distributed separately and is not stored in this Git repository.

## Creating a user and copying a link

1. Open `https://panel.hometele.com.ru/` and sign in with the Remnawave admin account.
2. Open **Users** and select **Create user**.
3. Set a username without spaces, limits and expiry.
4. Assign the user to `hometele-users`.
5. Create the user and use the link icon in the user row to copy the subscription URL.
6. Import that unchanged URL into Hiddify and update the profile.

Do not assign ordinary users to `hometele-azazello-bridge`.

## Headscale and Windows HomeMesh

- Public control URL: `https://mesh.hometele.com.ru`.
- Each VPN customer receives a separate Headscale user identity.
- Policy `autogroup:self` permits communication only between devices owned by
  the same user; cross-customer access is denied.
- Address pools: `100.64.0.0/10`, `fd7a:115c:a1e0::/48`.
- MagicDNS base domain: `home.mesh.hometele.com.ru`.
- SQLite database: `/opt/headscale/data/db.sqlite`.
- Metrics are loopback-only.
- Auth keys are generated only for enrolment and are never written to this repository.
- Current protected key material, when present, is root-only under `/root/`.

Windows installer: `Install-HomeMesh.ps1`. It installs the official Tailscale
client through Winget, connects it to this Headscale server and optionally
creates interface-scoped firewall rules for ping, RDP, SMB and SSH. Prefer a
single-use key file; the key is not written to the diagnostic log and can be
removed automatically after registration.

Create an isolated two-device enrolment on `hometele`:

```bash
sudo /opt/vpn-migration/scripts/create-homemesh-enrollment.sh USERNAME 2 24h
```

Export one operator-readable archive per device with
`export-homemesh-device-package.sh ENROLLMENT_DIR DEVICE_NUMBER`. Each archive
contains exactly one single-use key and is placed in
`/home/suazzzi/homemesh-outbox/` for transfer; remove it after delivery.

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-HomeMesh.ps1 -AuthKeyFile .\device-1.authkey -RemoveAuthKeyFile -AllowPing -PeerName HOME-PC
```

Full procedure: `HOMEMESH-USER-ONBOARDING.md`.

Subnet routing into a home LAN is deliberately not enabled. It is a separate,
optional phase after the two PCs can reach each other directly.

## Monitoring

Lightweight checks run every 15 minutes on `www`:

```text
vpn-healthcheck.timer
/opt/vpn-migration/reports/health-latest.txt
```

The full Hysteria2 and routing test runs daily:

```text
vpn-deepcheck.timer
/opt/vpn-migration/reports/test-vpn-latest.txt
```

Checks cover DNS, public HTTPS, certificate lifetime, panel native login API,
the subscription output, all management containers, node connectivity,
Hysteria2 transport, selective egress, overlay bypass rules and a conservative
path-MTU probe.

An on-demand transport monitor is installed on `www`:

```bash
sudo /opt/vpn-migration/tests/monitor-vpn-transports.sh
sudo jq . /opt/vpn-migration/reports/vpn-transport-monitor-latest.json
```

The test uses a protected synthetic subscription, performs repeated HTTP
availability probes through each complete VPN path, downloads the same 36 MB
official release through each transport and records only sanitized aggregate
results.

Post-deployment measurement on 2026-09-08:

| Measurement | Hysteria2 | Reality |
|---|---:|---:|
| Successful probes | 40/40 | 40/40 |
| Application-level loss | 0% | 0% |
| Average response | 0.4269 s | 0.1882 s |
| p95 response | 0.3357 s | 0.2116 s |
| Maximum response | 5.2158 s | 0.2445 s |
| Single 36 MB download | 20.78 Mbit/s | 13.48 Mbit/s |

The direct `www` baseline to the same object was 193.06 Mbit/s. This is a
single-object operational comparison, not a guaranteed subscriber line rate.
Both transports confirmed foreign egress through azazello.

The 100-packet, 1200-byte DF ICMP samples showed 0% loss from `www` to
hometele, but 4–6% loss on paths involving azazello, at approximately 54–55 ms
average RTT. During the load test, UDP receive/send error counters did not
increase and both Hysteria2 sockets retained 16 MiB buffers with socket drops
`d0`. The observed loss is therefore on the external path to azazello rather
than a Remnawave/Hysteria2 receive-buffer overflow. QUIC recovery hid it from
the 40-request application sample, but it remains the primary performance
risk for selected foreign traffic.

Detailed sanitized record:
[`notes/vpn-monitoring-2026-09-08.md`](notes/vpn-monitoring-2026-09-08.md).

## Backups

Complete pre-migration backups:

- hometele: `/root/pre-remnawave-migration-20260902-222748/` (`1.6G`, `COMPLETE`);
- www: `/root/pre-remnawave-migration-20260902-222748/` (`7.1G`, `COMPLETE`);
- azazello: `/root/pre-remnawave-migration-20260903-000001/` (`433M`, `COMPLETE`).

Headscale SQLite uses a consistent daily backup with 30-day retention under
`/root/headscale-backups/`.

## Legacy removal and rollback

The former host-level Xray service and configuration were removed from
hometele. The former x-ui data, executable and UDP/443 redirect service were
removed from azazello. The Xray-core embedded in Remnawave Node is part of the
new architecture and must not be removed.

Current targeted rollback entry points:

```text
hometele:
  /opt/vpn-migration/rollback/hometele-legacy-removal-20260903-145913/full-rollback.sh

azazello:
  /opt/vpn-migration/rollback/azazello-legacy-removal-20260903-145916/full-rollback.sh

www panel SPA authentication fix:
  /opt/vpn-migration/rollback/panel-spa-auth-20260903-150812/restore.sh

www monitoring:
  /opt/vpn-migration/rollback/monitoring-20260903-145315/restore.sh
```

Run rollback only from the named server and only after confirming which stack
must own TCP/443 and UDP/443. Full pre-migration archives remain the final
disaster-recovery source.

## Troubleshooting

### Hiddify cannot update a subscription

Run on `www`:

```bash
sudo /opt/vpn-migration/tests/test-public-remnawave.sh
```

### Hiddify connects but routing is wrong

Run on `www`:

```bash
sudo /opt/vpn-migration/tests/test-hysteria-routing.sh
sudo /opt/vpn-migration/tests/test-telegram-mtproto-route.sh
```

Then inspect the dedicated routing JSON files. Do not edit generated node
configuration inside a running container.

For speed, latency or intermittent availability complaints, run:

```bash
sudo /opt/vpn-migration/tests/monitor-vpn-transports.sh
sudo jq . /opt/vpn-migration/reports/vpn-transport-monitor-latest.json
```

Interpret the result together with destination packet loss and UDP counter
deltas. Cumulative kernel counters alone do not prove that the current test
lost packets.

If the Telegram website works but native mobile or desktop clients reconnect,
verify that `TELEGRAM_NETWORKS` is present in `hometele-entry-hy2`. Native
clients use MTProto data-centre IPs and cannot be covered by domain rules alone.

### Panel shows only a dark background

Check that `auth_basic` is not enabled for the complete panel SPA and verify:

```bash
curl -fsS https://panel.hometele.com.ru/api/auth/status | jq .
```

### Headscale coordination failure

On hometele:

```bash
sudo docker inspect -f '{{.State.Health.Status}}' headscale
curl -fsS http://127.0.0.1:8081/health
```

### Health overview

On `www`:

```bash
sudo cat /opt/vpn-migration/reports/health-latest.txt
sudo systemctl list-timers vpn-healthcheck.timer vpn-deepcheck.timer
```

## References

- Remnawave documentation: `https://docs.rw/`
- Remnawave Panel: `https://github.com/remnawave/panel`
- Remnawave Node: `https://github.com/remnawave/node`
- Headscale: `https://headscale.net/`
- Tailscale clients: `https://tailscale.com/download`
