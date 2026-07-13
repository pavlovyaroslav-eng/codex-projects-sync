# 03-SELF-HEALING — VPN Server

Дата: 2026-07-04  
Проект: **VPN сервер**  
Назначение: план контроля конфигураций, Git-эталона и автоматического восстановления.

> Цель: чтобы при случайном изменении, удалении файла, поломке конфигурации или неудачном обновлении система могла обнаружить drift, показать diff и безопасно вернуть сервер к эталону.

---

## 1. Главная идея

```text
Git repo = эталонная конфигурация без секретов
   ↓
control host / www = точка управления и мониторинга
   ↓ SSH forced commands / restricted sudo
azazello, hometele, www = проверяемые серверы
   ↓
audit-only -> diff -> backup -> validate -> restore -> restart service
```

Стартовать нужно не с полного auto-restore, а с режима `audit-only`:

```text
1. собрать inventory;
2. описать эталон;
3. проверять drift;
4. присылать diff в Matrix;
5. только потом разрешить восстановление безопасных файлов.
```

---

## 2. Почему не сразу “само чинит всё”

Автоматическое восстановление опасно для:

```text
Xray Reality на 443;
3x-ui database/config;
Postfix rules;
SSH authorized_keys;
сертификатов;
WireGuard/OpenVPN ключей;
Matrix tokens;
WARP keys.
```

Поэтому уровни восстановления делим так:

| Уровень | Режим | Что делает |
|---|---|---|
| L0 | inventory-only | только собирает состояние |
| L1 | audit-only | показывает drift/diff, ничего не меняет |
| L2 | safe-restore | восстанавливает безопасные скрипты и cron после backup |
| L3 | service-restore | восстанавливает config + validate + restart service |
| L4 | disaster-restore | ручной режим восстановления из полного backup |

---

## 3. Что хранить в Git

Рекомендуемая структура repo:

```text
vpn-server-wiki/
  README-VPN-SERVER.md
  01-INVENTORY.md
  02-RUNBOOK.md
  03-SELF-HEALING.md
  CHANGELOG.md

  inventory/
    servers.yml
    ports.yml
    services.yml
    dns.yml

  policies/
    no-secrets.md
    restore-levels.md
    validation-rules.md

  server-files/
    azazello/
      etc-cron.d-server-maintenance
      opt-server-maintenance-restart-containers-and-services.sh
      opt-server-maintenance-weekly-apt-upgrade.sh
      xray-config.sanitized.json
      x-ui-inventory.sanitized.md

    hometele/
      usr-local-etc-xray-config.sanitized.json
      usr-local-sbin-hometele-vpn-user
      usr-local-sbin-hometele-vpn-ssh-wrapper
      etc-sudoers.d-hometele-vpn-user
      etc-cron.d-server-maintenance
      opt-server-maintenance-restart-containers-and-services.sh
      opt-server-maintenance-weekly-apt-upgrade.sh
      nginx-sites.sanitized.md
      postfix-main.sanitized.cf

    www/
      usr-local-bin-hometele-command-agent.py
      usr-local-sbin-www-hometele-vpn
      etc-systemd-system-hometele-command-agent.service
      etc-hometele-monitor-command-agent.sanitized.conf
      etc-cron.d-server-maintenance
      opt-server-maintenance-restart-containers-and-services.sh
      opt-server-maintenance-weekly-apt-upgrade.sh

  scripts/
    collect-inventory.sh
    audit-drift.sh
    restore-file.sh
    validate-service.sh
    matrix-report.sh
```

---

## 4. Что нельзя хранить в Git

```text
пароли;
Matrix access tokens;
DeepSeek/API tokens;
client UUID;
готовые VPN links;
Reality privateKey;
Reality shortIds, если считаем их секретами;
WARP secretKey/reserved;
WireGuard private keys;
OpenVPN private keys;
MTProto secret;
SSH private keys;
3x-ui database с клиентами и секретами;
полные файлы authorized_keys с приватными комментариями, если есть чувствительные данные.
```

Что можно хранить вместо секретов:

```text
fingerprint ключа;
наличие файла;
права доступа;
owner/group;
sha256 от sanitized версии;
шаблон с placeholder вида {{ SECRET_FROM_VAULT }}.
```

