# VPN Server Mini-WIKI

Дата сборки: 2026-07-04  
Проект: **VPN сервер**  
Назначение: короткая рабочая документация без длинных логов, картинок и отладочного шума.

> В документ намеренно не включены приватные ключи, токены Matrix, пароли, client UUID, MTProto secret, private keys Reality/WireGuard/WARP и содержимое SSH-ключей. Храним только структуру, пути, порты, команды и нюансы эксплуатации.

---

## 1. Общая схема

```text
Клиент VPN
   ↓
hometele — RU входная точка, видимая для провайдера
   ↓ VPN-туннель / каскад
azazello — CZ шлюз наружу / интернет

www — отдельный VPS для Matrix/Synapse, командного агента и мониторинга
```

### Роли серверов

| Сервер | Роль | Ключевые функции |
|---|---|---|
| `azazello` | Чехия, выход в интернет | 3x-ui/Xray, WARP outbound, VLESS Reality, Hysteria/MTProto, панель 3x-ui |
| `hometele` | Россия, входная точка для клиентов | Xray VLESS Reality на 443, сайт-заглушка, почта, VPN-каскад на Чехию, WireGuard/OpenVPN связки |
| `www` | Matrix VPS | Matrix Synapse, Coturn, Synapse Admin, командный агент, AI bot, мониторинг 3 серверов |

---

## 2. DNS и домены

### `hometele.com.ru`

Из зафиксированного рабочего состояния:

```text
A @      -> 185.71.196.110
A www    -> 185.71.196.110
A mail   -> 91.242.163.206
MX @     -> mail.hometele.com.ru
```

Примечание: `chat.hometele.com.ru`, `matrix.hometele.com.ru`, `turn.hometele.com.ru` на одном из этапов отсутствовали. Matrix был вынесен на отдельный VPS из-за конфликта с 443 портом.

### `azazello.raxla.org`

Панель 3x-ui:

```text
https://azazello.raxla.org:2020/azzzi/panel/
```

Нюанс: при SSH-туннеле на панель и открытии `http://127.0.0.1:12020/` сервер отдавал 307 на HTTPS. Рабочий доступ был через HTTPS URL панели.

---

## 3. Сервер `azazello`

### Роль

`azazello` — чешский VPS, основной шлюз “в мир”. На нём стоит 3x-ui/Xray. Через него уходит внешний трафик каскада.

### Основные компоненты

```text
3x-ui
Xray
nginx
fail2ban
Docker, если используется
MTProto proxy для Telegram
cron maintenance
```

### 3x-ui / Xray

Из проектного состояния:

```text
3x-ui: 3.2.7
Xray: 26.6.1 / актуальная версия по серверу на момент аудита
API inbound: 127.0.0.1:62789 dokodemo-door
VLESS Reality: TCP 443
Дополнительный VLESS Reality: TCP 45954
Hysteria2/Hysteria: UDP/порт по актуальному конфигу 3x-ui
```

В загруженном конфиге Xray присутствовали:

```text
inbound api        127.0.0.1:62789
inbound vless-443  0.0.0.0:443, tcp, reality
inbound vless-45954 0.0.0.0:45954, tcp, reality
inbound hysteria-443 0.0.0.0:443, hysteria, tls
```

### Routing Xray на `azazello`

Зафиксированные правила:

```text
geoip:private       -> blocked
protocol bittorrent -> blocked
RU домены           -> direct
geoip:ru            -> direct
ext:geoip_RU.dat:ru -> direct
geosite:google      -> IPv4 outbound
geosite:openai      -> WARP outbound
default tcp,udp     -> WARP outbound
198.18.0.0/16       -> direct
```

RU direct domains включали:

