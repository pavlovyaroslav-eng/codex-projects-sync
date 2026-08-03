# Install report

Дата итогового состояния: 2026-08-02, станция `local-ai`.

## Установлено и проверено

| Компонент | Версия / конфигурация | Путь или служба |
|---|---|---|
| Ubuntu | 24.04.4 LTS, kernel 7.0.0-28 | host |
| NVIDIA | driver 595.84, CUDA 13.2.2, RTX 5070 12227 MiB | kernel/CUDA |
| llama.cpp | b10229, commit `c745be2a2c5aefbf9f3ced0440804373731890b6`, CUDA sm_120 | `/opt/ai-stack/releases/llama-b10229` |
| Qwen3-Coder | 30B-A3B-Instruct Q4_K_M, 18,556,689,568 bytes | `/srv/ai/models/qwen3-coder-30b-a3b` |
| Qwen Code | 0.21.3 standalone | `/opt/ai-stack/releases/qwen-code-v0.21.3` |
| Ghidra | 12.1.2 PUBLIC, JDK 21 | `/opt/ghidra/ghidra_12.1.2_PUBLIC` |
| PyGhidra MCP | pyghidra-mcp 0.2.3, PyGhidra 3.1.0, MCP 1.29.0 | `/opt/ai-stack/venvs/pyghidra-mcp` |
| Podman | 4.9.3 rootless | `localhost/ai-static-tools:1.0` |
| KVM/libvirt | QEMU 8.2.2, libvirt 10.0.0 | `qemu:///system` |
| .NET | SDK 10.0.110 | `/usr/bin/dotnet` |

Модель получена из `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`, revision
`b17cb02dd882d5b6ab62fc777ad2995f19668350`. SHA-256:
`fadc3e5f8d42bf7e894a785b05082e47daee4df26680389817e2093056f088ad`.
Лицензия базовой модели — Apache-2.0; локальные копии `LICENSE` и
`MODEL_CARD.md` лежат рядом с GGUF.

## Службы и порты

- `qwen3-coder.service`: active/enabled, user `qwenllm`,
  `127.0.0.1:8012`, `Restart=on-failure`, `NRestarts=0`;
- `pyghidra-mcp.service`: active/enabled, user `ghidramcp`,
  `127.0.0.1:8000`;
- старые `local-ai-llama.service` и `local-ai-autostart.service` выключены;
- legacy Open WebUI после reboot inactive и порт 3000 не слушает; прежние
  controller/VPN-only UFW rules оставлены без изменений;
- совместимый адаптер `local-ai-qwen3-tool-proxy.service` опубликован на
  `0.0.0.0:8080` и передаёт запросы новому backend `127.0.0.1:8012`; доступ
  ограничивают уже существующие UFW rules для Acer и `tun93`.

API проверен через health, models, chat completions, streaming, русский язык,
генерацию Python, system message на 11,228 prompt tokens и OpenAI function call.
Qwen Code без CLI override подключился к локальному endpoint и вернул
`QWEN_OK`; отдельный end-to-end сеанс прочитал три файла тестового проекта,
нашёл ошибку `a - b`, предложил diff и не изменил файлы. MCP `ghidra` показан
как `Connected`.

Совместимый endpoint проверен с Acer по LAN `192.168.1.65:8080` и OpenVPN
`10.93.0.10:8080`: health/models/chat PASS. Open Interpreter через текущий
профиль `local-ai` выполнил безопасный PowerShell tool call и получил
`LOCAL_AI_OI_OK`. Matrix-сервер `www` по `tun93` видит ту же модель; его
`hometele-ai.service` переведён на этот API и active/enabled.

## Инструменты анализа

Официальные release assets: capa 9.4.0, Rizin 0.9.1, JADX 1.5.6, Apktool
3.0.3, ILSpycmd 10.1.1.8388. Из Ubuntu repositories установлены file/binutils,
gdb, strace/ltrace, ripgrep, jq, 7zip, cabextract, ExifTool, YARA 4.5.0,
ClamAV 1.5.3, binwalk 2.3.4, libguestfs и xorriso. Python venv фиксирует
pefile 2024.8.26, LIEF 1.0.0, Capstone 5.0.9, Unicorn 2.1.4,
yara-python 4.5.4, python-magic 0.4.27 и ghidrecomp 0.5.9.

`ai-ingest-file` копирует объект в hash-каталог quarantine без исполнения.
`ai-static-scan` запускает удаляемый rootless-контейнер без сети, `/dev`, host
home, сокета Podman и capabilities. Безопасный ELF-тест сформировал JSON/Markdown
report и отметил `executed=false`, `network=false`.

## VM

Определена выключенная VM `windows-analysis`: q35/UEFI, TPM 2.0, 8 vCPU,
16 GiB RAM, sparse qcow2 120 GiB, SPICE только `127.0.0.1`, изолированная сеть
`windows-analysis-isolated` без `<forward>`. Проверены старт на безопасном ISO,
read-only CD-ROM, отсутствие host shares/clipboard/file transfer, snapshot
`empty-template` и revert. Автоматически появившаяся libvirt-сеть `default`
остановлена и лишена autostart.

## Резервные копии

- базовая конфигурация:
  `/srv/local-ai/backups/ai-station-bootstrap-20260802T145102Z/pre-base-config.tar.gz`,
  SHA-256 `ba98213c1b3ed9d6fc11480f5258ce3ff5fb5faa04b3caacab36e0b4fe1e75d9`;
- прежние LLM units:
  `/srv/local-ai/backups/ai-station-bootstrap-20260802T191338Z/pre-qwen-service.tar.gz`,
  SHA-256 `3cebcd967e2c9a5f306239105b81179d31fd8046446a502e7d98fd13b5396985`;
- точечные backups Qwen Code — `~/ai-station-bootstrap/backups/qwen-code-*`;
- backup MCP unit — `/srv/local-ai/backups/ai-station-bootstrap-20260802T183300Z/`.
- совместимый API unit, health-check и точный rollback —
  `/srv/local-ai/backups/api-compat-20260802T203904Z/`.

## Не установлено / требуется участие владельца

- Windows guest и FLARE-VM не установлены. Для Windows требуется принадлежащий
  владельцу ISO в `/var/lib/libvirt/boot/windows-analysis.iso`;
- ClamAV signature database недоступна из-за CDN HTTP 403/cooldown до
  2026-08-03 17:53 MSK; до успешного `freshclam` результат ClamAV считается
  `unavailable`;
- Git commit не создан без `user.name`/`user.email` владельца.

Разрешённый reboot выполнен 2026-08-02 в 23:09 MSK. После загрузки Qwen и MCP
active/enabled с `NRestarts=0`, GPU доступна, VM shut off, изолированная сеть
active/autostart. `local-ai-health.service` завершён status 0, timer
active/enabled; автоматический timer run в 23:18:58 завершён status 0 и
`Result: 0 error(s)`, `systemctl --failed` пуст.

См. точные ошибки в [`reports/FAILED_STEPS.md`](reports/FAILED_STEPS.md) и
откат в [`ROLLBACK.md`](ROLLBACK.md).
