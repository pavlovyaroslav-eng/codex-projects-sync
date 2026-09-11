# Базовый runbook

## Проверка без изменений

```bash
hostnamectl
uptime
systemctl --failed
ss -lntup
ufw status verbose
fail2ban-client status
ip route
ip rule
wg show
```

Для Xray/3x-ui, Matrix, Nginx, Postfix и Docker использовать только локальные read-only проверки до любых действий.

## Перед изменением

1. Скопировать изменяемый файл с датой.
2. Проверить синтаксис.
3. Применить reload, если он возможен, вместо restart.
4. Проверить порты, маршруты и внешний доступ.
5. Зафиксировать изменение в WIKI и Git.

## Hiddify 4.1.1 на обслуживаемом Windows-компьютере

При `failed to start background core` вместе с `Cannot create a file when that file already exists` не менять серверы: это повторное создание локального `tun0`.

Использовать ярлык `Hiddify - безопасный запуск`. Он сохраняет уже здоровое соединение, а при зависшем старте ждёт удаления TUN и выполняет один clean retry.

```powershell
Get-Process Hiddify
Get-NetAdapter -Name tun0
Get-NetTCPConnection -State Listen -LocalAddress 127.0.0.1 -LocalPort 17078
```

## Git-WIKI и config baseline

Штатная синхронизация на каждом сервере:

```bash
sudo /usr/local/sbin/vpn-wiki-sync-cron
```

Скрипт сначала получает свою ветку и допускает только fast-forward. На `hometele` и `azazello` он копирует канонические файлы из `origin/www` по `scripts/wiki-common-paths.txt`; собственные `inventory/` и `notes/audit/` не перезаписываются.

```bash
git -C /opt/vpn-server-wiki status --short
git -C /opt/vpn-server-wiki rev-list --left-right --count origin/$(hostname -s)...$(hostname -s)
```

Ожидаемый результат: чистой статус и `0 0`.

Принять документированный baseline:

```bash
sudo /usr/local/sbin/vpn-config-baseline-refresh
```

Helper сохраняет прежний baseline, проверяет WIKI/remote, выполняет health/deep на `www` либо локальный node preflight, создаёт эталон и сразу требует `OK_NO_CHANGES`.
