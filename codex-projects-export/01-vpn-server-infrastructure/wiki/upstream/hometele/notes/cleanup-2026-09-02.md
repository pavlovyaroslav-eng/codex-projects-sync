# Очистка диска hometele — 2026-09-02

## Цель и границы

Выполнена санкционированная очистка APT-кэша, временных файлов, journald и
ротированных логов старше 7 дней. Рабочие конфигурации, активные логи и VPN-
данные не удалялись. Firewall, SSH, маршрутизация, Xray, nginx, почта и порты
не изменялись.

## Сохранённое состояние

- Backup: `/var/backups/codex-cleanup-20260902T175258Z`.
- Сохранены `df`, полный список версий пакетов, manual package set, список
  активных служб, размер journald, dry-run autoremove и diff до/после.
- 37 ротированных логов (39 735 384 байта) упакованы в
  `rotated-logs.tar.gz`; SHA-256 проверен успешно.

## Выполненные команды

```text
journalctl --rotate
journalctl --vacuum-time=7d
apt-get -o DPkg::Lock::Timeout=120 autoremove --purge -y
apt-get clean
systemd-tmpfiles --clean
```

Ротированные файлы `/var/log` старше 7 дней отбирались только по маскам
`*.gz`, `*.xz`, `*.zst`, `*.[0-9]`, `*.[0-9][0-9]`, `*.log.*`; перед удалением
они были включены в архив и манифест backup.

## Результат

- Использовано до: 12 302 917 632 байта.
- Использовано после: 11 257 507 840 байт.
- Освобождено: 1 045 409 792 байта (997,0 MiB).
- APT cache: 732 377 088 → 0 байт.
- journald vacuum: освобождено 173,4 MiB.
- `autoremove`: 0 пакетов; состав и версии пакетов не изменились.
- Ротированных логов старше 7 дней после операции: 0.
- `dpkg --audit`: 0 строк; failed systemd units: 0.
- SSH, Xray, nginx, Postfix, Fail2Ban и OpenVPN активны; `tun79`, `awg79` и
  `wg-home` подняты.

## Откат

Проверка и восстановление архивированных ротированных логов:

```text
cd /var/backups/codex-cleanup-20260902T175258Z
sudo sha256sum -c rotated-logs.tar.gz.sha256
sudo tar -xzf rotated-logs.tar.gz -C /
```

Удалённые сегменты journald и APT-кэш не восстанавливаются. Конфигурации и
пакеты не менялись; отдельный rollback служб или пакетов не требуется.
