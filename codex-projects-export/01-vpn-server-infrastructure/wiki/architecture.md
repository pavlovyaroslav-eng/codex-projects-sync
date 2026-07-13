# Архитектура

Инфраструктура состоит из внешнего шлюза `azazello`, российского входного узла `hometele` и сервисного узла `www`.

```text
VPN-клиенты → hometele (RU вход) → OpenVPN tun79/каскад → azazello (CZ выход)
Keenetic/Home Assistant → WireGuard wg-home → hometele → tun79 → azazello
www → Matrix command agent → ограниченный SSH wrapper → управление Xray на hometele
```

На `azazello` Xray/3x-ui маршрутизирует RU-домены напрямую, OpenAI через WARP и остальной трафик согласно runtime-конфигурации. На `hometele` TCP 443 занят VLESS Reality; nginx остаётся на TCP 80. `www` размещает Matrix Synapse, nginx, coturn, Synapse Admin, командного агента и центральный bare Git-WIKI.

Матрица управления VPN ограничена forced command и отдельной sudo-командой; полный shell боту не предоставляется. Любые изменения TCP 443, маршрутов и туннелей требуют backup, проверки и плана отката.
