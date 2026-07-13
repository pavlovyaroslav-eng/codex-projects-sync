# Безопасная проверка состояния

Проверки должны быть read-only. Не выполнять автоматический restart, изменение firewall или TCP 443.

```bash
systemctl --failed --no-pager
ss -lntup
ip -br addr
ip route
wg show
fail2ban-client status
ufw status verbose
docker ps
```

На `hometele` дополнительно проверить `systemctl status xray postfix`, интерфейсы `tun79` и `wg-home`; на `azazello` — runtime Xray/3x-ui и контейнер `mtproto-telegram`; на `www` — `matrix-synapse`, `coturn`, `nginx`, command-agent и Synapse Admin.
