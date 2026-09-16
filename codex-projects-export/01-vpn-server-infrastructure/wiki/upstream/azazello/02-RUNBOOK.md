# 02-RUNBOOK — VPN Server

Дата актуализации: 2026-09-15
Проект: **VPN сервер**  
Назначение: короткие рабочие инструкции для проверки, ремонта и эксплуатации.

> Правило: перед опасным изменением делаем backup, после изменения — validate/test, затем restart/reload. Секреты, токены, private keys и UUID клиентов в WIKI не вставлять.

> **Текущая production-схема — Remnawave с Hysteria2 и Reality.** Разделы
> ниже про host-level Xray, `tun79`, 3x-ui и старое управление пользователями
> сохранены как исторические инструкции. Для текущих операций сначала
> использовать раздел 0 и [`REMNAWAVE-HYSTERIA2.md`](REMNAWAVE-HYSTERIA2.md).

---

## 0. Актуальная схема Remnawave

Проверить всю инфраструктуру с `www`:

```bash
sudo /opt/vpn-migration/tests/vpn-healthcheck.sh
sudo cat /opt/vpn-migration/reports/health-latest.txt
sudo systemctl list-timers vpn-healthcheck.timer vpn-deepcheck.timer
```

Проверить публичную подписку и полную маршрутизацию:

```bash
sudo /opt/vpn-migration/tests/test-public-remnawave.sh
sudo /opt/vpn-migration/tests/test-hysteria-routing.sh
sudo /opt/vpn-migration/tests/test-telegram-mtproto-route.sh
```

Измерить доступность и скорость обоих клиентских транспортов:

```bash
sudo /opt/vpn-migration/tests/monitor-vpn-transports.sh
sudo jq . /opt/vpn-migration/reports/vpn-transport-monitor-latest.json
```

Проверить входной узел `hometele` без изменения конфигурации:

```bash
sudo docker ps --filter name=remnanode
sudo nginx -t
sudo ss -lntup | egrep ':443|:10443|:8443|:52000'
sudo ss -u -a -n -p -m | grep ':443'
```

Проверить выходной узел `azazello`:

```bash
sudo docker ps --filter name=remnanode
sudo ss -lunp | egrep ':24443|:39425'
sudo ss -u -a -n -p -m | grep ':24443'
```

Рабочие признаки Hysteria2: UDP/443 и UDP/24443 слушаются, размеры `rb`/`tb`
равны 16 MiB, `d0`, а `UdpRcvbufErrors`/`UdpSndbufErrors` не растут за окно
теста. Сравнивать нужно дельту счётчиков, а не их накопленное значение.

Создать пользователя и получить ссылку:

1. Открыть `https://panel.hometele.com.ru/`.
2. Создать пользователя в разделе **Users**.
3. Назначить squad `hometele-users`.
4. Скопировать subscription URL из строки пользователя.
5. Обновить профиль в Hiddify; карточка профиля и основной селектор должны называться `Yar$$VPN`, в нём должны быть `Auto (30s)`, Hysteria2, Reality и MTU `1280`. Транспорт по умолчанию — Reality. Заголовок подписки `profile-title` задаётся как `rwEncodeBase64:Yar$$VPN`.

Обычным пользователям не назначать squad `hometele-azazello-bridge`. Полные
subscription URL, UUID и учётные данные панели в WIKI не сохранять.

Результаты контрольного измерения 2026-09-08 находятся в
[`notes/vpn-monitoring-2026-09-08.md`](notes/vpn-monitoring-2026-09-08.md).

С 2026-09-15 последнее правило серверного профиля должно быть
`CATCH_ALL_FOREIGN -> azazello-hy2`. Проверка `test-hysteria-routing.sh`
обязана показать `GENERIC_FOREIGN_EXIT_IP=91.242.163.206`; иначе общий
зарубежный трафик снова выходит напрямую через российский вход. Подробный
отчёт: [`notes/vpn-routing-recovery-2026-09-15.md`](notes/vpn-routing-recovery-2026-09-15.md).

При жалобах мобильных клиентов после сна или смены Wi-Fi/LTE не повышать MTU
без доказанной фрагментации. Сначала обновить профиль и убедиться, что выбран
`Yar$$VPN` с Reality. Xray Hysteria2 26.7.28 может удерживать
устаревшую QUIC-сессию до тайм-аута; `Auto (30s)` предназначен для сетей, где
UDP работает устойчиво.