```text
ya.ru, yandex.ru, ozon.ru, wb.ru, wildberries.ru, mail.ru,
sberbank.ru, gosuslugi.ru, mos.ru, russianpost.ru, avito.ru,
sber.ru, vkusvill.ru, lenta.ru, rbc.ru, kinopoisk.ru,
regexp:.*\.ru$, regexp:.*\.xn--p1ai$, regexp:.*\.su$
```

### MTProto Telegram proxy

Рабочее состояние:

```text
Сервер: azazello
Порт: 9443/tcp
Тип: MTProto
Ключ в Telegram: raw secret без префикса dd
```

Важный нюанс: вариант secret с `dd` в начале добавлялся в Telegram, но не подключался. Рабочий вариант — обычный raw secret из:

```bash
cat /root/telegram-mtproto-secret.txt
```

Контейнер:

```bash
docker ps --filter "name=mtproto-telegram"
docker logs --tail=100 mtproto-telegram
docker restart mtproto-telegram
```

### Maintenance cron

Установлен общий cron обслуживания:

```text
0 3 * * * root /opt/server-maintenance/restart-containers-and-services.sh
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh
```

---

## 4. Сервер `hometele`

### Роль

`hometele` — RU VPS, видимый для клиентов и провайдера. Используется как входная точка каскадного VPN. На нём также висит сайт-заглушка и почта.

### Основные данные

```text
Домен: hometele.com.ru
IP: 185.71.196.110
SSH: port 52000
Пользователь SSH для служебных операций: suazzzi
```

### Сервисы

```text
xray          — активен, слушает 443
nginx         — активен, слушает 80, сайт-заглушка
postfix       — почта
fail2ban      — защита
openvpn       — каскад/туннели
WireGuard     — wg-home
x-ui          — на hometele не основной; фактически используется xray-json
apache2       — не используется / inactive
```

### Xray

Рабочий backend для управления клиентами:

```text
backend: xray-json
config: /usr/local/etc/xray/config.json
inbound tag: in-ru-reality-443
port: 443
protocol: VLESS Reality
flow: xtls-rprx-vision
```

Проверенный менеджер пользователей:

```bash
/usr/local/sbin/hometele-vpn-user list
/usr/local/sbin/hometele-vpn-user add NAME
/usr/local/sbin/hometele-vpn-user del NAME
```

Ограничение имени:

```text
2-32 символа: латиница, цифры, точка, тире, подчёркивание
Regex: [A-Za-z0-9_.-]{2,32}
```

### Важный нюанс Xray config test

Xray `26.3.27` на `hometele` не принимал временный файл с расширением `.tmp`:

```text
Failed to get format of /usr/local/etc/xray/config.json.tmp
```

Фикс: временный файл должен иметь окончание `.json`:

```text
/usr/local/etc/xray/config.json.tmp.json
```

После фикса тестовый пользователь успешно создавался и удалялся.

### Сертификаты и 443

Let’s Encrypt сертификат есть:

```text
/etc/letsencrypt/archive/hometele.com.ru/cert1.pem
/etc/letsencrypt/archive/hometele.com.ru/fullchain1.pem
/etc/letsencrypt/archive/hometele.com.ru/privkey1.pem
/etc/letsencrypt/archive/hometele.com.ru/chain1.pem
```

Нюанс: `443` занят Xray Reality. Простая установка сайта на HTTPS через nginx без изменения схемы сломает Xray. Безопасные варианты: оставить сайт на 80, выносить HTTPS на другой порт/хост, либо делать аккуратный SNI/fallback split.

### Каскад и туннели

Зафиксированное рабочее состояние после DNS fix:

```text
hometele direct IP: 185.71.196.110
Czech via tun79: 91.242.163.206
Xray SOCKS exit: 91.242.163.206
Xray 443 active
OpenVPN tun79 active
AX73 UDP active
fail2ban jail = 0
```

WireGuard:

```text
interface: wg-home
listen port: 51820
peer allowed IPs: 10.77.77.0/24
```

### Backup

Стабильный backup после DNS fix:

