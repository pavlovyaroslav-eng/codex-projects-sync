# 02-RUNBOOK — VPN Server

Дата: 2026-07-04  
Проект: **VPN сервер**  
Назначение: короткие рабочие инструкции для проверки, ремонта и эксплуатации.

> Правило: перед опасным изменением делаем backup, после изменения — validate/test, затем restart/reload. Секреты, токены, private keys и UUID клиентов в WIKI не вставлять.

---

## 1. Быстрый статус через Matrix

```text
!status all
!fail2ban all
```

По одному серверу:

```text
!status hometele
!status azazello
!status www

!fail2ban hometele
!fail2ban azazello
!fail2ban www
```

---

## 2. VPN-пользователи через Matrix

Создать:

```text
!vpn add NAME
```

Удалить:

```text
!vpn del NAME
```

Список:

```text
!vpn list
```

Правила имени:

```text
2-32 символа
латиница, цифры, точка, тире, подчёркивание
Regex: [A-Za-z0-9_.-]{2,32}
```

---

## 3. VPN-пользователи через `www`

```bash
/usr/local/sbin/www-hometele-vpn list
/usr/local/sbin/www-hometele-vpn add test_matrix_001
/usr/local/sbin/www-hometele-vpn del test_matrix_001
```

Проверка агента:

```bash
systemctl status hometele-command-agent.service --no-pager -l
journalctl -u hometele-command-agent.service -n 120 --no-pager
```

---

## 4. VPN-пользователи напрямую на `hometele`

```bash
/usr/local/sbin/hometele-vpn-user list
/usr/local/sbin/hometele-vpn-user add NAME
/usr/local/sbin/hometele-vpn-user del NAME
```

После операций проверить Xray:

```bash
systemctl status xray --no-pager -l
journalctl -u xray -n 120 --no-pager
ss -lntup | grep ':443'
```

---

## 5. Перед любым изменением Xray на `hometele`

Сделать backup:

```bash
set -e
TS="$(date +%F-%H%M%S)"
cp -a /usr/local/etc/xray/config.json "/usr/local/etc/xray/config.json.bak-$TS"
ls -lh "/usr/local/etc/xray/config.json.bak-$TS"
```

Проверить JSON:

```bash
python3 -m json.tool /usr/local/etc/xray/config.json >/dev/null && echo 'JSON OK'
```

Проверить Xray config:

```bash
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

Если делается временный файл, использовать окончание `.json`:

```bash
TMP="/usr/local/etc/xray/config.json.tmp.json"
cp -a /usr/local/etc/xray/config.json "$TMP"
/usr/local/bin/xray run -test -config "$TMP"
```

---

## 6. Проверить Xray на `hometele`

```bash
systemctl status xray --no-pager -l
ss -lntup | grep ':443'
journalctl -u xray -n 120 --no-pager
```

Проверить внешний IP через локальный SOCKS, если настроен:

```bash
curl -4 --max-time 10 ifconfig.me ; echo
```

---

## 7. Проверить каскад `hometele -> azazello`

```bash
ip addr show tun79 2>/dev/null || true
ip route | sed -n '1,120p'
ss -lntup | egrep ':443|:51820|:52000' || true
systemctl status openvpn* --no-pager -l || true
wg show 2>/dev/null || true
```

Ожидаемые признаки из рабочего состояния:

```text
Xray 443 active
OpenVPN tun79 active
wg-home exists
Czech exit IP: 91.242.163.206
```

---

## 8. Проверить `azazello`

```bash
systemctl status xray --no-pager -l || true
systemctl status x-ui --no-pager -l || true
systemctl status nginx --no-pager -l || true
systemctl status fail2ban --no-pager -l || true
ss -lntup | egrep ':443|:45954|:9443|:2020|:62789' || true
journalctl -u xray -n 120 --no-pager || true
```

3x-ui панель:

```text
https://azazello.raxla.org:2020/azzzi/panel/
```

---

## 9. Проверить MTProto на `azazello`

```bash
docker ps --filter "name=mtproto-telegram"
docker logs --tail=100 mtproto-telegram
ss -lntup | grep ':9443'
```

Перезапуск:

```bash
docker restart mtproto-telegram
sleep 3
docker ps --filter "name=mtproto-telegram"
docker logs --tail=80 mtproto-telegram
```

Нюанс:

```text
В Telegram-клиент вставлять raw secret без префикса dd.
```

---

## 10. Проверить Matrix на `www`

```bash
systemctl status matrix-synapse --no-pager -l
systemctl status coturn --no-pager -l
systemctl status hometele-command-agent --no-pager -l
systemctl status hometele-ai --no-pager -l
docker ps --filter "name=synapse-admin"
ss -lntup | egrep ':80|:443|:5349|:8008|:8080'
```

Логи агента:

```bash
journalctl -u hometele-command-agent -n 150 --no-pager
```

Логи AI bot:

```bash
journalctl -u hometele-ai -n 150 --no-pager
```

---

## 11. Fail2Ban

Статус:

```bash
fail2ban-client status
fail2ban-client banned
```

Разбанить IP:

```bash
fail2ban-client unban IP
```

Перечитать конфиг:

```bash
fail2ban-client reload
```

Whitelist файл:

```text
/etc/fail2ban/jail.d/98-hometele-whitelist.local
```

Формат:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 IP
```

