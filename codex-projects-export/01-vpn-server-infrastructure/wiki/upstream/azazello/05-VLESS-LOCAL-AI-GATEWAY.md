# Доступ VLESS к локальной ИИ-станции

Состояние зафиксировано 2026-08-01 после сквозной live-проверки.

## Назначение и границы

Авторизованные пользователи RU VLESS/Reality на `hometele.com.ru` могут открыть
web-интерфейс и OpenAI-совместимый API локальной ИИ-станции по адресу:

```text
http://10.93.0.10:8080/
```

Разрешён только TCP `10.93.0.10/32:8080` из VLESS inbound. Остальные приватные
адреса по-прежнему блокируются правилом Xray `geoip:private`. Порт `8080` не
публикуется на RU-сервере или `www`, для него нет DNAT или публичного nginx
proxy. На ИИ-станции UFW принимает этот порт с интерфейса `tun93` только от
`10.93.0.0/24`.

## Архитектура

```text
VLESS/Reality client
  -> hometele.com.ru:443
  -> Xray inbound in-ru-reality-443
  -> узкое routing rule: 10.93.0.10/32 TCP 8080 -> direct
  -> openvpn-client@local-ai, tun93 10.93.0.12
  -> www openvpn-server@local-ai, tun93 10.93.0.1
  -> local-ai 10.93.0.10:8080
  -> llama.cpp / qwen3-14b-q4km
```

Отдельная OpenVPN-идентичность называется `hometele-vless-gateway`; в CCD ей
закреплён адрес `10.93.0.12`. Профиль и ключи имеют права root-only.

## Конфигурационные пути

На `hometele`:

```text
/usr/local/etc/xray/config.json
/etc/openvpn/client/local-ai.conf
openvpn-client@local-ai.service
xray.service
```

На `www`:

```text
/etc/openvpn/server/local-ai.conf
/etc/openvpn/ccd-local-ai/hometele-vless-gateway
/etc/openvpn/local-ai-pki
openvpn-server@local-ai.service
```

Секретные значения VLESS, Reality, сертификаты и приватные ключи в WIKI не
копируются.

## Диагностика

На `hometele`:

```bash
systemctl status openvpn-client@local-ai xray --no-pager -l
ip address show tun93
ip route get 10.93.0.10
curl -fsS http://10.93.0.10:8080/health
curl -fsS --socks5-hostname 127.0.0.1:10808 http://10.93.0.10:8080/health
curl --compressed --socks5-hostname 127.0.0.1:10808 -I http://10.93.0.10:8080/
```

На `www`:

```bash
systemctl status openvpn-server@local-ai --no-pager -l
grep '^CLIENT_LIST' /run/openvpn-server/status-local-ai.log
```

Ожидаемые VPN-адреса: `local-ai=10.93.0.10`, `owner-laptop=10.93.0.11`,
`hometele-vless-gateway=10.93.0.12`.

Если клиентское приложение исключает LAN/private ranges из туннеля, для
`10.93.0.10/32` нужно выбрать proxy или отключить `Bypass LAN`. VLESS URL и его
UUID нельзя публиковать в тикетах, WIKI или журналах диагностики.

## Проверки после установки

- OpenVPN RU -> www: active/enabled, маршрут через `tun93`, `NRestarts=0`.
- Xray: встроенный config test успешен, порт 443 активен, `NRestarts=0`.
- Через Xray SOCKS проверены `/health`, `/`, `/v1/models` и Chat Completions.
- Активная модель: `qwen3-14b-q4km`.
- Публичный listener/DNAT для `8080` отсутствует.
- Общий Xray block для `geoip:private` сохранён сразу после узкого allow rule.

## Резервные копии и откат

```text
/opt/backups/vless-ai-route-hometele-20260801-220351/RESTORE.txt
/opt/backups/vless-ai-route-www-20260801-220351/RESTORE.txt
```

При откате сначала отключить `openvpn-client@local-ai` и восстановить Xray на
`hometele`. Восстановление PKI/CCD на `www` требуется только если нужно полностью
отменить выдачу отдельного клиентского сертификата. Перед откатом проверять
`SHA256SUMS` внутри обоих каталогов.
