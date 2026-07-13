# Диагностика

Сначала проверить доступность узла, systemd/Docker status, журналы без секретов, слушающие порты, маршруты и firewall. При расхождении с документацией остановиться и провести read-only аудит.

Известные случаи:

- Xray не принимает временный файл без расширения `.json`;
- nginx HTTPS на `hometele:443` конфликтует с Xray Reality;
- Telegram/Home Assistant требует маршрута `wg-home → tun79`;
- MTProto подключается с raw secret без префикса `dd`;
- после weekly apt upgrade может требоваться ручной reboot.
