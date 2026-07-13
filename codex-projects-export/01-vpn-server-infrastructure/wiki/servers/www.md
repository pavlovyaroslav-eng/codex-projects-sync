# www

Сервисный узел на Ubuntu 24.04: Matrix Synapse, nginx, coturn, Synapse Admin, `hometele-command-agent`, Matrix AI bot и центральный bare Git-WIKI `/opt/git/vpn-server-wiki.git`. Рабочая копия WIKI находится в `/opt/vpn-server-wiki`.

Matrix-команды управляют пользователями Xray на `hometele` через отдельный wrapper, forced command и ограниченное правило sudo. Synapse слушает локальный TCP 8008, Synapse Admin привязан к loopback TCP 8080, coturn использует TCP/UDP 5349.
