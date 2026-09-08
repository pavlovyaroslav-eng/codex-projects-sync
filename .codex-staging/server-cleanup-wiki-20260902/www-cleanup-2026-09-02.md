# Очистка диска www — 2026-09-02

## Цель и границы

Выполнена санкционированная очистка APT-кэша, временных файлов, journald и
ротированных логов старше 7 дней. Рабочие конфигурации, активные логи, Docker
volumes, сети, контейнеры и образы не удалялись. Matrix, nginx, coturn, SSH и
порты не изменялись.

## Сохранённое состояние

- Backup: `/var/backups/codex-cleanup-20260902T175337Z`.
- Сохранены `df`, полный список версий пакетов, manual package set, список
  активных служб, Docker state, размер journald, dry-run autoremove и diff до/после.
- 3 ротированных лога (9 055 288 байт) упакованы в `rotated-logs.tar.gz`;
  SHA-256 проверен успешно.

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

- Использовано до: 13 481 074 688 байт.
- Использовано после: 12 111 798 272 байта.
- Освобождено: 1 369 276 416 байт (1 305,8 MiB).
- APT cache: 1 164 627 968 → 0 байт.
- journald vacuum: освобождено 86,1 MiB.
- `autoremove`: 0 пакетов; состав и версии пакетов не изменились.
- Ротированных логов старше 7 дней после операции: 0.
- `dpkg --audit`: 0 строк; failed systemd units: 0.
- SSH, nginx, Matrix Synapse, coturn, command-agent, AI service и Docker
  активны; контейнер `synapse-admin` работает.
- Docker prune не выполнялся: активный образ и контейнер сохранены.

## Откат

Проверка и восстановление архивированных ротированных логов:

```text
cd /var/backups/codex-cleanup-20260902T175337Z
sudo sha256sum -c rotated-logs.tar.gz.sha256
sudo tar -xzf rotated-logs.tar.gz -C /
```

Удалённые сегменты journald и APT-кэш не восстанавливаются. Конфигурации и
пакеты не менялись; отдельный rollback служб или пакетов не требуется.
