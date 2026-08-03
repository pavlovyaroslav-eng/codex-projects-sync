# Контрольная точка №3 — VPN `hometele`

Статус: подтверждён и успешно применён 2026-08-01.

## Live-аудит перед применением — 2026-08-01

- Административная PuTTY-сессия `MATRIX` указывает на `93.183.106.203`, hostname
  `www.hometele.com.ru`; публичное имя этого адреса — `matrix.hometele.com.ru`.
- На текущей системе OpenVPN и `/etc/openvpn` отсутствуют. Данные о `tun88`–`tun92`
  ниже относятся к прежнему снимку WIKI и не отражают live-состояние сервера.
- Ubuntu 24.04.4 предлагает OpenVPN `2.6.19-0ubuntu0.24.04.3` и Easy-RSA `3.1.7-2`.
- UDP 21200, `tun93` и `10.93.0.0/24` свободны. Docker использует только
  `172.17.0.0/16` и `172.18.0.0/16`.
- UFW активен: deny incoming/deny routed; публично разрешены существующие
  SSH/HTTP/HTTPS/TURN-порты. `net.ipv4.ip_forward=1`; менять sysctl не требуется.
- Точный diff: отдельный server instance `openvpn-server@local-ai`, EC PKI,
  `client-to-client`, два CN (`local-ai`, `owner-laptop`), одно новое правило
  UDP 21200. NAT, default route, DNS, nginx/Matrix, SSH и Docker не меняются.

## Что уже известно из WIKI/inventory

- На `hometele` уже работает OpenVPN 2.6.19 и несколько server instances:
  `tun88`–`tun92` в сетях `10.88.0.0/24`–`10.92.0.0/24`.
- Заняты публичные OpenVPN-порты UDP `21195`, `21196`, `21198`, `21199` и TCP
  `21197`. `tun79` — отдельный исходящий резервный каскад к `azazello`, его нельзя
  использовать как входной профиль local-ai.
- `wg-home` использует `10.77.77.0/24`, AmneziaWG — адрес `10.8.1.2`, Xray
  занимает TCP 443, nginx — TCP 80, WireGuard — UDP 51820.
- Снимок показывает существующие PKI/инстансы лишь косвенно. Перед применением
  необходимо live read-only проверить unit files, `server.conf`, `client-config-dir`,
  сертификаты, CRL, forwarding, NAT и актуальные `ss`/`ip route`/UFW.

## Применённая изолированная конфигурация

Не добавлять local-ai в `tun79` и не менять `tun88`–`tun92`. Создать отдельный
OpenVPN server instance только для удалённого управления ИИ:

| Параметр | Предложение |
|---|---|
| Unit | `openvpn-server@local-ai.service` |
| Конфигурация | `/etc/openvpn/server/local-ai.conf` |
| Протокол/порт | UDP `21200` — только если live-аудит подтвердит, что свободен |
| Интерфейс | `tun93` |
| Подсеть | `10.93.0.0/24` — только после live-проверки всех routes/Docker networks |
| Сервер | `10.93.0.1` |
| Ubuntu local-ai | статический VPN IP `10.93.0.10` |
| Удалённое устройство владельца | статический VPN IP `10.93.0.11` |
| Маршрутизация | только внутри `10.93.0.0/24`, без `redirect-gateway` |
| DNS | не push, чтобы не менять DNS клиентов |
| Доступ | `client-to-client`; только SSH/3000/8000/8080/8188 на AI |

Созданы два уникальных, независимо отзываемых сертификата: `local-ai` и
`owner-laptop`. Один `.ovpn` нельзя использовать на двух устройствах. Поскольку
live-аудит не обнаружил существующего OpenVPN PKI, создан отдельный EC PKI.

## Выполненные изменения и проверка

1. Снят timestamped backup `/etc/openvpn`, systemd unit files, UFW numbered,
   `ip rule/route`, sysctl forwarding и PKI metadata без вывода private keys.
2. Подтверждены свободные `21200/udp`, `10.93.0.0/24` и имя `tun93`.
3. Созданы и подписаны два уникальных сертификата; ключи имеют root-only ACL.
4. Создан `local-ai.conf` без NAT/redirect-gateway и с отдельным CCD.
5. Добавлено одно именованное UFW allow-правило для `21200/udp`; существующие
   правила и маршруты сохранены.
6. Запущен только новый instance; nginx сохранил состояние `active`, SSH и Docker
   не перезапускались.
7. На Ubuntu установлен OpenVPN client profile с mode `0600`, включён
   `openvpn-client@hometele-local-ai.service` и UFW allow from `10.93.0.0/24`
   к портам 22/3000/8000/8080/8188.
8. Windows-профиль владельца подключён как `.11`; SSH, llama.cpp health и Open
   WebUI health по `.10` проверены. Default route и DNS не менялись.
9. Перезапуск Ubuntu VPN-client успешно вернул `.10`; обе стороны включены в
   автозагрузку. AI не публиковался через DNAT в интернет.

Backup: `/var/backups/openvpn-local-ai-20260801T050342Z`. Первичный запуск
откатился автоматически после отсутствующего `dh none`; затем конфигурация была
исправлена и применена повторно. Итоговый server instance — `enabled/active`.

Временные серверные `.ovpn` exports удалены после установки обоих клиентов.
Рабочие профили остаются только в защищённых хранилищах клиентов; private
материал не записывался в этот репозиторий.

## Откат

```text
systemctl disable --now openvpn-server@local-ai
ufw delete <точный номер правила 21200/udp>
```

Затем удалить только созданные `local-ai.conf`, CCD-записи и сертификаты после
их отзыва; восстановить backup затронутых файлов и перезагрузить UFW. Не выполнять
`ufw reset`, не останавливать общий `openvpn`, Xray, WireGuard или `tun79`.

## Решение владельца

Владелец отдельно подтвердил live-изменение `hometele` 2026-08-01. Контрольная
точка закрыта после успешной проверки сервера, Ubuntu-клиента, Windows-клиента,
маршрутов и AI endpoint.
