# Hardware report — этап 1 (до изменений)

Дата сбора: 2026-07-31 21:02–21:25 MSK  
Компьютер: `WIN-27KGFBIDMBS` (`192.168.1.65`)

## Операционная система и прошивка

- Windows 10 Enterprise 22H2, build 19045, x64.
- Материнская плата сообщает только общее имя `INTEL X99`; BIOS AMI 5.11 от
  2024-03-06. Перед изменением NUMA/Secure Boot нужны фотографии экранов BIOS.
- Загрузка Windows идёт в UEFI с GPT через
  `\EFI\MICROSOFT\BOOT\BOOTMGFW.EFI`; Legacy/MBR не используются.
- Secure Boot не подтверждён как включённый: `Confirm-SecureBootUEFI` возвращает
  ошибку `0xC0000100`, а ключ состояния Secure Boot отсутствует.
- В BCD у Windows Boot Manager и текущего загрузчика установлено необычное
  `flightsigning Yes`. На этапе аудита BCD не изменялся.
- BitLocker на C: и E: отключён, тома полностью расшифрованы, key protectors
  отсутствуют.
- Fast Startup включён (`HiberbootEnabled=1`), гибернация доступна. Перед dual
  boot его надо отключить, но только после контрольной точки №2.
- WinRE неработоспособна: `reagentc /info` возвращает exit 3 («конечная установка
  Windows не найдена»); `ReAgent.xml` и проверенные копии `Winre.wim` отсутствуют.

Подробности: [windows-boot-before.txt](inventory/windows-boot-before.txt) и
[stage1-critical-recheck.txt](inventory/stage1-critical-recheck.txt).

## CPU, RAM и NUMA

- 2 × Intel Xeon E5-2680 v4, по 14 ядер / 28 потоков; всего 28 физических и 56
  логических процессоров.
- RAM: 63,88 GiB, 4 модуля.
- Windows API подтверждает AVX=True и AVX2=True.
- ОС видит только один NUMA-узел (`HighestNumaNode=0`), несмотря на два сокета.
  Вероятная причина — Node Interleaving/UMA в BIOS; это надо проверить до
  настройки производительности llama.cpp.
- Точные CPU-температуры через ACPI не доступны. Нужны HWiNFO/IPMI либо BIOS.
- События провайдера `Microsoft-Windows-WHEA-Logger` за 30 дней: 0. Прежнее
  совпадение ID 18 было информационным событием `Kernel-Boot`, а не WHEA.
- Результатов Windows Memory Diagnostic за 365 дней: 0; тест памяти ещё не
  выполнялся.

## GPU

- NVIDIA GeForce RTX 5070, 12227 MiB VRAM.
- Windows-драйвер 572.70 от 2025-03-03.
- Во время простоя: 41 °C, 8,84 W из лимита 250 W, P8.
- `nvidia-smi` работает; CUDA Toolkit/`nvcc` в Windows не установлен.
- Короткий GPU-стресс-тест не запускался до проверки охлаждения.

Подробности: [gpu-before.txt](inventory/gpu-before.txt).

## Накопители и разделы

- Disk 0: Samsung SSD 990 PRO 1TB, NVMe, GPT, 1 000 204 886 016 bytes
  (931,51 GiB), firmware `4B2QJXD7`, health `Healthy`, wear 0.
- NVMe temperature 43 °C; записанный максимум 82 °C. Максимальные latency
  counters: read 1392 ms, write 1394 ms, flush 589 ms. Счётчики ошибок драйвер
  не предоставил.
- На официальной странице Samsung актуальная прошивка 990 PRO — `8B2QJXD7`;
  текущая `4B2QJXD7` устарела. Обновление допустимо только после backup и
  отдельного подтверждения, до изменения разделов.
- Disk 2: `Generic MassStorageClass`, USB, MBR, 63 864 569 856 bytes
  (59,48 GiB). Раздел E: почти пуст по данным Windows, но filesystem определяется
  как `Unknown`; уничтожать или переиспользовать без явного подтверждения нельзя.

| Disk 0 | Назначение | FS | Размер | Свободно | Действие сейчас |
|---|---|---:|---:|---:|---|
| Partition 1 | EFI System | FAT32 | 100 MiB | 69,45 MiB | не менять |
| Partition 2 | Microsoft Reserved | — | 16 MiB | — | не менять |
| Partition 3 | Windows C: | NTFS | 931,40 GiB | 663,47 GiB | не менять |

Recovery-раздел отсутствует. Штатный Windows API сообщает для C: минимальный
поддерживаемый размер 399,12 GiB. Предлагаемый размер 420 GiB оставляет запас
20,88 GiB над этим минимумом и создаёт около 511,40 GiB неразмеченного места.

Подробности: [disk-layout-before.txt](inventory/disk-layout-before.txt) и
[stage1-followup.txt](inventory/stage1-followup.txt).

## Сеть и удалённое администрирование

- Realtek PCIe GbE Family Controller, MAC `00-E0-21-A9-50-30`.
- Линк согласован только на 100 Mbps; ошибок и discarded packets нет.
- Драйвер Realtek 9.1.410.2015 от 2015-04-10, Speed & Duplex = Auto Negotiation.
  До загрузки моделей нужно проверить кабель и гигабитный порт, затем подобрать
  драйвер по точному hardware ID.
- SSH работает только по отдельному ключу; старый ошибочно зашифрованный ключ
  отозван после проверки нового.
- RDP с пустым паролем и без NLA включён по явному решению владельца; RDP, SMB и
  WinRM ограничены Windows Firewall адресом контроллера `192.168.1.41/32`.
- Microsoft Defender, Network Inspection Service и Windows Security Health
  Service отключены; альтернативный антивирус в Security Center не найден.
  Bootstrap этого не делал. Windows Firewall включён во всех трёх профилях.

## Итог этапа 1

Аппаратная конфигурация подходит для Ubuntu dual boot и локального AI, но
изменять разделы пока небезопасно. Блокеры: отсутствующий WinRE/Recovery USB,
устаревшая прошивка системного NVMe, включённый Fast Startup, неиспытанная RAM,
неясный Secure Boot/NUMA BIOS state и 100‑Мбит/с сетевой линк. Точная рекомендация
и схема приведены в [контрольной точке №1](docs/control-point-1.md).