Matrix-команды:

```text
!fail2ban
!unban IP
!whitelist IP
```

---

## 12. Maintenance cron

Проверка:

```bash
cat /etc/cron.d/server-maintenance
systemctl status cron --no-pager || systemctl status crond --no-pager
ls -lah /var/log/server-maintenance/
```

Логи за сегодня:

```bash
tail -n 150 /var/log/server-maintenance/restart-$(date +%F).log 2>/dev/null || true
tail -n 150 /var/log/server-maintenance/apt-upgrade-$(date +%F).log 2>/dev/null || true
```

Ручной запуск рестарта:

```bash
/opt/server-maintenance/restart-containers-and-services.sh
```

Ручной запуск обновления:

```bash
/opt/server-maintenance/weekly-apt-upgrade.sh
```

После обновлений проверить pending reboot:

```bash
[ -f /var/run/reboot-required ] && cat /var/run/reboot-required || echo 'No reboot-required flag'
[ -f /var/run/reboot-required.pkgs ] && cat /var/run/reboot-required.pkgs || true
```

---

## 13. Почта на `hometele`

Проверка Postfix:

```bash
systemctl status postfix --no-pager -l
postconf -n
ss -lntup | egrep ':25|:465|:587|:993|:995' || true
tail -n 120 /var/log/mail.log
```

Проверить DNS логически:

```bash
dig +short MX hometele.com.ru
dig +short A mail.hometele.com.ru
```

Перед добавлением blacklist:

```bash
grep -RniE 'facebook|linkedin|sender_access|check_sender_access|reject_sender' /etc/postfix /etc/postfix* 2>/dev/null || true
postconf -n | grep -Ei 'smtpd_sender_restrictions|sender_access|header_checks|body_checks' || true
```

---

## 14. 443 на `hometele`: нельзя ломать

Перед любыми действиями с nginx/HTTPS:

```bash
ss -lntup | egrep ':80|:443'
systemctl is-active nginx 2>/dev/null && echo 'nginx active' || echo 'nginx not active'
systemctl is-active xray 2>/dev/null && echo 'xray active' || echo 'xray not active'
```

Запрет:

```text
Не запускать nginx HTTPS на 443 поверх Xray Reality.
```

Безопасные варианты:

```text
1. nginx только 80/tcp;
2. HTTPS на другом порту;
3. отдельный домен/VPS;
4. SNI/fallback split только после backup и теста.
```

---

## 15. Emergency: Xray не стартует на `hometele`

1. Посмотреть ошибку:

```bash
journalctl -u xray -n 200 --no-pager
```

2. Проверить JSON:

```bash
python3 -m json.tool /usr/local/etc/xray/config.json >/dev/null
```

3. Найти свежий backup:

```bash
ls -lt /usr/local/etc/xray/config.json.bak-* 2>/dev/null | head -10
```

4. Восстановить последний рабочий backup вручную:

```bash
cp -a /usr/local/etc/xray/config.json.bak-YYYY-MM-DD-HHMMSS /usr/local/etc/xray/config.json
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
systemctl restart xray
systemctl status xray --no-pager -l
```

---

## 16. Emergency: Matrix-команды не работают

На `www`:

```bash
systemctl status hometele-command-agent --no-pager -l
journalctl -u hometele-command-agent -n 200 --no-pager
```

Проверить wrapper до hometele:

```bash
/usr/local/sbin/www-hometele-vpn list
```

Если SSH/wrapper сломан:

```bash
ssh -i /root/.ssh/www-to-hometele-vpn -p 52000 suazzzi@hometele.com.ru list
```

Проверить forced command на `hometele`:

```bash
grep -n 'hometele-vpn-ssh-wrapper' /home/suazzzi/.ssh/authorized_keys
cat /etc/sudoers.d/hometele-vpn-user
```

---

## 17. Формат записи изменений в WIKI

Каждое важное изменение добавлять в конец README или отдельный CHANGELOG:

```markdown
## YYYY-MM-DD — короткое название изменения

### Что изменили
- ...

### Где
- server: `...`
- files: `...`
- services: `...`

### Проверка
```bash
команда проверки
```

### Результат
```text
что считается рабочим результатом
```

### Нюанс
- что не забыть в следующий раз
```

---

## 18. Правило для будущей работы с ChatGPT

```text
После каждого важного изменения в проекте просить готовый блок для WIKI.
Формат: короткий Markdown без логов, без скриншотов, без секретов.
```