Если YouTube работает в браузере, но не воспроизводится в мобильном приложении,
проверить наличие в свежей Sing-box-подписке точечного правила `reject` для
YouTube-доменов с `network: udp` и `port: 443`. Оно отключает только YouTube
QUIC и заставляет приложение сразу перейти на HTTPS/TCP через выбранный
транспорт. Глобально блокировать UDP/443 нельзя: на нём работает Hysteria2.
После изменения пользователь должен вручную обновить профиль и принудительно
закрыть YouTube. Разбор и откат изменения от 2026-09-15:
[`notes/youtube-mobile-quic-2026-09-15.md`](notes/youtube-mobile-quic-2026-09-15.md).

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
docker inspect -f '{{.Name}} {{.State.Status}} restarts={{.RestartCount}}' remnanode
docker inspect -f '{{.Name}} {{.State.Status}} restarts={{.RestartCount}}' amnezia-awg2
systemctl status nginx --no-pager -l || true
systemctl status fail2ban --no-pager -l || true
fail2ban-client -t
fail2ban-client status
ss -lntup | egrep ':80|:9443|:24443|:39425|:52000' || true
```

3x-ui и host-level `xray.service` удалены. Их отсутствие штатно; управление
выполняется через центральную панель Remnawave. Не восстанавливать порт 2020 и
jail `3x-ipl`.

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
systemctl status matrix-qwen-bot --no-pager -l
systemctl is-active openvpn-server@local-ai
curl -fsS http://10.93.0.10:8080/health
curl -fsS http://10.93.0.10:8080/v1/models
docker ps --filter "name=synapse-admin"
ss -lntup | egrep ':80|:443|:5349|:8008|:8080'
```

Логи агента:

```bash
journalctl -u hometele-command-agent -n 150 --no-pager
```

Логи AI bot:

```bash
journalctl -u matrix-qwen-bot -n 150 --no-pager
```

Полный rollback на DeepSeek описан в
`/opt/backups/matrix-deepseek-bot-20260801-193151/RESTORE.md`.

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

На `azazello` после удаления 3x-ui файлы jail, filter и action `3x-ipl`
удалены из `/etc/fail2ban`: их прежний logpath `/var/log/x-ui/3xipl.log`
больше не существует. Перед restart всегда выполнять `fail2ban-client -t`.
См. отчёты
[`notes/fail2ban-azazello-2026-09-13.md`](notes/fail2ban-azazello-2026-09-13.md)
и [`notes/azazello-legacy-cleanup-2026-09-13.md`](notes/azazello-legacy-cleanup-2026-09-13.md).

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
---

## 19. 2026-07-27 — Hiddify: invalid Reality public_key после `!vpn add`

### Симптом
- пользователь через Element создавался, но Hiddify отклонял профиль с `invalid public_key`;
- создание пользователя из консоли сервера не воспроизводило ошибку импорта.

### Причина
- Xray `26.3.27` выводит результат `x25519 -i` с меткой `Password (PublicKey):`;
- `/usr/local/sbin/hometele-vpn-user` распознавал только старую метку `Public key:` и формировал VLESS Reality-ссылку без параметра `pbk`.

### Что изменили
- server: `hometele`;
- file: `/usr/local/sbin/hometele-vpn-user`;
- parser поддерживает старую и новую метки Xray;
- Reality public key проверяется как 43-символьный base64url, декодирующийся в 32 байта;
- ссылка проверяется до записи клиента, поэтому при ошибке пользователь не создаётся частично;
- Xray-конфигурация, TCP 443 и Matrix-агент не перенастраивались.

### Проверка
- временный пользователь успешно создан и удалён через `/usr/local/sbin/www-hometele-vpn` на `www`;
- ссылка содержала один канонический 32-байтный `pbk`, host `hometele.com.ru`, port `443`, security `reality`;
- `xray run -test` — OK;
- `xray.service` — active;
- TCP 443 — LISTEN;
- `hometele-command-agent.service` — active;
- временный пользователь после теста отсутствует.

### Backup и откат

Backup скрипта:

```text
/usr/local/sbin/hometele-vpn-user.bak-2026-07-27-103016
```

Откат:

