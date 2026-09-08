# Отчёт о ресурсах серверов: www, hometele, azazello

Дата аудита: 2026-08-15, 10:23–10:34 MSK  
Режим: read-only, без изменения конфигураций и перезапуска служб.

## Итог

- `www`: штатное состояние, ресурсы с большим запасом, Matrix/Element/TURN доступны.
- `hometele`: ресурсы и VPN-каскад в норме, но Fail2Ban запущен без единого jail.
- `azazello`: рабочие сервисы доступны, но корневой диск заполнен на 94%; наблюдается высокая нагрузка на единственный vCPU. Основная причина расхода диска — резервные копии 3x-ui без retention.

## Ресурсы

| Сервер | Uptime | vCPU | Load 1/5/15 | CPU во время замера | RAM | Swap | Корневой диск | Inodes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `www` | 7 д 7 ч | 3 | 0.00 / 0.00 / 0.00 | около 0% busy | 640 MiB из 1.9 GiB; available 1.3 GiB | нет | 11/35 GiB, 32% | 7% |
| `hometele` | 7 д 7 ч | 3 | 0.07 / 0.11 / 0.09 | около 3% busy | 552 MiB из 1.9 GiB; available 1.4 GiB | нет | 13/35 GiB, 39% | 11% |
| `azazello` | 13 д 7 ч | 1 | 1.78 / 1.43 / 1.09 | 60–79% busy в повторной серии; очередь 2–10 процессов | 788 MiB из 2.9 GiB; available 2.1 GiB | 512 KiB из 3 GiB | 15/17 GiB, 94%; свободно около 1 GiB | 24% |

На всех серверах время синхронизировано. Файл `reboot-required` отсутствует.

## Критические службы и доступность

### www

- Активны и enabled: `matrix-synapse`, `nginx`, `coturn`, `docker`, `hometele-command-agent`, `hometele-ai`, `openvpn-server@local-ai`, `fail2ban`, `ufw`, `certbot.timer`.
- `element-bot.service` остаётся `inactive/disabled` — это соответствует ранее выполненному отключению HomeBot на сервере.
- Failed systemd units: 0.
- Matrix локально: HTTP 200, около 3 ms.
- Matrix с рабочей станции: HTTP 200; Element: HTTP 200; TURN TCP/5349 доступен.
- Synapse Admin локально отвечает HTTP 200; внешний корень `admin.hometele.com.ru` возвращает 404. Это не доказывает отказ приложения, но внешнюю политику маршрутизации стоит сверить с ожидаемой.
- Docker: `synapse-admin` Up 7 days, около 4.2 MiB RAM.
- Ошибок уровня `err` в journal за 24 часа нет.

### hometele

- Активны: `xray`, `nginx`, `postfix`, `wg-quick@wg-home`, `awg-quick@awg79`, `openvpn-client@cz-exit`, `openvpn-client@local-ai`, серверные OpenVPN instances, `fail2ban`, `ufw`.
- Failed systemd units: 0; предупреждений Xray за 24 часа нет.
- Основной Xray egress: `sendThrough=10.8.1.2`, AmneziaWG активен. Резервный `tun79` также поднят.
- TCP/80, TCP/443 и SSH/52000 доступны с рабочей станции. Postfix слушает TCP/25 на сервере, но соединение с текущей рабочей станции не установилось; для проверки внешнего SMTP нужен тест с нейтрального почтового узла.
- Новых сетевых ошибок/дропов на основных интерфейсах в момент аудита не выявлено; накопленный `wg-home tx_dropped` равен 101.
- Ошибок уровня `err` в journal за 24 часа нет.

### azazello

- Активны: `x-ui` с рабочим Xray, `docker`, `nginx`, OpenVPN instances, `unbound`, `fail2ban`, `ufw`, таймер `amnezia-hometele-peer-guard`.
- Доступны TCP/80, Xray TCP/443, MTProto TCP/9443 и SSH/52000. Слушают Hysteria UDP/46539, OpenVPN UDP/21194 и AmneziaWG UDP/39425.
- Docker-контейнеры `mtproto-telegram`, `amnezia-awg2`, `signal-tls-proxy-certbot-1` работают 13 дней. В одном снимке CPU: MTProto 23.8%, AmneziaWG 9.8%.
- За пятесекундную контрольную серию новые RX/TX drops на `tun79`, `wg-home`, `wg0`, `eth0` не появились. Счётчики с boot: `tun79 tx_dropped=58190`, `wg-home tx_dropped=17870`.
- Межсерверный AmneziaWG peer `10.8.1.2/32` присутствует в live-интерфейсе, handshake свежий, guard завершает текущие проверки успешно.

## Найденные риски

### P1 — azazello: корневой диск заполнен на 94%

Факты:

- `/root/backup-3xui` занимает 4,602,904,576 байт.
- В каталоге 16 198 директорий и 32 433 файла за период 2026-06-05 — 2026-08-15.
- `/etc/cron.d/3xui-client-sync` запускает `/root/sync-3xui-clients.sh` каждые 5 минут.
- Скрипт создаёт новую копию `x-ui.db` и `config.json`, но логики retention/удаления старых копий нет.
- Нормальный полный день создаёт 288 каталогов, примерно 87 MB/сутки.

