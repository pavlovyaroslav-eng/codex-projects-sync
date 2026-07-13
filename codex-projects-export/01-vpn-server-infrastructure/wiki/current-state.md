# Текущее состояние

- `azazello`: Xray/3x-ui, VLESS Reality на TCP 443 и дополнительном порту, Hysteria, WARP outbound, OpenVPN/WireGuard и Telegram MTProto proxy на TCP 9443.
- `hometele`: Xray Reality на TCP 443, nginx-заглушка на TCP 80, OpenVPN `tun79`, WireGuard `wg-home`, Postfix и Fail2Ban.
- `www`: Matrix Synapse, nginx, coturn, Synapse Admin, Matrix command agent, AI bot и центральный Git-WIKI.
- На трёх серверах используются Fail2Ban и правила UFW.
- Ежедневное обслуживание запускается в 03:00; еженедельное обновление пакетов — по воскресеньям в 03:30.
- Конфигурации проверяет `vpn-config-audit`; WIKI синхронизирует серверный `vpn-wiki-sync`.

## Следующие задачи

1. Проверить актуальные IP/hostname и systemd units контрольным read-only аудитом.
2. Добавить обезличенные runtime-конфигурации и полную схему backup/restore.
3. Проверить blacklist Postfix для нежелательных отправителей до изменения правил.
4. Реализовать self-healing по этапам: inventory → audit-only → validate → ручное разрешение restore.
5. Планировать ручную перезагрузку после обновления ядра, если есть pending kernel upgrade.
