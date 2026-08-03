# Final verification

Дата: 2026-08-02. Итог: **PASS после реального reboot**. Внешние ограничения:
Windows ISO не предоставлен, ClamAV CDN database недоступна до окончания
cooldown.

## LLM и Qwen Code

- llama.cpp CUDA build и model SHA-256: PASS;
- `qwen3-coder.service`: active/enabled, `NRestarts=0`;
- health, models, chat, streaming, русский язык и Python code: PASS;
- system message 11,228 tokens: PASS, ответ `ПРИНЯТО`;
- OpenAI function call: PASS, `safe_add {"a":20,"b":22}`;
- context 8192/16384/32768: PASS, без OOM/swap thrashing;
- backend listener только `127.0.0.1:8012`; LAN connection к backend timeout:
  PASS. Совместимый proxy `0.0.0.0:8080` active/enabled и ограничен UFW;
- Acer LAN/VPN health, models и chat через `:8080`: PASS;
- Open Interpreter end-to-end PowerShell tool call через VPN: PASS,
  `LOCAL_AI_OI_OK`;
- Matrix `www` → `10.93.0.10:8080` через `tun93`: PASS; Element AI bot
  active/enabled, login/sync PASS, `NRestarts=0`;
- Qwen Code 0.21.3 без auth CLI override вернул `QWEN_OK` через локальную
  модель; approval mode `default`, folder trust включён;
- read-only тест проекта: три файла прочитаны, bug найден, diff предложен,
  файловые SHA-256 не менялись;
- post-reboot: service active/enabled, API PASS, `NRestarts=0`.

## Ghidra и MCP

- Ghidra GUI smoke и headless safe ELF analysis: PASS;
- `pyghidra-mcp.service`: active/enabled, loopback-only 8000: PASS;
- Qwen MCP list: `ghidra ... Connected`;
- debug и stripped ELF import/analysis/decompile/xrefs/comment/save: PASS;
- LAN connection к 8000: timeout, публикации наружу нет.

## Статический анализ

- `ai-ingest-file` создал hash quarantine и metadata без исполнения: PASS;
- rootless Podman: true; image `localhost/ai-static-tools:1.0`: present;
- safe ELF static scan: report created, `executed=false`, `network=false`;
- container policy: network none, input read-only, tmpfs, no host home,
  `/dev`, Podman socket, capabilities или tokens: PASS;
- software search/plan: PASS; install требует `INSTALL` и sudo password;
- ClamAV package present, signature scan status: UNAVAILABLE (CDN 403).

## VM

- KVM access and `windows-analysis` definition: PASS;
- isolated network active/autostart, no forwarding: PASS;
- default NAT network inactive/autostart=no: PASS;
- safe ISO read-only attach, VM start, isolated NIC, loopback display: PASS;
- no filesystem share/redirdev/home path/clipboard/file transfer: PASS;
- snapshot `empty-template` create/revert/current: PASS;
- VM state после теста: shut off; Windows guest: NOT INSTALLED.

## Host/security

- итоговый `scripts/99-verify-stack.sh`: PASS; журнал
  `logs/99-verify-stack-20260802T192654Z.log`;
- модель в рабочем режиме: 7053 MiB VRAM used, 4720 MiB free, 47°C;
- post-reboot host RAM available 57 GiB, swap used 0;
- LLM/MCP backend wildcard listeners отсутствуют; совместимый `:8080`
  намеренно опубликован только в controller/VPN scope;
- UFW, SSH, disks, bootloader и firmware не изменялись;
- временный `NOPASSWD: ALL` удалён после последнего privileged step,
  эквивалентный кандидат без drop-in прошёл `visudo -cf`; в новом SSH-сеансе
  файл отсутствует и `sudo -n true` возвращает 1 / требует пароль;
- новые NVIDIA Xid/Fatal/host OOM события после reboot отсутствуют;
- `local-ai-health.service` проверяет Qwen 8012, API adapter 8080 и MCP 8000;
  post-reboot run
  status 0; автоматический timer run 23:18:58 MSK также вернул
  `Result: 0 error(s)`, timer active/enabled;
- `systemctl --failed` после исправления пуст.

## Проверка интеграции 2026-08-03

- `:8080/`: HTTP 200 HTML через LAN и VPN, gzip browser error устранена;
- Open WebUI `:3000`: title/UI/model отрисованы, console errors отсутствуют;
- browser chat через `10.93.0.10:3000`: Qwen3-Coder вернул реальный ответ;
- Element backend: `qwen3-coder-30b-a3b-q4km`, добавлен `!model`;
- Open Interpreter config: `native` harness, MCP `ghidra`, approval `approve`;
- `ghidra/list_project_binaries`: completed, возвращены два тестовых ELF;
- `ghidra/decompile_function(main)`: completed, возвращён C-код с
  `add_numbers(0x14,0x16)` и `printf`;
- MCP VPN listener: только `10.93.0.10:8000`, backend loopback-only;
- Ghidra/Whisper port conflicts проверены `systemd-analyze verify`.
- Реальный цикл `ai-mode whisper` -> `ai-mode llm`: PASS; порт `8000`
  переходит Whisper и возвращается PyGhidra, Qwen/API/WebUI восстановлены;
- повторный Open Interpreter `ghidra/list_project_binaries` после рестартов:
  completed, два бинарника;
- итоговый `local-ai-health.service`: `Result: 0 error(s)`, failed units пусты.
