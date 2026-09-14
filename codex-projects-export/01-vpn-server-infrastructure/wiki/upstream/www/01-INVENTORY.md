# 01-INVENTORY — VPN Server

Дата: 2026-07-04  
Проект: **VPN сервер**  
Назначение: инвентаризация серверов, сервисов, портов, доменов и рабочих путей.

> В этом файле намеренно не хранятся приватные ключи, токены Matrix, пароли, client UUID, MTProto secret, Reality private key, WARP secret, SSH private keys и полные клиентские ссылки.

---

## 1. Короткая схема

```text
Клиенты VPN
   ↓
hometele — RU входная точка, видимая клиентам и провайдеру
   ↓ каскад / VPN-туннель
azazello — CZ выход наружу / интернет

www — отдельный VPS для Matrix, командного агента, AI bot и мониторинга
```

---

## 2. Серверы

| Сервер | Роль | Ключевые сервисы | Главная осторожность |
|---|---|---|---|
| `azazello` | CZ выход в интернет | Remnawave Node, Hysteria2 bridge, Amnezia AWG, MTProto, nginx, fail2ban | Не восстанавливать удалённый 3x-ui поверх Remnawave Node |
| `hometele` | RU входная точка каскада | Xray, nginx-заглушка, Postfix, fail2ban, OpenVPN, WireGuard | `443/tcp` занят Xray Reality |
| `www` | Matrix / агент / мониторинг | Synapse, Coturn, nginx, synapse-admin, command-agent, AI bot | Не давать агенту полный root shell |

---

## 3. DNS и домены

### `hometele.com.ru`

```text
A @      -> 185.71.196.110
A www    -> 185.71.196.110
A mail   -> 91.242.163.206
MX @     -> mail.hometele.com.ru
```

Назначение:

```text
hometele.com.ru       — RU входная точка / сайт-заглушка / Xray Reality
www.hometele.com.ru   — сайт-заглушка
mail.hometele.com.ru  — почта
```

Нюанс: Matrix не держим на `hometele`, потому что `443/tcp` уже занят Xray Reality.

### `azazello.raxla.org`

```text
Legacy 3x-ui удалён при переходе на Remnawave; порт 2020 не используется.
```

Управление пользователями и профилями выполняется через центральную панель
Remnawave. Старые адрес и SSH-туннель панели 3x-ui не восстанавливать.

---

## 4. `azazello`

### Роль

Чешский VPS. Основной зарубежный выход и узел Remnawave Node.

### Сервисы

```text
remnanode container — Remnawave Node 3.4.1
amnezia-awg2 container — параллельный Amnezia AWG
mtproto-telegram container — Telegram MTProto
nginx — HTTP-заглушка
fail2ban — sshd, recidive, ufw-portscan
cron maintenance
```

### Remnawave Node

```text
container: remnanode
image: remnawave/node:3.4.1
runtime: rw-core внутри контейнера
Hysteria2 bridge: 24443/udp
3x-ui/x-ui host service: removed
host-level xray service: removed
```

Публичные профили и пользователи управляются центральной панелью Remnawave.
Токены узла, UUID и клиентские параметры в WIKI не сохранять.

### Актуальные слушатели без секретов

```text
80/tcp      nginx
9443/tcp    mtproto-telegram
24443/udp   rw-core / Remnawave Node
39425/udp   amnezia-awg2
52000/tcp   SSH
```

Состояние зафиксировано 2026-09-13. Не делать вывод по старым выгрузкам 3x-ui;
проверять `docker inspect remnanode` и фактические слушатели через `ss`.

### MTProto Telegram proxy

```text
Сервер: azazello
Порт: 9443/tcp
Тип: MTProto
Контейнер: mtproto-telegram
Secret: хранится отдельно, в WIKI не вставлять
```

Рабочий нюанс:

```text
В Telegram использовать raw MTProto secret без префикса dd.
Вариант с dd зависал на “Соединение…”.
```

Проверка:

```bash
docker ps --filter "name=mtproto-telegram"
docker logs --tail=100 mtproto-telegram
ss -lntup | grep ':9443'
```

---

## 5. `hometele`

### Роль

Российский VPS. Входная точка для клиентов и провайдера. На нём работают Xray Reality, сайт-заглушка, почта и туннели каскада.

### Основные данные

