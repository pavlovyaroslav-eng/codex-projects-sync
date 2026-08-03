# Changelog

## 2026-08-03

- Исправлен внешний compatibility proxy `:8080`: GET-запросы больше не получают
  ошибку `gzip is not supported by this browser`; gzip от llama.cpp прозрачно
  распаковывается, а заголовки запроса/ответа передаются корректно.
- Open WebUI снова включён на `:3000` и связан с новым API. Для Socket.IO
  разрешены только точные LAN/VPN/loopback origins. Браузерный тест через
  `10.93.0.10:3000` завершён реальным ответом Qwen3-Coder без console errors.
- Matrix-бот теперь детерминированно сообщает точную модель по `!model` и не
  выдаёт Qwen3-Coder-30B-A3B за Qwen3-14B.
- PyGhidra MCP опубликован для ноутбука только через VPN endpoint
  `http://10.93.0.10:8000/mcp`. Open Interpreter переведён на `native` harness,
  Ghidra tools разрешены, подтверждены реальные `list_project_binaries` и
  `decompile_function(main)`.
- Устранён конфликт Ghidra/Whisper на порту `8000`: `ai-mode whisper`
  освобождает порт, а `ai-mode llm` автоматически возвращает PyGhidra MCP.
- Старые `ai-model`/`ai-mode` синхронизированы с новым `qwen3-coder.service`:
  профиль `coder30` управляет backend `8012`, proxy `8080`, Open WebUI и MCP;
  удалена противоречивая legacy dependency. Реальный цикл
  `LLM -> Whisper -> LLM` и повторный MCP tool call прошли успешно.

## 2026-08-02

- После развёртывания нового `qwen3-coder.service` восстановлен прежний внешний
  OpenAI-compatible endpoint `:8080`: адаптер
  `local-ai-qwen3-tool-proxy.service` принимает LAN/VPN-запросы и передаёт их в
  новый loopback backend `127.0.0.1:8012`. Существующие UFW-правила для
  `192.168.1.41/32` и `tun93` сохранены без расширения доступа.
- С ACER подтверждены `/health`, `/v1/models` и Chat Completions через LAN
  `192.168.1.65:8080` и OpenVPN `10.93.0.10:8080`. Open Interpreter выполнил
  реальный безопасный PowerShell tool call через новую модель.
- Matrix-бот `hometele-ai.service` на `www` переведён с внешнего DeepSeek на
  `http://10.93.0.10:8080/v1`, включён в автозагрузку и успешно вошёл в Matrix.
  При старте бот сначала сдвигает sync token и не повторяет старые команды.

## 2026-08-01

- Для Qwen3-Coder добавлен systemd-адаптер XML function calls в стандартный
  OpenAI `tool_calls`. llama.cpp перенесён на loopback `127.0.0.1:8082`, внешний
  API сохранён на `:8080`; Open Interpreter переведён на `minimal`/Chat и
  подтверждён реальным выполнением PowerShell-команды.
- Установлены Ubuntu 24.04.4 LTS и видимый GRUB (`saved`, timeout 10 s) рядом с
  сохранёнными Windows NTFS/Windows Boot Manager. Root — один ext4-раздел около
  511,4 GiB, swap file увеличен до 16 GiB.
- Настроены key-only SSH, root SSH prohibition, passwordless sudo для локального
  администратора, UFW controller-only, Fail2Ban, fstrim и unattended upgrades.
- Подтверждена RTX 5070 12 GiB: driver 595.84, CUDA Toolkit 13.2, PyTorch
  2.12.0+cu132 и compute capability 12.0.
- Собран llama.cpp b10210 с CUDA; установлен и проверен Qwen3-14B Q4_K_M. Короткий
  русский test дал 64,736 tok/s при пике около 9,27 GiB VRAM.
- Установлен Open WebUI 0.9.5 с выключенными signup/plugins/code execution и
  controller-only UFW rule.
- Установлены ComfyUI v0.29.2 и SDXL Base 1.0. Исправлена несовместимость
  torchaudio cu130 с PyTorch cu132 установкой поддерживаемого torchaudio
  2.11.0+cpu; реальная генерация 768×768 заняла 10,7 s, пик 7 354 MiB/68 °C.
- Установлены faster-whisper 1.2.1, CUDA 12 runtime libraries CTranslate2 и модель
  `turbo`; русский test 3,52 s распознан дословно. Добавлены Web/OpenAI API,
  TXT/SRT/VTT/JSON, upload limit и автоматическое удаление временного файла.
- Qwen3-Coder-30B-A3B и официальный Qwen3-VL-8B загружены по фиксированным
  размеру/SHA256 и прошли рабочие API-запросы; `ai-model` взаимно исключает
  GPU-службы и сохраняет профиль для reboot.
- Установлен отдельный SAM 2.1 environment. Tracking 18 кадров занял 4,679 s;
  NVENC MP4 содержит H.264 video и исходный AAC audio.
- Установлены pinned ComfyUI Manager, VHS, SAM2, RIFE, ControlNet Aux и
  WanVideoWrapper. Registry успешно загрузил 857 nodes.
- Добавлены health/cleanup/backup timers, model inventory, operations и recovery
  docs. До отдельного подтверждения live-изменений была подготовлена только
  контрольная точка №3 для `hometele`.
- Финальный reboot успешно восстановил key-only SSH, Qwen3-14B, Open WebUI и
  timers. Post-boot health-check — 0 ошибок; сохранены backup и итоговый inventory.
- Владелец подтвердил успешную физическую загрузку Windows через сохранённый
  Windows Boot Manager после установки Ubuntu.
