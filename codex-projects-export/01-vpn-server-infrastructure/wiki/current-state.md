# Текущее состояние

- `azazello`: Xray/3x-ui, VLESS Reality на TCP 443, Hysteria на UDP 46539, WARP outbound, OpenVPN `tun79` на UDP 21194, AmneziaWG в контейнере `amnezia-awg2` на UDP 39425 и Telegram MTProto proxy на TCP 9443. AmneziaWG обслуживает 23 peer, включая зарегистрированный межсерверный peer `hometele-cascade` (`10.8.1.2/32`). UDP 443 свободен. Тестовый `wg79test` выключен и не включён в автозапуск.
- `hometele`: Xray Reality на TCP 443, nginx-заглушка на TCP 80, OpenVPN `tun79`, AmneziaWG `awg79`, WireGuard `wg-home`, Postfix и Fail2Ban. Основной чешский outbound Xray использует AmneziaWG с исходным адресом `10.8.1.2`; OpenVPN `tun79` остаётся включённым резервом для немедленного возврата. Тестовый `wg79test` выключен и не включён в автозапуск.
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

## Аварийное переключение каскада

На `hometele` переключение меняет только `sendThrough` существующего Xray outbound и перед применением проверяет выбранный туннель и конфигурацию Xray:

```bash
sudo xray-egress-select status
sudo xray-egress-select openvpn
sudo xray-egress-select awg
```

Текущее рабочее значение — `10.8.1.2` (AmneziaWG). Резервное значение — `10.79.0.2` (OpenVPN).
