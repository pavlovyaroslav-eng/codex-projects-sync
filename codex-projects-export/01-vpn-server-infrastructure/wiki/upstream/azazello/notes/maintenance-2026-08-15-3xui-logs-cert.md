# Обслуживание 3x-ui, журналов и сертификата — 2026-08-15

Дата выполнения: 2026-08-15, Europe/Moscow.  
Узлы: `azazello`, `www`, `hometele`.

## Результат

- На `azazello` прекращено создание резервной копии базы и конфигурации 3x-ui при каждом пятиминутном запуске синхронизации.
- Накопленный каталог `/root/backup-3xui` удалён безвозвратно после проверки абсолютного пути, типа объекта, файловой системы и блокировки задания.
- На всех трёх серверах удалены архивные журналы старше 24 часов. Текущие журналы служб оставлены рабочими; для nginx и Xray сохранены записи последних 24 часов.
- Для `azazello.raxla.org` успешно выполнены staging dry-run и реальный выпуск сертификата Let's Encrypt.
- Включён `certbot.timer`; standalone-renewal проверен с pre/post-hook для временной остановки и обязательного запуска nginx.

## 1. 3x-ui на azazello

Источник задания:

```cron
*/5 * * * * root /root/sync-3xui-clients.sh
```

Файл cron `/etc/cron.d/3xui-client-sync` не отключался: синхронизация клиентов должна продолжаться. Из `/root/sync-3xui-clients.sh` удалён только блок строк, создававший каталог и копировавший в него `x-ui.db` и `config.json`.

Удалённый блок:

```diff
-BACKUP_DIR="/root/backup-3xui/$(date +%F-%H%M%S)-safe-client-sync-v3"
-mkdir -p "$BACKUP_DIR"
-
-cp -a "$DB" "$BACKUP_DIR/x-ui.db"
-cp -a "$CFG" "$BACKUP_DIR/config.json"
-
-echo "Backup saved to: $BACKUP_DIR"
```

Контрольные данные перед удалением:

- точный target: `/root/backup-3xui`;
- обычный каталог `root:root`, не symlink и не отдельная точка монтирования;
- размер: `4 515 284 888` байт;
- каталогов верхнего уровня: `16 201`.

Удаление выполнено под `flock /run/3xui-client-sync.lock`. Данные не резервировались по прямому указанию на безвозвратное удаление.

Backup изменённого скрипта для отката:

```text
/root/sync-3xui-clients.sh.pre-no-backup-20260815T104522+0300
```

SHA-256:

```text
до:    2845f2e2910c6cc9ba621de58178974344443b74ce442bd38cedbf9bfd8135c3
после: 0e9fd2ac4b4fd7d56dc704f9627cac98466c4feff2be740531fcb068cd0fd1ae
```

После очередного запуска cron в `11:25:01 MSK`:

- синтаксис скрипта корректен;
- задание выполнилось и обновило лог;
- код резервирования отсутствует;
- `/root/backup-3xui` повторно не появился.

## 2. Очистка журналов

Политика обслуживания: `journalctl --rotate` и `journalctl --vacuum-time=1d`, удаление старых rotated/compressed-файлов и сохранение последних 24 часов для крупных прикладных access-логов. Активные файлы служб не удалялись из-под процессов.

| Узел | journald до → после | `/var/log` до → после | Диск до → после |
|---|---:|---:|---:|
| `www` | 246,5 МиБ → 16,0 МиБ | 614 904 656 → 64 648 288 байт | 32% → 31% |
| `hometele` | 857,9 МиБ → 16,0 МиБ | 2 270 227 774 → 52 767 926 байт | 39% → 33% |
| `azazello` | 197,4 МиБ → 39,5 МиБ | 817 557 744 → 113 868 562 байт | 67% → 64% |

Дополнительно:

- `www`: nginx access за последние 24 часа — `9 033 952` байта; nginx выполнил reopen без перезапуска; `nginx -t` успешен.
- `hometele`: Xray access за последние 24 часа — `28 494 120` байт; применён copytruncate, Xray остался активен.
- `azazello`: журнал синхронизации 3x-ui сокращён до записей последних 24 часов; после контрольного cron — `262 983` байта.
- На `azazello` контрольный поиск после обслуживания: `0` rotated/compressed-файлов старше 24 часов.

Суммарно на корневом разделе `azazello` после удаления копий и журналов: заполнение снизилось с `94%` до `64%`, свободно около `5,9 ГиБ`.

## 3. Сертификат azazello.raxla.org

До обслуживания сертификат был просрочен с `2026-06-11`. Renewal использует `authenticator = standalone`, а TCP/80 занят nginx.

В `/etc/letsencrypt/renewal/azazello.raxla.org.conf` добавлено:

```ini
pre_hook = systemctl stop nginx
post_hook = systemctl start nginx
```

Backup renewal-конфигурации:

```text
/root/azazello.raxla.org.renewal.conf.pre-hooks-20260815T112213
```

Проверки и выпуск:

1. `nginx -t` — успешно.
2. `certbot renew --cert-name azazello.raxla.org --dry-run` — успешно.
3. Реальное принудительное обновление — успешно.
4. Nginx после каждого ACME-запуска активен, повторный `nginx -t` успешен.
5. `certbot.timer` — `enabled`, `active`.

Новый сертификат:

```text
CN: azazello.raxla.org
issuer: Let's Encrypt YR2
archive generation: cert9/fullchain9/privkey9
notBefore: 2026-08-15 07:24:14 UTC
notAfter:  2026-11-13 07:24:13 UTC
```

Приватный ключ и его содержимое в WIKI не сохранялись.

## 4. Итоговая проверка служб

- `www`: `nginx` и `matrix-synapse` — active; `nginx -t` — successful.
- `hometele`: `ssh`, `systemd-journald`, `rsyslog`, `xray` — active.
- `azazello`: `ssh`, `nginx`, `x-ui`, `systemd-journald`, `rsyslog` — active.
- На `azazello` cron 3x-ui после изменения отработал без восстановления каталога копий.

## 5. Откат

Вернуть прежний скрипт с резервированием:

```bash
sudo install -o root -g root -m 755 \
  /root/sync-3xui-clients.sh.pre-no-backup-20260815T104522+0300 \
  /root/sync-3xui-clients.sh
sudo bash -n /root/sync-3xui-clients.sh
```

Вернуть прежний renewal-конфиг и исходное состояние таймера:

```bash
sudo install -o root -g root -m 600 \
  /root/azazello.raxla.org.renewal.conf.pre-hooks-20260815T112213 \
  /etc/letsencrypt/renewal/azazello.raxla.org.conf
sudo systemctl disable --now certbot.timer
```

Удалённые каталоги 3x-ui и старые журналы локального rollback не имеют. Возможные snapshots провайдера находятся вне области этой работы. Предыдущая certbot-generation `8` сохранена в стандартном archive Let's Encrypt, но она просрочена и для рабочего отката не подходит.
