# Текущее состояние

> Актуализировано 2026-09-11. Старые строки ниже сохранены как архивный контекст; рабочая схема описана в `wiki/upstream/www/REMNAWAVE-HYSTERIA2.md`.

## Актуальная VPN-схема

- `www`: Remnawave Panel `3.4.3`, PostgreSQL, Valkey и Subscription Page.
- `hometele`: Remnawave Node `3.4.1`, Hysteria2 UDP/443 и VLESS Reality TCP/443; Headscale обслуживает доступ к удалённым компьютерам.
- `azazello`: Remnawave Node `3.4.1`, частный Hysteria2 bridge UDP/24443, MTProto и AmneziaWG UDP/39425.
- Одна Remnawave-подписка выдаёт Hysteria2 и Reality; selective routing отправляет Telegram и зарубежные назначения через `azazello`.
- На обоих VPN-узлах UDP max buffer равен 16 MiB, default buffer — 4 MiB.
- Итоговые health/deep проверки пройдены, config-audit всех трёх серверов показывает `OK_NO_CHANGES`.

## azazello

- Xray/3x-ui: VLESS Reality на TCP 443.
- Hysteria2 на UDP 46539.
- Telegram MTProto proxy в контейнере, рабочий TCP 9443.
- Для Telegram используется raw MTProto secret без префикса `dd`.

## hometele

- Xray Reality на TCP 443.
- WireGuard hub для Keenetic/Home Assistant.
- Postfix принимает почту домена и пересылает её на внешнюю почту пользователя.
- Известный стабильный backup после DNS-исправления: `/root/hometele-stable-after-dns-fix-2026-06-29-213952.tar.gz`.

## www

- Ubuntu 24.04.4 LTS.
- Matrix Synapse, Nginx, Coturn, Synapse Admin в Docker.
- Домены: `matrix.hometele.com.ru`, `chat.hometele.com.ru`, `turn.hometele.com.ru`.
- Центральный bare Git-WIKI: `/opt/git/vpn-server-wiki.git`.
- Локальная WIKI на каждом сервере: `/opt/vpn-server-wiki`.

## Общая эксплуатация

- Fail2Ban на трёх серверах: `sshd`, `ufw-portscan`, `recidive`.
- Ежедневно в 03:00 выполняется перезапуск нужных контейнеров/служб.
- По воскресеньям в 03:30 — apt update/upgrade.
- Скрипты: `/opt/server-maintenance/restart-containers-and-services.sh`, `/opt/server-maintenance/weekly-apt-upgrade.sh`.
- Аудит конфигураций: `/usr/local/sbin/vpn-config-audit`, конфиг `/etc/vpn-config-audit/`.
- Git-WIKI синхронизация: `/usr/local/sbin/vpn-wiki-sync-cron`; до push выполняются fetch/fast-forward и перенос канонических файлов из `www` по явному manifest.
- Baseline config-audit принимается через `/usr/local/sbin/vpn-config-baseline-refresh` после проверки WIKI и сервисов.