---

## 5. Что контролировать на каждом сервере

### `azazello`

```text
3x-ui service state
xray service state
nginx service state
fail2ban service state
mtproto-telegram container state
listening ports: 443, 45954, 9443, 2020, 62789
routing rules sanitized
WARP outbound presence without secret
cron maintenance files
server-maintenance scripts
```

Критичные файлы:

```text
3x-ui DB/config — только backup/sanitized inventory
Xray runtime config — sanitized inventory
/root/cert/azazello.raxla.org/ — наличие, expiry, права, без приватного ключа в Git
/opt/server-maintenance/
/etc/cron.d/server-maintenance
```

### `hometele`

```text
xray service state
nginx service state
postfix service state
fail2ban service state
openvpn/tun79 state
wireguard wg-home state
listening ports: 80, 443, 51820, 52000
VPN user manager scripts
forced SSH command chain
cron maintenance files
```

Критичные файлы:

```text
/usr/local/etc/xray/config.json — sanitized + backup before restore
/usr/local/sbin/hometele-vpn-user
/usr/local/sbin/hometele-vpn-ssh-wrapper
/etc/sudoers.d/hometele-vpn-user
/home/suazzzi/.ssh/authorized_keys — only forced command presence/fingerprint
/etc/nginx/
/etc/postfix/
/etc/fail2ban/
/etc/cron.d/server-maintenance
/opt/server-maintenance/
```

### `www`

```text
matrix-synapse service state
coturn service state
nginx service state
fail2ban service state
hometele-command-agent service state
hometele-ai service state
synapse-admin container state
listening ports: 80, 443, 5349, 8008 local, 8080 local
Matrix command list
cron maintenance files
```

Критичные файлы:

```text
/usr/local/bin/hometele-command-agent.py
/usr/local/sbin/www-hometele-vpn
/etc/systemd/system/hometele-command-agent.service
/etc/hometele-monitor/command-agent.conf — sanitized only
/var/lib/hometele-monitor/command-agent.since — state, обычно не в Git
/opt/hometele-ai/ — код можно, токены нельзя
/etc/cron.d/server-maintenance
/opt/server-maintenance/
```

---

## 6. Validation rules перед restore

### Xray

```bash
python3 -m json.tool /usr/local/etc/xray/config.json >/dev/null
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

Если используется временный файл:

```bash
TMP="/usr/local/etc/xray/config.json.tmp.json"
cp -a /usr/local/etc/xray/config.json "$TMP"
/usr/local/bin/xray run -test -config "$TMP"
```

### nginx

```bash
nginx -t
```

### Postfix

```bash
postfix check
postconf -n >/dev/null
```

### systemd unit

```bash
systemd-analyze verify /etc/systemd/system/SERVICE.service
systemctl daemon-reload
```

### sudoers

```bash
visudo -cf /etc/sudoers.d/hometele-vpn-user
```

### shell/python scripts

```bash
bash -n /path/to/script.sh
python3 -m py_compile /path/to/script.py
```

---

## 7. Restore policy

Перед восстановлением любого файла:

```text
1. проверить, что файл входит в allowlist;
2. сделать timestamp backup;
3. восстановить во временный путь;
4. проверить права owner/group/mode;
5. прогнать validate;
6. атомарно заменить файл;
7. reload/restart только нужного сервиса;
8. проверить сервис и listening port;
9. записать результат в log;
10. отправить краткий отчёт в Matrix.
```

Что можно восстанавливать автоматически на L2:

```text
/opt/server-maintenance/*.sh
/etc/cron.d/server-maintenance
/usr/local/sbin/www-hometele-vpn
/usr/local/bin/hometele-command-agent.py после python compile
systemd unit после systemd-analyze verify
```

Что только с ручным подтверждением на L3:

```text
/usr/local/etc/xray/config.json
/etc/nginx/*
/etc/postfix/*
/etc/fail2ban/*
/etc/sudoers.d/*
/home/*/.ssh/authorized_keys
3x-ui DB/config
```

Что нельзя автоперезаписывать:

```text
private keys;
cert private keys;
Matrix tokens;
WARP secret;
MTProto secret;
client UUID database;
3x-ui DB без ручного backup/restore плана.
```

---

## 8. Matrix-команды для будущего self-healing

Минимальный набор:

```text
!cfg status all
!cfg status hometele
!cfg status azazello
!cfg status www