```text
/root/hometele-stable-after-dns-fix-2026-06-29-213952.tar.gz
```

### Maintenance cron

Установлен общий cron обслуживания:

```text
0 3 * * * root /opt/server-maintenance/restart-containers-and-services.sh
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh
```

---

## 5. Сервер `www` / Matrix VPS

### Роль

Отдельный VPS у того же провайдера. На нём Matrix/Synapse, Coturn, Synapse Admin, командный агент и AI bot.

### Сервисы

```text
matrix-synapse.service              active
coturn.service                      active
nginx.service                       active
fail2ban.service                    active
hometele-command-agent.service      active
hometele-ai.service                 active
Docker container: synapse-admin
```

### Порты

Из проверенного состояния:

```text
80/tcp     nginx
443/tcp    nginx
5349/tcp   coturn / turnserver
5349/udp   coturn / turnserver
8008/tcp   matrix-synapse локально 127.0.0.1 / ::1
8080/tcp   synapse-admin docker, 127.0.0.1:8080 -> 80/tcp
```

IP, замеченный в логах `turnserver`:

```text
93.183.106.203
```

### Matrix command agent

Сервис:

```text
hometele-command-agent.service
ExecStart=/usr/bin/python3 /usr/local/bin/hometele-command-agent.py
```

Файл агента:

```text
/usr/local/bin/hometele-command-agent.py
```

Конфиг агента:

```text
/etc/hometele-monitor/command-agent.conf
```

State/since файл:

```text
/var/lib/hometele-monitor/command-agent.since
```

Активные команды агента:

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

Сервис:

```text
hometele-ai.service
WorkingDirectory=/opt/hometele-ai
ExecStart=/opt/hometele-ai/venv/bin/python /opt/hometele-ai/hometele-ai.py
```

Назначение: HomeTele AI Matrix Bot через локальный Qwen3-Coder на ИИ-станции.
Команда в Element: `!ai текст вопроса`. Endpoint доступен только через
изолированный OpenVPN: `http://10.93.0.10:8080/v1`; модель
`qwen3-coder-30b-a3b-q4km`.

### Synapse Admin

Docker container:

```text
synapse-admin
127.0.0.1:8080 -> 80/tcp
```

Проверка:

```bash
docker ps --filter "name=synapse-admin"
```

### Maintenance cron

Установлен общий cron обслуживания. На `www` в список рестарта добавлены:

```text
nginx
fail2ban
coturn
matrix-synapse
Docker containers, включая synapse-admin
```

---

## 6. Matrix-команды для VPN-пользователей

### Цель

Создавать пользователей каскадного VPN на `hometele` через Matrix, не давая Matrix-боту полный root shell.

### Безопасная схема

```text
Matrix message on www
   ↓
hometele-command-agent.py
   ↓
/usr/local/sbin/www-hometele-vpn
   ↓ SSH port 52000
suazzzi@hometele.com.ru
   ↓ forced command
/usr/local/sbin/hometele-vpn-ssh-wrapper
   ↓ sudo only one command
/usr/local/sbin/hometele-vpn-user
   ↓
редактирование /usr/local/etc/xray/config.json + restart xray
```

### Файлы на `www`

```text
/root/.ssh/www-to-hometele-vpn
/root/.ssh/www-to-hometele-vpn.pub
/usr/local/sbin/www-hometele-vpn
/usr/local/bin/hometele-command-agent.py
/etc/systemd/system/hometele-command-agent.service
```

Команды проверки на `www`:

```bash
/usr/local/sbin/www-hometele-vpn list
/usr/local/sbin/www-hometele-vpn add test_matrix_001
/usr/local/sbin/www-hometele-vpn del test_matrix_001
systemctl status hometele-command-agent.service --no-pager -l
journalctl -u hometele-command-agent.service -n 120 --no-pager
```

### Файлы на `hometele`

