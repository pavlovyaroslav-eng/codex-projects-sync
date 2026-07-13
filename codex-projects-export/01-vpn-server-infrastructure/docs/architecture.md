# Архитектура

```text
Домашние устройства / Keenetic
          |
          | WireGuard
          v
      hometele (RU)
          |
          | VPN/Xray/OpenVPN routes
          v
      azazello (CZ) ---> внешний интернет

www:
- Matrix/Synapse
- Nginx TLS reverse proxy
- Coturn
- Central Git-WIKI
```

`www` обслуживает коммуникации и документацию, а `hometele` и `azazello` сохраняют рабочую VPN-цепочку.
