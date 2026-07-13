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
