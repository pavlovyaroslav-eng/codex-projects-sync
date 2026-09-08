# Remnawave dual-transport rollout — 2026-09-07

## Result

The public user address remains `hometele.com.ru:443`. Hiddify subscriptions
now contain Hysteria2 over UDP as the preferred transport and VLESS Reality
over TCP as an automatically tested fallback. Server-side direct versus
azazello routing is unchanged, so users do not select the exit server.

## hometele TCP/443

Nginx stream owns public TCP/443 and reads SNI without terminating TLS:

- `hometele.com.ru` -> Remnawave/Xray Reality on `127.0.0.1:10443`;
- `www.hometele.com.ru` and `mesh.hometele.com.ru` -> Nginx HTTPS on
  `127.0.0.1:8443`;
- unknown SNI -> closed local backend, no certificate or VPN response.

Reality uses the same local HTTPS site as its fallback target. Its private key,
short ID and all user identifiers remain root-only and are not stored in this
Wiki.

## Client profile

The Hiddify Sing-box response contains:

- selector `-> Remnawave`, default member `Auto`;
- `Auto` URL-test over exactly Hysteria2 and Reality;
- one Hysteria2 outbound and one Reality-enabled VLESS outbound;
- TUN MTU `1280`;
- the existing HomeMesh direct-bypass rules.

Users must refresh their existing subscription once. The subscription URL does
not change.

## UDP tuning

Both VPN nodes use `/etc/sysctl.d/99-hysteria2-performance.conf` with 16 MiB
maximum socket buffers, 1 MiB defaults, backlog 4096 and 16 KiB UDP minima.
The active Hysteria2 sockets show 16 MiB send/receive buffers and zero socket
drops at verification time. Amnezia on azazello remains a separate UDP service;
its container was restarted once to inherit the new 1 MiB default buffers.

## Verification

- Nginx configuration test: pass.
- Unknown SNI drop: pass.
- Reality end-to-end with selected foreign egress through azazello: pass.
- Hysteria2 end-to-end, direct and selected foreign routing: pass.
- YouTube HTTP 204, Telegram HTTP 200: pass.
- Panel, subscription service, website, certificates and Headscale: pass.
- Lightweight VPN healthcheck: zero failures.

## Post-deployment monitoring — 2026-09-08

Both complete client paths passed 40/40 application probes. A single 36 MB
download measured 20.78 Mbit/s through Hysteria2 and 13.48 Mbit/s through
Reality, compared with a 193.06 Mbit/s direct baseline on `www`.

No UDP receive/send counter increase or Hysteria2 socket drops occurred during
the load window. Separate 100-packet DF probes showed 0% loss from `www` to
hometele and 4–6% on paths involving azazello. The remaining performance risk
is therefore the external route to the foreign exit, not local UDP buffer
overflow. Full evidence and limitations are recorded in
[`vpn-monitoring-2026-09-08.md`](vpn-monitoring-2026-09-08.md).

## Rollback

- www API objects and PostgreSQL dump:
  `/root/remnawave-reality-rollouts/20260907-182732/`
- hometele Nginx:
  `/root/hometele-sni-router-rollbacks/20260907-182835/rollback.sh`
- hometele UDP sysctl:
  `/root/vpn-stability-rollbacks/20260907-182403/rollback.sh`
- azazello UDP sysctl:
  `/root/vpn-stability-rollbacks/20260907-182405/rollback.sh`

API rollback command on www:

```bash
sudo /opt/vpn-migration/scripts/rollback-reality-fallback.sh \
  /root/remnawave-reality-rollouts/20260907-182732
```
