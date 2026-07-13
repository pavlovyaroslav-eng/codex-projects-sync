# OpenVPN и WireGuard

`hometele` выполняет роль WireGuard hub `wg-home` для Keenetic/Home Assistant. Сеть `10.77.77.0/24` маршрутизируется через OpenVPN `tun79` к чешскому выходу `azazello`. PrivateKey и PresharedKey запрещено хранить в Git.

Ранее исправленная проблема Telegram в Home Assistant была связана с отсутствующим маршрутом `wg-home → tun79`; после исправления Telegram API доступен через чешский выход.