```bash
sudo cp -a /usr/local/sbin/hometele-vpn-user.bak-2026-07-27-103016 /usr/local/sbin/hometele-vpn-user
sudo python3 -m py_compile /usr/local/sbin/hometele-vpn-user
```

Перезапуск Xray для отката самого parser-скрипта не требуется.

---

## 20. Управляемое обновление config-audit baseline

Baseline обновляется только после того, как изменение рабочей системы описано в WIKI и обе проверки VPN завершились успешно. Ежедневный audit по-прежнему только сравнивает конфигурацию и не принимает drift автоматически.

На сервере, baseline которого нужно принять, выполнить:

```bash
sudo vpn-config-baseline-refresh
```

По умолчанию команда сама выбирает последний коммит, изменявший основную документацию Remnawave. Чтобы явно привязать baseline к проверенному коммиту WIKI:

```bash
sudo vpn-config-baseline-refresh --wiki-ref COMMIT
```

Команда выполняет следующие проверки и действия:

1. убеждается, что ветка WIKI совпадает с именем сервера, рабочее дерево чистое, а локальная и центральная ветки синхронизированы;
2. проверяет, что указанный WIKI-коммит существует и является предком текущего `HEAD`;
3. сохраняет предыдущие baseline/current и WIKI HEAD в `/opt/vpn-migration/rollback/audit-baseline-HOST-TIMESTAMP/`;
4. на `www` запускает `vpn-healthcheck.sh` и `test-vpn.sh --deep`; на VPN-узле проверяет Docker, работающий контейнер `remnanode` и `nginx -t`;
5. создаёт новый baseline, немедленно проверяет его через `vpn-config-audit check` и требует полного совпадения baseline/current;
6. записывает связь с WIKI-коммитом в `sanitized-configs/audit-baselines/HOST.wiki-ref`, создаёт отдельный Git-коммит и отправляет его в центральный репозиторий.

Откат выполняется копированием `baseline.before` из напечатанного каталога rollback на место `sanitized-configs/audit-baselines/HOST.sha256`, после чего запускается `sudo vpn-config-audit check`.

Git-команды helper всегда выполняет от владельца WIKI-репозитория. Это предотвращает появление root-owned объектов в central bare repo, даже когда сам health/audit запускается через `sudo`.

Текущее состояние `www` принято 2026-09-11 после полного health/deep check. Первый commit обновлённого эталона: `ebc3491`; резервная копия прежнего эталона: `/opt/vpn-migration/rollback/audit-baseline-20260911-193432/`.

---

## 21. Hiddify 4.1.1: `failed to start background core` на Windows

Если журнал содержит `Cannot create a file when that file already exists` для `inbound/tun[tun-in]`, это повторное создание локального `tun0`, а не отказ Remnawave/Hysteria2.

На обслуживаемом Windows-компьютере использовать ярлык:

```text
Hiddify - безопасный запуск
```

Launcher ждёт полного удаления старого TUN и выполняет не более одного clean retry. После запуска проверить один процесс Hiddify, один `tun0`, `LISTEN` на `127.0.0.1:17078` и отсутствие новой ошибки в `app.log`.

Подробности, результаты транспортных тестов, UDP tuning и диагностика Amnezia error 305: `notes/vpn-stability-2026-09-11.md`.

---

## 22. Синхронизация общей WIKI на серверные ветки

`www` хранит каноническую документацию, а ветки `hometele` и `azazello` — собственные inventory/audit-истории. Их Git-истории независимы, поэтому общий merge не используется.

Ежедневный `/usr/local/sbin/vpn-wiki-sync-cron`:

1. получает свою ветку и разрешает только безопасный fast-forward;
2. на удалённых узлах получает `origin/www`;
3. копирует только пути из `scripts/wiki-common-paths.txt`;
4. собирает host inventory, создаёт коммит и отправляет свою ветку;
5. при неизвестной дивергенции останавливается без force-push и без изменения центральной истории.

Ручная проверка:

```bash
sudo /usr/local/sbin/vpn-wiki-sync-cron
git -C /opt/vpn-server-wiki status --short
git -C /opt/vpn-server-wiki rev-list --left-right --count origin/$(hostname -s)...$(hostname -s)
```

Последняя команда должна показать `0 0`. Файлы `inventory/HOST-*` и `notes/audit/HOST-*` никогда не включать в список общей синхронизации.