```text
Домен: hometele.com.ru
IP: 185.71.196.110
SSH: 52000/tcp
Служебный пользователь: suazzzi
```

### Сервисы

```text
xray       — active, 443/tcp
nginx      — active, 80/tcp, сайт-заглушка
postfix    — почта
fail2ban   — защита
openvpn    — каскад / tun79
wireguard  — wg-home
x-ui       — не основной backend на hometele
apache2    — не используется / inactive
```

### Xray

```text
backend: xray-json
config: /usr/local/etc/xray/config.json
inbound tag: in-ru-reality-443
port: 443/tcp
protocol: VLESS Reality
flow: xtls-rprx-vision
```

Менеджер пользователей:

```bash
/usr/local/sbin/hometele-vpn-user list
/usr/local/sbin/hometele-vpn-user add NAME
/usr/local/sbin/hometele-vpn-user del NAME
```

Ограничение имени:

```text
[A-Za-z0-9_.-]{2,32}
```

### Важный нюанс Xray validate

```text
Плохо: /usr/local/etc/xray/config.json.tmp
Хорошо: /usr/local/etc/xray/config.json.tmp.json
```

Причина: Xray на hometele не определял формат временного файла без окончания `.json`.

### 443 и сертификаты

```text
443/tcp занят Xray Reality.
Нельзя просто включить nginx HTTPS на 443 — можно сломать VPN.
```

Сертификаты Let’s Encrypt:

```text
/etc/letsencrypt/archive/hometele.com.ru/cert1.pem
/etc/letsencrypt/archive/hometele.com.ru/fullchain1.pem
/etc/letsencrypt/archive/hometele.com.ru/privkey1.pem
/etc/letsencrypt/archive/hometele.com.ru/chain1.pem
```

Безопасные варианты для HTTPS сайта:

```text
1. оставить сайт-заглушку на 80/tcp;
2. вынести HTTPS на другой порт;
3. вынести сайт на другой host/VPS;
4. делать аккуратный SNI/fallback split только после backup и тестов.
```

### Каскад и туннели

```text
hometele direct IP: 185.71.196.110
Czech via tun79: 91.242.163.206
Xray SOCKS exit: 91.242.163.206
OpenVPN tun79: active
AX73 UDP: active
```

WireGuard:

```text
interface: wg-home
listen port: 51820/udp
peer allowed IPs: 10.77.77.0/24
```

### Backup

```text
/root/hometele-stable-after-dns-fix-2026-06-29-213952.tar.gz
```

---

## 6. `www` / Matrix VPS

### Роль

Отдельный VPS для Matrix/Synapse, Coturn, Synapse Admin, командного агента, AI bot и мониторинга трёх серверов.

### Сервисы

```text
matrix-synapse.service          active
coturn.service                  active
nginx.service                   active
fail2ban.service                active
hometele-command-agent.service  active
hometele-ai.service             active
synapse-admin docker container  active
```

### Порты

```text
80/tcp       nginx
443/tcp      nginx
5349/tcp     coturn / turnserver
5349/udp     coturn / turnserver
8008/tcp     matrix-synapse local 127.0.0.1 / ::1
8080/tcp     synapse-admin docker, 127.0.0.1:8080 -> 80/tcp
```

IP, замеченный в логах `turnserver`:

```text
93.183.106.203
```

### Matrix command agent

```text
service: /etc/systemd/system/hometele-command-agent.service
ExecStart: /usr/bin/python3 /usr/local/bin/hometele-command-agent.py
script: /usr/local/bin/hometele-command-agent.py
config: /etc/hometele-monitor/command-agent.conf
state: /var/lib/hometele-monitor/command-agent.since
```

Активные команды:

```text
!status [server|all]
hometele-status [server|all]
/status [server|all]

!fail2ban [server|all]
/fail2ban [server|all]

!unban IP
/unban IP

!whitelist IP
/whitelist IP

!vpn list
!vpn add NAME
!vpn del NAME
/vpn list
/vpn add NAME
/vpn del NAME
```

### Matrix AI bot

```text
service: matrix-qwen-bot.service
User/Group: matrix-qwen-bot
WorkingDirectory: /opt/matrix-qwen-bot
Config: /etc/matrix-qwen-bot/bot.env (root:matrix-qwen-bot, 0640)
State: /var/lib/matrix-qwen-bot/state.json
Назначение: приватный разговорный Matrix bot через локальную Qwen3-14B
LLM route: www tun93 10.93.0.1 -> local-ai 10.93.0.10:8080/v1
```

