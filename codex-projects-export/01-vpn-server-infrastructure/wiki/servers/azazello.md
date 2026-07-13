# azazello

Чешский внешний шлюз VPN-каскада. Используются Xray/3x-ui с VLESS Reality, WARP outbound, Hysteria, OpenVPN/WireGuard и Telegram MTProto proxy на TCP 9443. Порт TCP 443 является критическим.

Известная особенность MTProto: Telegram использует raw secret без префикса `dd`; само значение в Git не хранится. Фактические слушатели всегда проверяются через `ss -lntup`, поскольку сохранённая конфигурация может отличаться от runtime.