!cfg diff all
!cfg diff hometele

!cfg backup hometele
!cfg restore hometele /usr/local/sbin/hometele-vpn-user --confirm

!cfg validate hometele xray
!cfg validate www matrix
!cfg validate azazello mtproto
```

Формат ответа:

```text
server: hometele
mode: audit-only
changed: 2
critical: 0

DRIFT:
- /usr/local/sbin/hometele-vpn-user: hash mismatch
- /etc/cron.d/server-maintenance: missing

NEXT:
!cfg restore hometele /etc/cron.d/server-maintenance --confirm
```

---

## 9. Минимальный MVP

### Этап 0 — Git/WIKI

```text
Создать repo.
Положить README + 01-INVENTORY + 02-RUNBOOK + 03-SELF-HEALING.
Не хранить секреты.
```

### Этап 1 — collect inventory

На каждом сервере собрать:

```bash
hostname -f || hostname
ip -br addr
ss -lntup
systemctl list-units --type=service --state=running --no-pager
crontab -l 2>/dev/null || true
ls -lah /etc/cron.d/ /opt/server-maintenance/ 2>/dev/null || true
```

### Этап 2 — audit-only

```text
Сравнить expected services, ports, files, sha256.
Ничего не менять.
Отчёт в Matrix.
```

### Этап 3 — backup manager

```text
Перед изменением любого файла делать backup в /var/backups/hometele-config/YYYY-MM-DD-HHMMSS/
Хранить минимум 10 последних backup.
```

### Этап 4 — safe restore

```text
Восстанавливать только безопасные скрипты и cron.
Xray/nginx/postfix только после validate и ручного confirm.
```

### Этап 5 — full restore playbook

```text
Документированный disaster recovery:
- поднять чистый сервер;
- поставить пакеты;
- восстановить конфиги;
- восстановить секреты из отдельного secure backup;
- validate;
- включить сервисы.
```

---

## 10. Рекомендуемый первый скрипт `collect-inventory.sh`

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

OUT="/tmp/vpn-inventory-$(hostname)-$(date +%F-%H%M%S).txt"

{
  echo "# HOST"
  hostname -f 2>/dev/null || hostname
  echo

  echo "# DATE"
  date -Is
  echo

  echo "# OS"
  cat /etc/os-release 2>/dev/null || true
  echo

  echo "# IP"
  ip -br addr || true
  echo

  echo "# ROUTES"
  ip route || true
  echo

  echo "# LISTEN PORTS"
  ss -lntup || true
  echo

  echo "# RUNNING SERVICES"
  systemctl list-units --type=service --state=running --no-pager || true
  echo

  echo "# FAILED SERVICES"
  systemctl --failed --no-pager || true
  echo

  echo "# CRON MAINTENANCE"
  cat /etc/cron.d/server-maintenance 2>/dev/null || true
  ls -lah /opt/server-maintenance/ 2>/dev/null || true
  echo

  echo "# FAIL2BAN"
  fail2ban-client status 2>/dev/null || true
  fail2ban-client banned 2>/dev/null || true
  echo

  echo "# DOCKER"
  docker ps 2>/dev/null || true
  echo

} | tee "$OUT"

echo "Saved: $OUT"
```

---

## 11. Правила безопасности агента

```text
1. Никакого полного root shell из Matrix.
2. Только allowlist команд.
3. Forced SSH command для удалённых действий.
4. sudo только на конкретные wrapper scripts.
5. Все действия логировать.
6. Restore только после backup.
7. Restart сервиса только если validate прошёл успешно.
8. Секреты не выводить в Matrix.
9. Логи в Matrix резать до короткого summary.
10. Для L3 действий требовать --confirm.
```

---

## 12. Ближайший практический следующий шаг

```text
1. Создать Git repo на локальной машине или приватном сервере.
2. Положить туда README и эти 3 файла.
3. Снять inventory с azazello/hometele/www.
4. Сформировать inventory/servers.yml и inventory/ports.yml.
5. Сделать первый audit-only отчёт без автоматического восстановления.
```
