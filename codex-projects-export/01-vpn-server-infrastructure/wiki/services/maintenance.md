# Обслуживание

Ежедневный сценарий обслуживания запускается в 03:00. По воскресеньям в 03:30 выполняется обновление пакетов. Известные пути: `/etc/cron.d/server-maintenance`, `/opt/server-maintenance/restart-containers-and-services.sh`, `/opt/server-maintenance/weekly-apt-upgrade.sh` и `/var/log/server-maintenance/`.

После обновления пакетов возможен pending kernel upgrade. Ядро не переключается автоматически: reboot выполняется вручную в согласованное окно.
