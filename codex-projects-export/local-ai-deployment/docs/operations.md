# Эксплуатация Ubuntu local-ai

Хост: `local-ai`, LAN IP: `192.168.1.65`, VPN IP: `10.93.0.10`. Все сетевые
AI-порты разрешены UFW только контроллеру `192.168.1.41/32` и через `tun93` из
`10.93.0.0/24`; публичного проброса нет.

## Подключение

```powershell
ssh -i C:\Users\ACER-X-02\.ssh\id_ed25519_local_ai_admin_v2 `
  -o HostKeyAlias=192.168.1.65 user@10.93.0.10
```

SSH принимает только ключ. `root` по SSH запрещён. Пользователь `user` применяет
обычный `sudo` с паролем; временный широкий `NOPASSWD` удалён. Пароль и приватный
ключ в репозитории не сохраняются.

| Назначение | URL/порт | Когда доступно |
|---|---|---|
| Open WebUI | `http://10.93.0.10:3000` | LLM mode; основной браузерный интерфейс |
| OpenAI API llama.cpp | `http://10.93.0.10:8080/v1` | LLM mode |
| ComfyUI | `http://10.93.0.10:8188` | image/video mode |
| PyGhidra MCP | `http://10.93.0.10:8000/mcp` | LLM mode |
| Whisper Web/API | `http://10.93.0.10:8000` | whisper mode; вместо Ghidra |
| SSH | `10.93.0.10:22` | всегда |

LAN-адреса `192.168.1.65:*` остаются доступны с контроллера дома. Подробности
VPN, Windows-клиента и локальных агентов: [`vpn-and-agents.md`](vpn-and-agents.md).

## Агенты с Windows

```powershell
powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\start-local-ai-agent.ps1 `
  -Agent aider -Profile coder30

powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\start-local-ai-agent.ps1 `
  -Agent opencode -Profile coder30
```

Wrapper сначала проверяет VPN/SSH, выбирает GPU-профиль и ждёт готовности API.
Поддерживаются `coder30`, `qwen14` и `qwen-vl`; для задач с кодом использовать
`coder30`.

Open Interpreter запускается ярлыком `Open Interpreter.lnk` с рабочего стола.
Его пользовательская конфигурация находится в
`C:\Users\ACER-X-02\.openinterpreter\config.toml`, а локальный каталог модели —
в `C:\Users\ACER-X-02\.openinterpreter\model-catalog.json`. Исходная копия
каталога хранится в `configs/open-interpreter-model-catalog.json`. Каталог явно
задаёт для `qwen3-coder-30b-a3b-q4km` контекст 32768, автосжатие при 28000 и
лимит вывода инструментов 4000 токенов; это исключает fallback metadata клиента.

Open Interpreter использует `harness = "native"` и Chat Completions. Лишние
Apps/Plugins отключены, а MCP-сервер `ghidra` настроен на VPN endpoint
`http://10.93.0.10:8000/mcp` с автоматическим одобрением его инструментов.
Режим `native` обязателен: `minimal` не публикует динамические MCP tools модели.
Серверный адаптер на `:8080` преобразует специальный XML-формат Qwen3-Coder в
стандартный `tool_calls`; новый llama.cpp backend слушает только
`127.0.0.1:8012`.

Проверка регистрации Ghidra на ноутбуке:

```powershell
interpreter mcp get ghidra
interpreter exec --ephemeral --skip-git-repo-check `
  "Use only the Ghidra MCP tool list_project_binaries and return its result."
```

Успешный результат содержит события `ghidra/list_project_binaries (completed)`.
Рабочий тест также выполнил `ghidra/decompile_function` для `main` и вернул
реальный C-код. Open WebUI и Element остаются обычными чат-интерфейсами и сами
по себе Ghidra tools не получают; инструментальная связка работает в Open
Interpreter и в Qwen Code на ИИ-станции.

Для нового файла с диска Acer нужно попросить Open Interpreter: «передай этот
файл на ИИ-станцию, безопасно выполни `ai-ingest-file` и `ai-ghidra-stage`, затем
импортируй через `ghidra/import_binary` и декомпилируй; файл не исполнять».
Локальный Windows-путь нельзя передавать напрямую в PyGhidra: инструмент видит
только файловую систему Ubuntu. Точный workflow закреплён в корневом
`AGENTS.md` ноутбука.

Проверка адаптера и журнал:

```bash
systemctl is-active qwen3-coder.service local-ai-qwen3-tool-proxy.service
journalctl -u local-ai-qwen3-tool-proxy.service -n 50 --no-pager
python3 /opt/local-ai/apps/qwen3-coder-tool-proxy.py --self-test
```

Актуальная резервная копия и точные diff/rollback находятся в
`/srv/local-ai/backups/api-compat-20260802T203904Z`. Для отключения только
совместимого внешнего endpoint достаточно остановить и выключить
`local-ai-qwen3-tool-proxy.service`; loopback backend `8012` продолжит работать.

## Element / Matrix

На сервере `www` служба `hometele-ai.service` принимает в Element команду
`!ai текст вопроса` только от пользователя из `ALLOWED_USER`. Бот обращается к
новой модели через OpenVPN по `http://10.93.0.10:8080/v1`; наружу API не
проброшен. Команда `!model` возвращает точную статическую идентификацию
`Qwen3-Coder-30B-A3B-Instruct Q4_K_M`, поэтому ответ не зависит от способности
модели угадать собственное имя. Состояние связки:

