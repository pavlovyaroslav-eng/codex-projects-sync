# Текущее состояние

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
- Git-WIKI синхронизация: `/usr/local/sbin/vpn-wiki-sync`.
