# Правила агента

- Начинать с read-only аудита.
- Никогда не менять 443/TCP на `azazello` или `hometele` без явного задания и плана отката.
- Перед командами изменения показывать: текущая проверка, backup, команды изменения, проверка результата, rollback.
- Не удалять неизвестные правила маршрутизации, туннели `tun*`, Xray inbound/outbound или firewall rules.
- Не публиковать реальные client UUID, private keys, MTProto secret, Matrix token и почтовые credentials.
- Все изменения WIKI оформлять отдельным commit с понятным сообщением.
