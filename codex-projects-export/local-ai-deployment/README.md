# Local AI deployment

Воспроизводимая конфигурация локальной ИИ-станции `local-ai` на Ubuntu 24.04.4
LTS, RTX 5070 12 GB и dual boot с сохранённой Windows 10.

## Текущее состояние

- Ubuntu установлена в UEFI рядом с Windows; Windows-раздел и Windows Boot
  Manager сохранены. GRUB видим, timeout 10 секунд, режим `saved`. Физическая
  загрузка Windows после установки Ubuntu подтверждена владельцем.
- SSH — key-only, root login запрещён, UFW и Fail2Ban активны. AI-порты разрешены
  только контроллеру `192.168.1.41/32` и изолированной VPN `10.93.0.0/24`.
- NVIDIA driver `595.84`, CUDA Toolkit 13.2, PyTorch `2.12.0+cu132`; RTX 5070
  успешно прошла CUDA-тест.
- llama.cpp `b10210` собран с CUDA для compute capability 12.0.
- Qwen3-14B Q4_K_M работает через OpenAI-compatible API и Open WebUI.
- Qwen3-Coder-30B-A3B Q4_K_M и официальный Qwen3-VL-8B Q4_K_M/mmproj
  проверены через OpenAI-compatible API; файлы приняты по размеру и SHA256.
- ComfyUI `v0.29.2` и SDXL Base 1.0 работают; smoke generation 768×768 заняла
  10,7 с при пике 7 354 MiB VRAM и 68 °C.
- faster-whisper `1.2.1` с моделью `turbo` дословно распознал русский тест;
  доступны Web/API и TXT/SRT/VTT/JSON.
- SAM 2.1 отследил объект во всех 18 кадрах и собрал H.264 NVENC/AAC MP4.
  Установлены pinned Manager, VHS, SAM2, RIFE, ControlNet Aux и WanVideo nodes.
  VRAM-профили не запускаются одновременно.
- Health-check, очистка временных файлов и резервные копии конфигурации работают
  по systemd timers.
- Финальный reboot пройден: key-only SSH, выбранный Qwen3-14B, Open WebUI и
  timers поднялись автоматически; post-boot health-check вернул 0 ошибок.
- OpenVPN `tun93` работает через `matrix.hometele.com.ru`: сервер `.1`, ИИ-станция
  `.10`, Windows-ноутбук `.11`. Все три службы включены в автозагрузку, default
  route/DNS не меняются.
- На Windows установлены Aider `0.86.2` и OpenCode `1.18.10`; оба выполнили
  реальные запросы к Qwen3 Coder через VPN.
- Open WebUI на `:3000` проверен реальным браузерным сообщением через VPN;
  прежняя gzip-ошибка внешнего compatibility proxy устранена.
- Open Interpreter использует Qwen3-Coder через VPN и PyGhidra MCP. Реально
  подтверждены получение списка бинарников и декомпиляция функции `main`.
- Element-бот отвечает через ту же Qwen3-Coder; команда `!model` возвращает
  точное имя активной модели без генеративного угадывания.
- Каскад Hiddify `tun0` → публичный OpenVPN endpoint → `10.93.0.10` проверен:
  SSH и API доступны при активном Hiddify-профиле из внешней сети.

## Быстрый доступ

```powershell
ssh -i C:\Users\ACER-X-02\.ssh\id_ed25519_local_ai_admin_v2 `
  -o HostKeyAlias=192.168.1.65 user@10.93.0.10
```

- Open WebUI: `http://10.93.0.10:3000`
- Qwen OpenAI-compatible API: `http://10.93.0.10:8080/v1` (также используется
  Open Interpreter и Matrix/Element-ботом)
- PyGhidra MCP для Open Interpreter: `http://10.93.0.10:8000/mcp` в LLM mode
- ComfyUI: `http://10.93.0.10:8188` после `sudo ai-mode image`
- Whisper: `http://10.93.0.10:8000` после `sudo ai-mode whisper`; Ghidra на этом
  порту в данном режиме автоматически останавливается

