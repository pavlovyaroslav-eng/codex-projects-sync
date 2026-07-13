# Home network: Keenetic, Raspberry Pi и Home Assistant

## Цель

Направлять через VPN только Raspberry Pi 4 с Home Assistant и Telegram-ботом, сохраняя камеру и остальные домашние устройства в локальной сети.

## Устройства

- Raspberry Pi 4 / Home Assistant: IP `192.168.1.39`, MAC `e4:5f:01:6d:68:28`.
- Камера `CAMERA_aliosthings`: IP `192.168.1.66`, MAC `5c:4e:ee:bc:da:61`.

## Критические ограничения

- Через VPN должен идти только Home Assistant.
- Камеру не переводить в VPN.
- Основной AX73 не трогать; рабочая схема использует Keenetic 8227.
