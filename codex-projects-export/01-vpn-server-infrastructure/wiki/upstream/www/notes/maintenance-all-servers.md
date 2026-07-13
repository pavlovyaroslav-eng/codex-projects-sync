# Ночной server-maintenance cron на всех трёх серверах

Факт проекта: одинаковый ночной `server-maintenance` cron установлен на всех трёх серверах:

```text
www
hometele
azazello
```

Это отдельный механизм, не связанный с audit-only.

## Cron

```cron
0 3 * * * root /opt/server-maintenance/restart-containers-and-services.sh
30 3 * * 0 root /opt/server-maintenance/weekly-apt-upgrade.sh
```

## Файлы

```text
/etc/cron.d/server-maintenance
/opt/server-maintenance/restart-containers-and-services.sh
/opt/server-maintenance/weekly-apt-upgrade.sh
/var/log/server-maintenance/
```

## Разделение ответственности

```text
audit-only:
  проверяет hash/metadata;
  пишет audit report;
  делает Git commit/push;
  отправляет Matrix alert при DRIFT_DETECTED/AUDIT_ERROR;
  не делает restart;
  не делает reload;
  не делает restore;
  не меняет live-конфиги.

server-maintenance:
  отдельный ночной механизм обслуживания;
  может выполнять restart/reload настроенных служб и контейнеров;
  выполняет weekly apt upgrade по воскресеньям.
```

## Важный нюанс

После `weekly-apt-upgrade.sh` может появиться `Pending kernel upgrade`.
Ядро само не переключится — нужен ручной reboot в удобное окно.