Если темп сохранится, оставшийся 1 GiB будет исчерпан ориентировочно за 7–12 дней с учётом роста логов и пакетов. Это расчётный прогноз, а не точная дата.

Дополнительные потребители:

- `/usr`: 7.84 GB;
- весь `/root`: 5.39 GB;
- `/var`: 2.17 GB, включая `/var/log` 680 MB;
- Docker images: 931 MB, из них 357 MB помечено reclaimable;
- APT cache: 164 MB;
- journald: 197 MB.

Рекомендация: сначала согласовать retention для 3x-ui и выбрать контрольные restore points, затем отдельно удалить/архивировать избыточные снимки. Простая очистка Docker/логов даст только временный запас и не устранит причину.

### P1 — hometele: Fail2Ban без jail

- Служба `fail2ban` active/enabled и отвечает `pong`.
- `fail2ban-client status`: `Number of jail: 0`.
- В `jail.local` и `jail.d/*.conf|*.local` не найдено ни одной секции с `enabled = true`.
- Это расходится с WIKI, где ожидаются как минимум `sshd`, `ufw-portscan`, `recidive`.

UFW активен, но автоматической блокировки атак на SSH/другие сервисы сейчас нет. Нужно восстановить согласованный набор jail после проверки актуальных log backend и фильтров.

### P2 — azazello: сертификат просрочен

- Сертификат `azazello.raxla.org` истёк 2026-06-11.
- Системный `certbot.timer` disabled/inactive.
- Контейнер Certbot сообщает `No renewals were attempted`.

TCP/443 сейчас обслуживает Xray Reality, поэтому основной VPN не зависит от этого сертификата. Следует определить, используется ли сертификат Signal TLS proxy/nginx; если сервис нужен, восстановить renewal, если нет — документировать и удалить устаревший контур отдельной задачей.

### P2 — azazello: высокая нагрузка единственного vCPU

- Load average превышает число vCPU.
- В повторной серии `vmstat` idle составлял 21–40%, system CPU доходил до 52%, run queue — до 10.
- I/O wait почти нулевой: ограничение выглядит процессорным, а не дисковым.
- Наиболее заметные потребители в снимках: MTProto, AmneziaWG и Xray.

Рекомендация: после устранения риска заполнения диска провести 10–15-минутный `pidstat`/container-stats профиль. При постоянной очереди рассмотреть ограничение фоновых задач или увеличение до 2 vCPU.

### P3 — azazello: служебные ошибки

- `unbound-resolvconf.service` failed с 2026-08-12: `No DNS servers specified`; основной `unbound.service` остаётся active.
- Guard AmneziaWG ранее периодически завершался с кодом 141, но между ошибками и после них проходил успешно. Текущее состояние `Result=success`, peer присутствует и передаёт трафик.

Это не текущий отказ VPN, но helper Unbound и редкие коды 141 guard стоит исправить, чтобы systemd/journal снова были чистым сигналом мониторинга.

## Безопасность, сертификаты и обновления

| Сервер | UFW | Fail2Ban | Сертификаты | Обновления |
|---|---|---|---|---|
| `www` | active | 5 jail, текущих ban 0 | `admin` и `matrix`: ещё 44 дня | 4 библиотеки Kerberos |
| `hometele` | active | служба active, 0 jail | ещё 41 день | 0 |
| `azazello` | active | 4 jail; `ufw-portscan` сейчас 108 ban | системный сертификат истёк | 3 security kernel packages, переход 6.8.0-107 → 6.8.0-137 |

Обновления и перезагрузки в рамках этого аудита не выполнялись.

## Приоритет действий

1. Срочно остановить бесконтрольный рост `/root/backup-3xui`: определить retention и безопасно сократить 16 198 снимков после отдельного подтверждения.
2. Восстановить Fail2Ban jail на `hometele` и проверить `sshd`, `ufw-portscan`, `recidive`.
3. Решить судьбу просроченного сертификата `azazello.raxla.org` и Certbot renewal.
4. Профилировать CPU `azazello`; при устойчивой нагрузке добавить vCPU или снизить фоновые расходы.
5. Исправить/отключить ненужный `unbound-resolvconf.service` и разобрать редкий exit 141 guard.
6. В плановое окно установить доступные обновления; для `azazello` отдельно предусмотреть загрузку нового kernel.

## Источники проверки

Использованы только read-only команды: `uptime`, `vmstat`, `ps`, `free`, `df`, `du`, `find`, `systemctl is-active/is-enabled/status/show/list-timers`, `journalctl`, `ss`, `ip`, `wg show` с обезличенным агрегированием, `docker ps/stats/system df`, `ufw status`, `fail2ban-client status`, `certbot certificates`, `apt list --upgradable`, локальные TCP/HTTPS probes.

Изменения, резервные копии и rollback в ходе аудита не создавались; rollback не требуется.
