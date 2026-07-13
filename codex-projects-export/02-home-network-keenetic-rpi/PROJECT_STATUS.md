# Текущее состояние

- Keenetic использует WireGuard-туннель к `hometele.com.ru:51820`.
- Для Home Assistant настроена отдельная маршрутизация.
- Telegram API ранее не работал из-за выхода через RU IP.
- Исправление на `hometele`: отдельный service/script `hometele-keenetic8227-wghome-to-czech`, направляющий трафик `wg-home` через чешский выход `ovpn_cz/tun79`.
- После исправления Home Assistant выходил через CZ IP `91.242.163.206`, Telegram API отвечал.
- Telegram-бот «Дом в луге» работает с несколькими chat ID; команда `/sec` переключает охранную автоматизацию.