```bash
systemctl is-active hometele-ai.service openvpn-server@local-ai.service
curl -fsS http://10.93.0.10:8080/health
journalctl -u hometele-ai.service -n 50 --no-pager
```

Последний backup и откат Matrix-бота:
`/var/backups/hometele-ai-local-20260803T050714Z` на `www`.

Новый `qwen3-coder.service` запускается с контекстом 32768 токенов. KV-кэш
`q8_0` остаётся в системной RAM через `--no-kv-offload`, поэтому контекст не
вытесняет модель из VRAM. Проверка фактического размера через совместимый API:

```bash
curl -fsS http://127.0.0.1:8080/props | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["default_generation_settings"]["n_ctx"])'
```

## Переключение VRAM

Одновременно запускается только один GPU-профиль. Команды корректно останавливают
предыдущую службу, ждут освобождения VRAM и затем запускают новую.

```bash
sudo ai-model status
sudo ai-model start qwen14
sudo ai-model start coder30
sudo ai-model start qwen-vl
sudo ai-model stop

sudo ai-mode llm
sudo ai-mode image
sudo ai-mode video
sudo ai-mode whisper
sudo ai-mode off
```

Порт `8000` разделяется по режимам: при `ai-mode whisper` останавливаются
PyGhidra MCP и его VPN socket; при `ai-mode llm` они запускаются снова. Взаимные
systemd `Conflicts` не позволяют вручную занять порт обеими службами.
`ai-mode llm` возвращает только после готовности API, Open WebUI и настоящего
MCP listener. `ai-model start coder30` теперь означает новый
`qwen3-coder.service` + compatibility proxy, а не прежний legacy unit.

Сокращённая проверка Coder и VL одним проходом:

```bash
sudo local-ai-test-models
```

Ответы и runtime-метрики сохраняются в
`/srv/local-ai/output/model-tests`; исходный LLM-профиль восстанавливается
автоматически.

Последняя выбранная LLM хранится в `/etc/local-ai/active-model` и запускается с
Open WebUI после reboot через `local-ai-autostart.service`; тяжёлые
ComfyUI/Whisper/SAM процессы не стартуют одновременно с LLM.

## Whisper

API совместим с OpenAI endpoint `/v1/audio/transcriptions`, принимает WAV, MP3,
M4A и MP4, возвращает `json`, `verbose_json`, `text`, `srt` или `vtt`. Лимит
одного файла — 512 MiB. Временный upload удаляется после ответа.

```bash
sudo ai-mode whisper
curl -F file=@recording.m4a -F model=turbo -F language=ru \
  -F response_format=srt http://127.0.0.1:8000/v1/audio/transcriptions
```

Команда ниже один раз распознаёт файл, создаёт рядом TXT/SRT/VTT/JSON и возвращает
предыдущий LLM-профиль:

```bash
ai-transcribe /path/to/video.mp4 --language ru
```

## ComfyUI и SAM 2

```bash
sudo ai-mode image
# открыть http://192.168.1.65:8188
sam2-video-test
```

`sam2-video-test` создаёт синтетическое видео с аудио, извлекает кадры FFmpeg,
отслеживает объект SAM 2.1, сохраняет маски/оверлей и собирает MP4 с исходным
аудио в `/srv/local-ai/output/sam2-test`.

## Диагностика и обслуживание

```bash
sudo local-ai-health-check
sudo ai-model status
systemctl status openvpn-client@hometele-local-ai.service
ip -br address show tun93
journalctl -u local-ai-llama -n 100 --no-pager
journalctl -u local-ai-open-webui -n 100 --no-pager
journalctl -u local-ai-comfyui -n 100 --no-pager
journalctl -u local-ai-whisper -n 100 --no-pager
nvtop
df -h /srv/local-ai
```

Health-check выполняется каждые пять минут, очистка временных файлов — ежедневно,
резервная копия конфигурации и БД Open WebUI — еженедельно. Ручная копия:

```bash
sudo local-ai-backup
```

Архивы хранятся в `/srv/local-ai/backups`, имеют SHA256 и удаляются через 35
дней. Модели, входные/выходные медиа и секреты в архив конфигурации не входят.