```text
/usr/local/sbin/hometele-vpn-user
/usr/local/sbin/hometele-vpn-ssh-wrapper
/etc/sudoers.d/hometele-vpn-user
/home/suazzzi/.ssh/authorized_keys
/usr/local/etc/xray/config.json
```

`authorized_keys` содержит forced command:

```text
command="/usr/local/sbin/hometele-vpn-ssh-wrapper",no-agent-forwarding,no-X11-forwarding,no-port-forwarding,no-pty ...
```

Sudoers разрешает `suazzzi` запускать только менеджер:

```text
suazzzi ALL=(root) NOPASSWD: /usr/local/sbin/hometele-vpn-user
```

### Matrix usage

```text
!vpn list
!vpn add ivan_phone
!vpn del ivan_phone
```

При `add` бот возвращает готовую ссылку вида:

```text
vless://...@hometele.com.ru:443?type=tcp&security=reality&flow=xtls-rprx-vision&fp=chrome&sni=hometele.com.ru&sid=...&spx=%2F#NAME
```

---

## 7. Общий cron обслуживания серверов

На всех 3 серверах установлен единый набор:

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

Логи:

```bash
ls -lah /var/log/server-maintenance/
tail -n 150 /var/log/server-maintenance/restart-$(date +%F).log
tail -n 150 /var/log/server-maintenance/apt-upgrade-$(date +%F).log
```

Ручной запуск рестарта:

```bash
/opt/server-maintenance/restart-containers-and-services.sh
```

Ручной запуск обновления:

```bash
/opt/server-maintenance/weekly-apt-upgrade.sh
```

Нюанс: после `apt upgrade` может появиться `Pending kernel upgrade`. Ядро само не переключится — нужен ручной reboot в удобное окно.

---

## 8. Keenetic / Raspberry Pi / Home Assistant

### LAN

```text
LAN: 192.168.1.0/24
Router: 192.168.1.1
PC: 192.168.1.41
```

### Policy routing

```text
Камера: 192.168.1.66 / MAC 5c:4e:ee:bc:da:61
Режим: без VPN

Raspberry/Home Assistant: 192.168.1.39 / MAC e4:5f:01:6d:68:28
Режим: через WireGuard Hometele
```

### Home Assistant Telegram

Проблема была не в AX73 и не в Xray, а в маршрутизации `wg-home 10.77.77.0/24` на `hometele`.

Финальное исправление:

```text
service/script: hometele-keenetic8227-wghome-to-czech
wg-home/Keenetic 8227 -> ovpn_cz/tun79 -> Czech exit
```

Рабочий результат:

```text
External IPv4: 91.242.163.206
api.telegram.org: HTTP/2 302
Telegram bot messages work for chat IDs:
823834783, 5000088364, 988387918
```

---

## 9. Fail2Ban и управление банами

### Локальные команды

```bash
fail2ban-client status
fail2ban-client banned
fail2ban-client unban IP
fail2ban-client reload
```

### Matrix commands

```text
!fail2ban
!unban IP
!whitelist IP
```

Файл whitelist:

```text
/etc/fail2ban/jail.d/98-hometele-whitelist.local
```

