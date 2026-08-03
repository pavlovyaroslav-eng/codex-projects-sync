# План и фактический статус local-ai

Дата начала: 2026-07-31  
Целевой хост: `192.168.1.65`, MAC `00:e0:21:a9:50:30`

## Завершено

1. Windows read-only аудит оборудования, диска, UEFI/BCD/BitLocker/WinRE, GPU,
   NUMA и сети. Результаты сохранены в `hardware-report.md` и `inventory/`.
2. Контрольная точка №1: выбран Ubuntu dual boot.
3. Контрольная точка №2: NTFS уменьшен штатно из Windows, Ubuntu 24.04.4 LTS
   установлена в 511,4 GiB свободного пространства без форматирования ESP.
4. GRUB/UEFI: Windows Boot Manager сохранён, меню видно 10 секунд, последняя ОС
   запоминается. Создана инструкция восстановления.
5. Ubuntu base: hostname `local-ai`, key-only SSH, UFW, Fail2Ban, время Moscow,
   16 GiB swap, unattended upgrades, fstrim, каталоги `/opt/local-ai` и
   `/srv/local-ai`.
6. NVIDIA/CUDA: driver 595.84, CUDA Toolkit 13.2, PyTorch 2.12.0+cu132, GPU
   compute capability 12.0 проверена под нагрузкой.
7. llama.cpp b10210 собран с CUDA. Qwen3-14B Q4_K_M проверен на русском через
   OpenAI API: 64,736 tok/s в коротком generation test.
8. Open WebUI 0.9.5 доступен только с IP контроллера; runtime plugins/code
   execution/signup отключены.
9. ComfyUI v0.29.2 + SDXL Base 1.0: HTTP и реальная генерация 768×768 проверены.
10. faster-whisper 1.2.1 `turbo`: отдельное окружение, OpenAI-compatible API,
    лимит 512 MiB, русский WAV распознан дословно.
11. VRAM mode для LLM/ComfyUI/Whisper, health/cleanup/backup systemd timers.
12. Read-only VPN-план `hometele` подготовлен и затем отдельно подтверждён.
13. Qwen3-Coder-30B-A3B Q4_K_M и официальный Qwen3-VL-8B Q4_K_M/mmproj
    загружены с проверкой размера/SHA256 и прошли по одному API-запросу.
14. SAM 2.1 Hiera Small установлен в отдельном environment; 18-frame tracking,
    сохранение масок и H.264 NVENC сборка с исходным AAC прошли.
15. Pinned Manager, VideoHelperSuite, SAM2, RIFE, ControlNet Aux и WanVideoWrapper
    установлены без исполнения сторонних install scripts; 857 nodes загружены.
16. Финальный reboot пройден: key-only SSH, Qwen3-14B, Open WebUI и timers
    вернулись автоматически; ComfyUI/Whisper остались on-demand.
17. Созданы проверяемая конфигурационная backup-копия и итоговый
    `inventory/ubuntu-after.txt`; post-boot health-check — 0 ошибок.
18. Владелец физически выбрал Windows Boot Manager и подтвердил успешную загрузку
    Windows после установки Ubuntu.
19. Контрольная точка №3 применена: `openvpn-server@local-ai` на `tun93`,
    `10.93.0.0/24`, UDP `21200`, отдельные CN `local-ai`/`owner-laptop`, без
    NAT, DNS и default route. Ubuntu `.10` и Windows `.11` подключены с
    автозагрузкой; SSH/API/WebUI проверены через VPN.
20. На Windows установлены и проверены Aider `0.86.2` и OpenCode `1.18.10` с
    локальным Qwen3 Coder через `10.93.0.10:8080/v1`.

## Контрольная точка №3 — завершена

Live-аудит показал, что прежний WIKI inventory устарел и существующих OpenVPN
instances на текущем сервере нет. Применён только изолированный instance;
nginx, SSH, Docker и существующие firewall rules сохранены. Точный результат —
`docs/control-point-3-vpn-plan.md`.

## Ограничения

- Не сохранять пароли, private keys, recovery keys, токены и VPN profiles в Git.
- Не публиковать порты AI напрямую в интернет.
- Не запускать одновременно LLM, diffusion, Whisper и SAM 2 на 12 GiB VRAM.
- Не выполнять массовые обновления моделей/custom nodes без pinned version,
  source/license review и rollback.
- Не хранить `.ovpn` профили и встроенные клиентские private keys в репозитории;
  защищённые рабочие копии находятся только на соответствующих устройствах.