- После отдельного live-аудита и контрольной точки развёрнут изолированный
  OpenVPN `tun93` (`10.93.0.0/24`, UDP `21200`) на `matrix.hometele.com.ru`.
  Сервер `.1`, local-ai `.10` и Windows `.11` включены в автозагрузку; NAT,
  default route, DNS, nginx, SSH и Docker не менялись.
- UFW local-ai разрешает через `tun93` только SSH/Open WebUI/Whisper/llama.cpp/
  ComfyUI. Временные серверные экспорты `.ovpn` удалены после установки клиентов;
  private profiles не добавлялись в репозиторий.
- На Windows установлены OpenVPN Community `2.7.5`, Aider `0.86.2` и OpenCode
  `1.18.10`. Оба агента получили контрольный ответ от Qwen3 Coder через VPN;
  OpenCode ограничен шестью шагами во избежание инструментального цикла.
- Подтверждён каскад Hiddify `sing-tun` → OpenVPN: маршрут к публичному endpoint
  идёт через `tun0`, а `10.93.0.10` — через OpenVPN TAP; SSH/API отвечают. Добавлен
  скрипт одной команды для проверки каскада и открытия Open WebUI в поездках.

## 2026-07-31

- После повторной сверки model/serial/size, чистого `chkdsk /scan`, BCD export и
  явного принятия владельцем отсутствующих recovery safeguards C: уменьшен с
  931,40 до 420 GiB. Получено 511,40 GiB unallocated; EFI/MSR не менялись,
  BitLocker остаётся off, Fast Startup/hibernation отключены. Post-audit пройден.
- Официальный Ubuntu 24.04.4 Desktop ISO загружен на целевой хост; SHA256
  `3a4c9877b483ab46d7c3fbe165a0db275e1ae3cfe56a5657e5a47c2f99a99d1e`
  совпал. Raw USB writer не запустился, потому что подтверждённая флешка была
  физически отключена; выбор другого диска запрещён предохранителем.
- После повторного подключения exact-match USB очищен и полностью перезаписан
  ISO. Повторный полный readback пропущен по прямому указанию владельца;
  структура GPT и наличие `bootx64.efi`/`grubx64.efi`/`mmx64.efi` проверены.
- По решению владельца выбран Ubuntu 24.04.4 Desktop AMD64. Подготовлены
  контрольная точка №2, проверяемый Windows-side shrink script и безопасная
  загрузка официального ISO с обязательным SHA256; разделы и USB не изменялись.
- В bootstrap исправлен WHEA-фильтр: теперь учитывается только точный провайдер
  `Microsoft-Windows-WHEA-Logger`, а не любые события с совпавшим ID
  (версия `2026.07.31.9`).
- Завершён этап 1: исправлено ложное совпадение WHEA ID 18 (точный WHEA count
  равен 0), подтверждены AVX2, один NUMA-узел, предел уменьшения C:, отсутствие
  WinRE и отключённый Defender. Добавлены follow-up inventory и контрольная
  точка №1 без изменения дисков/загрузчика.
- По официальным источникам проверена текущая совместимость Ubuntu 24.04/26.04,
  NVIDIA/CUDA и PyTorch; предложено дождаться Ubuntu 26.04.1 от 2026-08-04 либо
  использовать 24.04.4 LTS.
- Исправлен локальный SSH-ключ, который первоначально получил буквальный
  passphrase `""` из-за Windows PowerShell argument quoting. Выпущен и проверен
  key-only `id_ed25519_local_ai_admin_v2`; старый публичный ключ отозван на
  целевом хосте после создания двух backup-файлов (версия `2026.07.31.8`).
- После включения blank-password network logon дополнительно принудительно
  отключена парольная аутентификация OpenSSH; WinRM/SMB также ограничены одним
  IP контроллера. Firewall RDP ограничивается до запуска listener
  (версия `2026.07.31.7`).
- По явному подтверждению пользователя добавлен ранний RDP для локальной учётной
  записи с пустым паролем: NLA отключена, TLS/high encryption сохранены, доступ
  ограничен контроллером `192.168.1.41/32`. RDP настраивается до длительного
  аудита; исходные registry/firewall settings предварительно сохраняются
  (версия `2026.07.31.6`).
- Исправлена передача `System.Object[]` из Windows PowerShell 5.1 в функцию
  UTF-8-записи. Добавлен ранний LAN-only containment штатного правила OpenSSH
  после прерванной установки (версия `2026.07.31.5`).
- Усилен первый запуск OpenSSH на чистой Windows: служба предварительно создаёт
  host keys; при отсутствии `ProgramData\ssh\sshd_config` используется штатный
  `sshd_config_default` Microsoft OpenSSH (версия `2026.07.31.4`).
- Исправлена обработка исходно не настроенного WinRM: `WSManFault` при чтении
  отсутствующего listener теперь сохраняется в backup как факт и не прерывает
  bootstrap (версия `2026.07.31.3`).
- Исправлена совместимость bootstrap с Windows PowerShell 5.1: коллекции строк
  отчёта теперь допускают пустые строки-разделители. Добавлен вывод прогресса
  каждого read-only сборщика; полный smoke-test формирования пяти отчётов пройден.
- Создан поэтапный audit-first план развёртывания.
- Выполнена первичная LAN-проверка `192.168.1.65`; MAC подтверждён, удалённые
  административные порты фильтруются.
- Read-only проверена ветка Git-WIKI `hometele`.
- Создан отдельный локальный SSH-ключ для будущего администрирования local-ai;
  приватная часть исключена из репозитория.
- Добавлен идемпотентный Windows PowerShell bootstrap с аудитом, резервными
  копиями, LAN-only SSH/RDP/WinRM/SMB и dry-run (`-WhatIf`).
