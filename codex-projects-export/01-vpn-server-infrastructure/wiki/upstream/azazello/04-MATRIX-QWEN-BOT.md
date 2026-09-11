# Matrix Qwen bot на `www`

Состояние зафиксировано 2026-08-01 после live-проверки и reboot `www`.

## Архитектура

```text
Element
   ↓
Matrix Synapse на www (127.0.0.1:8008)
   ↓
matrix-qwen-bot.service, непривилегированный пользователь matrix-qwen-bot
   ↓
OpenVPN tun93: www 10.93.0.1/24
   ↓
local-ai 10.93.0.10:8080
   ↓
llama.cpp / qwen3-14b-q4km
```

Порт модели не опубликован через nginx. На ИИ-станции UFW имеет default deny и
разрешает AI-порты только контроллеру LAN и VPN-подсети на `tun93`.

## Фактическая конфигурация

```text
service: matrix-qwen-bot.service
code: /opt/matrix-qwen-bot/matrix_qwen_bot.py
config: /etc/matrix-qwen-bot/bot.env
system prompt: /etc/matrix-qwen-bot/system-prompt.txt
state: /var/lib/matrix-qwen-bot/state.json
LLM base URL: http://10.93.0.10:8080/v1
LLM model: qwen3-14b-q4km
context: 8192
concurrency: 1
```

Конфигурация содержит Matrix-секрет и имеет права `root:matrix-qwen-bot 0640`.
Значения секретов не копируются в WIKI.

Бот отвечает на обычный текст в личном чате. В группе отвечает только при
упоминании, reply на сообщение бота или команде. Allowlist обязателен и работает
по принципу default deny.

По состоянию на 2026-08-01 allowlist синхронизирован со всеми 12 активными
пользовательскими аккаунтами локального Synapse. Служебные аккаунты
`hometeleai` и `servermon`, гости, отключённые, заблокированные и приостановленные
аккаунты в доступ не включаются. Новых пользователей после их создания нужно
добавлять в `MATRIX_ALLOWED_USERS` отдельно.

Команды:

```text
!help
!new
!reset
!status
!model
!stop
!ai текст   # совместимость со старым ботом
```

У бота нет shell, SSH, root, Docker socket или административных инструментов.
Старые команды `!backup` и вывод состояния системных служб удалены.

## Диагностика

```bash
systemctl status matrix-qwen-bot --no-pager -l
journalctl -u matrix-qwen-bot -n 100 --no-pager
systemctl is-active openvpn-server@local-ai
ping -c 2 10.93.0.10
curl -fsS http://10.93.0.10:8080/health
curl -fsS http://10.93.0.10:8080/v1/models
```

После установки проверены обычный Chat Completions, system message, streaming,
отмена генерации, restart модели, restart бота, restart OpenVPN и reboot `www`.
После reboot сервисы Synapse, nginx, coturn, Docker, OpenVPN и Matrix bot стали
active без restart loop.

## Кодировка streaming-ответов

2026-08-01 исправлено отображение русских ответов вида `Ð...`: строки SSE от
llama.cpp теперь принимаются как bytes и явно декодируются в UTF-8. Добавлен
регрессионный unit-тест с ответом `Привет!`; после установки также выполнен
реальный streaming-запрос к Qwen3-14B с серверной проверкой кириллицы и
отсутствия признаков mojibake.

Резервная копия состояния до этой ревизии:

```text
/opt/backups/matrix-qwen-bot-revision-20260801-195152/RESTORE.md
```

## Откат

Старый `hometele-ai.service` отключён, но исходный код и unit не удалены.

```text
/opt/backups/matrix-deepseek-bot-20260801-193151/RESTORE.md
```

Backup содержит код, защищённую конфигурацию, unit, зависимости, журнал,
состояние сети/firewall и проверяемый SHA256 manifest.
