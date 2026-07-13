# Безопасность и аудит

На трёх серверах используются Fail2Ban (`sshd`, `ufw-portscan`, `recidive`) и UFW. Конфигурации проверяет `/usr/local/sbin/vpn-config-audit`, данные находятся в `/etc/vpn-config-audit/`.

Рекомендуемая политика self-healing: сначала inventory и audit-only, затем проверка baseline и validation rules; restore допускается только для явно разрешённых файлов и сервисов. SSH, firewall, маршруты, туннели и критические Xray-конфигурации автоматически не восстанавливаются.