Формат:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 IP
```

---

## 10. Почта

`hometele` используется для сайта-заглушки и почты. В обсуждениях фигурировали:

```text
postfix
mail.log
DNS MX @ -> mail.hometele.com.ru
A mail -> 91.242.163.206
```

Письмо после настройки приходило успешно.

Отдельная задача: пользователь просил добавить Facebook/LinkedIn в чёрный список почты. В этой mini-WIKI нет подтверждённого финального состояния этого blacklist — нужно проверить текущие Postfix rules перед изменениями.

---

## 11. Бэкапы и контроль конфигураций

### Уже есть

```text
/root/hometele-stable-after-dns-fix-2026-06-29-213952.tar.gz
```

### Целевая идея пользователя

Сделать контроль конфигураций серверов, конфигов и ключей с автоматическим восстановлением до эталонного состояния. Пользователь упоминал Bcfg2 и проект `umbrella-linux` как ориентир.

### Что важно включить в будущий self-healing

```text
/usr/local/etc/xray/config.json
/etc/nginx/
/etc/fail2ban/
/etc/postfix/
/etc/dovecot/ если используется
/etc/cron.d/server-maintenance
/opt/server-maintenance/
/usr/local/sbin/hometele-vpn-user
/usr/local/sbin/hometele-vpn-ssh-wrapper
/usr/local/sbin/www-hometele-vpn
/usr/local/bin/hometele-command-agent.py
/etc/hometele-monitor/command-agent.conf без раскрытия токенов
/root/.ssh/ служебные ключи — только fingerprint/наличие, не содержимое
3x-ui DB/config на azazello
```

---

## 12. Быстрый runbook

### Проверить 3 сервера через Matrix

```text
!status all
!fail2ban all
```

### Создать VPN-пользователя

Через Matrix:

```text
!vpn add NAME
```

Через `www`:

```bash
/usr/local/sbin/www-hometele-vpn add NAME
```

Через `hometele` напрямую:

```bash
/usr/local/sbin/hometele-vpn-user add NAME
```

### Удалить VPN-пользователя

```text
!vpn del NAME
```

```bash
/usr/local/sbin/www-hometele-vpn del NAME
/usr/local/sbin/hometele-vpn-user del NAME
```

### Проверить Xray на `hometele`

```bash
systemctl status xray --no-pager -l
ss -lntup | grep ':443'
journalctl -u xray -n 120 --no-pager
```

### Проверить Matrix на `www`

```bash
systemctl status matrix-synapse --no-pager -l
systemctl status coturn --no-pager -l
systemctl status hometele-command-agent --no-pager -l
docker ps --filter "name=synapse-admin"
ss -lntup | egrep ':80|:443|:5349|:8008|:8080'
```

### Проверить MTProto на `azazello`

```bash
docker ps --filter "name=mtproto-telegram"
docker logs --tail=100 mtproto-telegram
ss -lntup | grep ':9443'
```

### Проверить maintenance cron

```bash
cat /etc/cron.d/server-maintenance
systemctl status cron --no-pager || systemctl status crond --no-pager
ls -lah /var/log/server-maintenance/
```

---

## 13. Известные нюансы

1. **MTProto Telegram**: в Telegram использовать secret без `dd`.
2. **Xray temp config**: временный файл для проверки должен иметь расширение `.json`, иначе Xray может не определить формат.
3. **443 на hometele**: занят Xray Reality; сайт HTTPS требует аккуратной отдельной схемы.
4. **Matrix вынесен отдельно**: потому что на основных VPN-серверах 443 уже занят Xray/Reality.
5. **VPN-пользователи через Matrix**: команда безопасна через forced SSH command, без полноценного shell.
6. **После weekly upgrade**: если есть pending kernel upgrade, нужен ручной reboot.
7. **Клиентские имена VPN**: только латиница/цифры/`_ . -`, 2-32 символа.
8. **Секреты не хранить в wiki**: токены Matrix, private keys, UUID клиентов, WARP secret, Reality private key, SSH private key.

---

## 14. Что стоит добавить позже

```text
1. Актуальные IP и hostname всех 3 серверов после контрольной проверки.
2. Список всех systemd services на каждом сервере.
3. Sanitized копии важных конфигов без секретов.
4. Таблица портов firewall/UFW/провайдера.
5. Схема backup/restore.
6. Self-healing через Ansible/Bcfg2/rsync+hash/auditd.
7. Регламент обновлений и ручных reboot после kernel upgrade.
```

## Ночной server-maintenance cron

Подробная заметка: `notes/maintenance-all-servers.md`

Кратко: audit-only не перезапускает сервисы; server-maintenance — отдельный ночной cron на www, hometele и azazello.
