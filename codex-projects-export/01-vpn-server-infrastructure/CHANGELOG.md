# Changelog — VPN server infrastructure

## 2026-09-11

- Новая схема Remnawave проверена: Hysteria2 и VLESS Reality, selective routing, Telegram, YouTube, панель и подписки работают.
- На `hometele` и `azazello` default UDP socket buffers увеличены с 1 до 4 MiB; после нагрузочной проверки новые `UdpRcvbufErrors` не появились.
- Исправлена Git-WIKI синхронизация: `fetch` и безопасный fast-forward выполняются до inventory/push, неизвестная дивергенция не перезаписывается.
- Общая документация из ветки `www` доставляется на независимые ветки узлов по `scripts/wiki-common-paths.txt` без перезаписи host-specific audit/inventory.
- Устранены смешанные владельцы central bare Git; Git-операции baseline helper выполняются от штатного владельца репозитория.
- Baseline `www`, `hometele` и `azazello` обновлены после health/deep или node preflight; итоговый статус всех трёх — `OK_NO_CHANGES`.
- Для локальной ошибки Hiddify `failed to start background core` создан safe-start launcher с ожиданием удаления stale `tun0` и одним clean retry.
- Amnezia error 305 локализована в SSH management-доступе; рабочий порт управления — TCP/52000, AmneziaWG продолжает работать на UDP/39425.

## 2026-07-18

- Основной каскадный outbound Xray на `hometele` переведён с OpenVPN `tun79` на существующий AmneziaWG-сервер `azazello`; OpenVPN оставлен включённым резервом.
- На `azazello` зарегистрирован постоянный межсерверный peer `hometele-cascade` (`10.8.1.2/32`) без перезапуска рабочего контейнера и других peer.
- Добавлен приоритетный сторож `amnezia-hometele-peer-guard`: проверка каждые 30 секунд и автоматическое восстановление peer в конфигурации, таблице клиентов и live-интерфейсе после перегенерации.
- На `hometele` установлены userspace-клиент AmneziaWG, безопасное source-based routing только для `10.8.1.2` и проверяемый переключатель `xray-egress-select` для быстрого отката на OpenVPN.
- Проверены handshake, MTU 1280, выход через IP `azazello`, HTTP 204 YouTube, передача трафика через Xray и работоспособность резервного OpenVPN.
- Выполнен read-only аудит MTU/MSS, маршрутизации и производительности OpenVPN `tun79` между `hometele` и `azazello`.
- Подтверждено, что запросы к Яндексу выходят напрямую с российского IP, а captcha связана не с чешской маршрутизацией.
- Без переключения Xray поднят изолированный `wg79test`; ранний тест показал около 129 Мбит/с в направлении из Чехии и 88 Мбит/с в направлении из России против примерно 33 Мбит/с через OpenVPN.
- Повторные тесты прямого WireGuard на UDP 46540 и 21195 обрывались после первых пакетов; продакшен-переключение отменено как нестабильное.
- Зафиксирован и устранён инцидент с ошибочным `ip rule not fwmark ... from ...`; доступ к `hometele` восстановлен через VNC удалением priority 10078.
- Тестовые WireGuard-службы и временные правила UFW отключены/удалены; `tun79` и Xray проверены и остаются рабочим производственным каналом.
- Runtime-порты уточнены: `azazello` использует Hysteria UDP 46539, OpenVPN UDP 21194 и Xray TCP 443; UDP 443 свободен.

## 2026-07-13

- Создана папка контекста для импорта в Codex.
- Подготовлены структура WIKI и безопасный ручной импорт центрального Git-WIKI; автоматическое подключение отложено до доступности ключа в Pageant.