Старый `hometele-ai.service` (DeepSeek) отключён, но не удалён. Backup и полный
откат: `/opt/backups/matrix-deepseek-bot-20260801-193151/RESTORE.md`.

Подробности: [`04-MATRIX-QWEN-BOT.md`](04-MATRIX-QWEN-BOT.md).

### Synapse Admin

```text
container: synapse-admin
binding: 127.0.0.1:8080 -> 80/tcp
```

---

## 7. Связка Matrix -> VPN user management

```text
Matrix message on www
   ↓
hometele-command-agent.py
   ↓
/usr/local/sbin/www-hometele-vpn
   ↓ SSH 52000
suazzzi@hometele.com.ru
   ↓ forced command
/usr/local/sbin/hometele-vpn-ssh-wrapper
   ↓ sudo only one command
/usr/local/sbin/hometele-vpn-user
   ↓
edit /usr/local/etc/xray/config.json + validate + restart xray
```

Файлы на `www`:

```text
/root/.ssh/www-to-hometele-vpn
/root/.ssh/www-to-hometele-vpn.pub
/usr/local/sbin/www-hometele-vpn
/usr/local/bin/hometele-command-agent.py
/etc/systemd/system/hometele-command-agent.service
```

Файлы на `hometele`:

```text
/usr/local/sbin/hometele-vpn-user
/usr/local/sbin/hometele-vpn-ssh-wrapper
/etc/sudoers.d/hometele-vpn-user
/home/suazzzi/.ssh/authorized_keys
/usr/local/etc/xray/config.json
```

Безопасность:

```text
authorized_keys использует forced command.
suazzzi через sudo может запускать только /usr/local/sbin/hometele-vpn-user.
Полный shell Matrix-боту не выдавать.
```

---

## 8. Общий maintenance cron

На всех 3 серверах:

```text
/etc/cron.d/server-maintenance
/opt/server-maintenance/restart-containers-and-services.sh
/opt/server-maintenance/weekly-apt-upgrade.sh
/var/log/server-maintenance/
```

Расписание:

```cron
0 3 * * * root /opt/server-maintenance/restart-containers-and-services.sh
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh
```

Нюанс:

```text
После weekly apt upgrade возможен pending kernel upgrade.
Ядро само не переключится — нужен ручной reboot в удобное окно.
```

---

## 9. Keenetic / Raspberry Pi / Home Assistant

LAN:

```text
LAN: 192.168.1.0/24
Router: 192.168.1.1
PC: 192.168.1.41
```

Policy routing:

```text
Камера: 192.168.1.66 / MAC 5c:4e:ee:bc:da:61
Режим: без VPN

Raspberry/Home Assistant: 192.168.1.39 / MAC e4:5f:01:6d:68:28
Режим: через WireGuard Hometele
```

Home Assistant Telegram:

```text
Проблема была в маршрутизации wg-home 10.77.77.0/24 на hometele.
Исправление: hometele-keenetic8227-wghome-to-czech
wg-home/Keenetic 8227 -> ovpn_cz/tun79 -> Czech exit
```

Рабочий результат:

```text
External IPv4: 91.242.163.206
api.telegram.org: HTTP/2 302
Telegram bot messages work for known chat IDs
```

---

## 10. Почта

```text
Сервер: hometele
Сервис: postfix
Лог: /var/log/mail.log
DNS MX: @ -> mail.hometele.com.ru
DNS A mail: 91.242.163.206
```

Финальное подтверждение:

```text
Письмо после настройки приходило успешно.
```

Открытая задача:

```text
Проверить, добавлены ли Facebook/LinkedIn в blacklist Postfix.
Перед изменениями посмотреть текущие rules.
```

---

## 11. Что нужно уточнить/дособрать позже

```text
1. Актуальные IP всех трёх VPS после контрольной проверки.
2. Hostname каждого сервера.
3. systemd list-units по каждому серверу.
4. firewall/UFW/provider firewall по каждому серверу.
5. Sanitized копии конфигов без секретов.
6. Полная схема backup/restore.
7. Git-репозиторий эталонной конфигурации.
8. Self-healing агент: режим audit-only -> restore-on-drift.
```
