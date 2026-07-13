# Xray и 3x-ui

Xray/Reality работает на `azazello` и `hometele`; TCP 443 нельзя занимать другими сервисами без плана миграции. На `azazello` используются direct, blocked, WARP и IPv4 outbounds; приватные сети и BitTorrent блокируются, RU-направления идут direct, а отдельные внешние сервисы — через WARP.

На `hometele` конфигурация находится в `/usr/local/etc/xray/config.json`. Перед restart обязательны backup, JSON-проверка и `xray run -test`. Пользовательские UUID и Reality private keys в документацию не включаются.