Web-интерфейсы сейчас без отдельного пароля по прямому решению владельца домашней
LAN/VPN, но UFW принимает подключения только от `192.168.1.41/32` и через
`tun93` из `10.93.0.0/24`. Публичной экспозиции AI-портов нет.

```bash
sudo ai-model status
sudo ai-model start qwen14
sudo ai-model start coder30
sudo ai-model start qwen-vl
sudo ai-mode image
sudo ai-mode whisper
sudo ai-mode llm
sudo local-ai-test-models
```

Полная памятка: [`docs/operations.md`](docs/operations.md). Источники и хэши:
[`docs/model-inventory.md`](docs/model-inventory.md). Восстановление GRUB/Windows:
[`docs/recovery.md`](docs/recovery.md). VPN и агенты:
[`docs/vpn-and-agents.md`](docs/vpn-and-agents.md).

Проверка удалённого доступа поверх Hiddify и открытие Open WebUI:

```powershell
powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\open-local-ai-via-hiddify.ps1
```

## Каталоги Ubuntu

```text
/opt/local-ai/apps          зафиксированные приложения
/opt/local-ai/src           исходники llama.cpp и SAM 2
/opt/local-ai/venvs         отдельные Python environments
/srv/local-ai/models        модели и manifests
/srv/local-ai/input         входные медиа
/srv/local-ai/output        результаты
/srv/local-ai/cache         runtime cache
/srv/local-ai/backups       архивы конфигурации
/etc/local-ai               выбранный профиль и конфигурация
/var/log/local-ai           installation logs
```

Linux размещён на одном ext4 root-разделе объёмом около 511 GiB; `/srv/local-ai`
не отдельная файловая система. Health-check считает менее 50 GiB свободного места
ошибкой. Swap file — 16 GiB.

## Скрипты этапов

- `ubuntu-stage1-bootstrap.sh` — SSH/UFW/hostname/GRUB;
- `ubuntu-stage2-system-base.sh` — системные пакеты, каталоги и swap;
- `ubuntu-stage3-gpu-llama.sh` — CUDA/PyTorch/llama.cpp;
- `ubuntu-stage4-qwen-service.sh` — Qwen3-14B;
- `ubuntu-stage5-open-webui.sh` — Open WebUI;
- `ubuntu-stage6-comfyui.sh` — ComfyUI/SDXL/VRAM mode;
- `ubuntu-stage7-whisper.sh` — faster-whisper API;
- `ubuntu-stage8-model-manager.sh` — Coder/VL и `ai-model`;
- `ubuntu-stage9-sam2-video.sh` — отдельный SAM 2.1;
- `ubuntu-stage10-comfy-nodes.sh` — pinned Manager/VHS/SAM2/RIFE/ControlNet/Wan nodes;
- `ubuntu-stage11-operations.sh` — health/cleanup/backup/recovery.
- `ubuntu-stage12-qwen3-tool-proxy.sh` — преобразование XML tool calls Coder в
  стандартный OpenAI `tool_calls` для Windows-агентов.
- `test-model-profiles.sh` — один функциональный запрос Coder и VL с возвратом
  исходного LLM-профиля.

Скрипты не содержат паролей, private keys или VPN profiles. Модельные загрузки
идемпотентны и возобновляются из `.part`.

## VPN `hometele`

Контрольная точка №3 подтверждена и применена после повторного live-аудита.
Создан отдельный OpenVPN instance `tun93`/`10.93.0.0/24`, UDP `21200`, с двумя
уникальными сертификатами и без NAT/default route/DNS. Существующие nginx, SSH,
Docker и другие службы не изменялись. План, backup и проверка описаны в
[`docs/control-point-3-vpn-plan.md`](docs/control-point-3-vpn-plan.md).

## История Windows/dual boot

До Ubuntu выполнен Windows read-only аудит, сохранены snapshots в `inventory/`,
контрольные точки в `docs/control-point-1.md` и `docs/control-point-2.md`, а также
PowerShell bootstrap/USB scripts. Они оставлены для аудита и восстановления, но
не нужны для повседневной работы Ubuntu.
