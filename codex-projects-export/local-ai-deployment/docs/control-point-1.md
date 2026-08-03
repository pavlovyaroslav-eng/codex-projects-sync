# Контрольная точка №1 — Windows, железо и вариант ОС

Дата: 2026-07-31  
Статус: аудит завершён; диски, EFI/BCD, Fast Startup и сервер `hometele` не
изменялись.

## Решение

Dual boot технически допустим: системный диск исправен, GPT/UEFI уже настроены,
BitLocker отсутствует, C: имеет достаточно свободного места и штатно уменьшается.
Но приступать к разметке можно только после устранения перечисленных ниже
блокеров и отдельного подтверждения контрольной точки №2.

## Ответы контрольной точки

1. **Можно ли безопасно ставить Ubuntu?** Условно да. Сначала нужны проверенная
   внешняя копия важных данных, Windows Recovery USB, обновление firmware 990 PRO,
   проверка RAM и отключение Fast Startup. Никакие разделы пока не изменены.

2. **Какой диск и раздел?** Только Disk 0 `Samsung SSD 990 PRO 1TB`, GPT,
   серийный номер из закрытого inventory. Уменьшать штатным Windows API только
   Partition 3, NTFS C:. Partition 1 EFI 100 MiB и Partition 2 MSR 16 MiB не
   форматировать и не удалять. USB Disk 2/E: пока не трогать.

3. **Сколько места выделить?** Предложение для контрольной точки №2:

   | Объект | Текущий размер | Предлагаемый размер | Назначение |
   |---|---:|---:|---|
   | Windows C: NTFS | 931,40 GiB | 420 GiB | Windows и запас около 152 GiB при текущем использовании |
   | Ubuntu `/` ext4 | — | 200 GiB | ОС, пакеты, venv, контейнерные слои и логи |
   | Ubuntu `/srv/local-ai` ext4 | — | около 311 GiB | модели, datasets, ComfyUI и медиа |
   | swapfile | — | 16 GiB внутри Linux | аварийный запас; отдельный swap-раздел не нужен |

   Числа предварительные: перед применением будет повторный снимок размеров и
   таблица «до/после». Файлы моделей не должны храниться в root без лимитов.

4. **Основные риски.** WinRE отсутствует; Recovery-раздела нет. Прошивка 990 PRO
   `4B2QJXD7` отстаёт от официальной `8B2QJXD7`; зарегистрированный максимум
   температуры NVMe — 82 °C. Fast Startup включён. Secure Boot не подтверждён,
   BCD содержит `flightsigning Yes`. Windows видит один NUMA-узел вместо двух.
   Нет результата memory test и CPU temperature sensors. Defender отключён без
   зарегистрированного альтернативного антивируса. RDP с пустым паролем/без NLA
   остаётся ослаблением, хотя firewall ограничивает его одним IP.

5. **Что упрощает dual boot?** Windows уже загружается в UEFI с GPT, BitLocker
   полностью отключён, ESP здоров и имеет около 69,45 MiB свободно, а штатный
   предел уменьшения C: — 399,12 GiB. Предлагаемые 420 GiB выше этого предела на
   20,88 GiB.

6. **Нужен ли загрузочный носитель?** Да, два логически разных носителя:
   Windows Recovery USB и Ubuntu USB. Имеющийся 64‑GB USB может стать одним из
   них только после подтверждения, что его можно полностью стереть. Для второго
   нужен ещё один накопитель либо последовательная перезапись после проверки
   восстановления.

7. **Физические действия владельца до контрольной точки №2.** Сделать backup на
   другой физический диск; подготовить и проверить загрузку Windows Recovery USB;
   обновить Samsung 990 PRO через Samsung Magician при стабильном питании и
   перезагрузить; заменить Ethernet-кабель/порт и добиться 1 Gbps; прислать фото
   BIOS страниц Secure Boot, CSM и NUMA/Node Interleaving; выполнить расширенный
   тест памяти. Для Ubuntu USB использовать только официальный ISO и проверить
   SHA256.

8. **Windows native, WSL2 или Ubuntu dual boot?** Для этого проекта рекомендуется
   Ubuntu dual boot: прямой GPU, штатные systemd/UFW/Fail2Ban/OpenVPN и меньше
   расхождений с Linux-first AI-инструментами. WSL2 — хороший запасной вариант,
   если Recovery USB/backup сделать нельзя; Windows native оставляем для RDP и
   задач, требующих Windows.

## Выбор Ubuntu и GPU-стека

Решение владельца от 2026-07-31: использовать **Ubuntu 24.04.4 Desktop AMD64**.
Точная схема вынесена в [контрольную точку №2](control-point-2.md).

- Ubuntu 26.04 LTS выпущена 2026-04-23; Canonical назначила 26.04.1 на
  2026-08-04. Для этой машины выбран более консервативный Ubuntu 24.04.4 LTS.
- NVIDIA официально поддерживает Ubuntu 24.04 и 26.04 в текущем Linux driver
  guide; CUDA 13.3 квалифицирует обе системы.
- PyTorch публикует Linux/Windows wheels для CUDA 12.8 и более новых веток.
  Полный CUDA Toolkit не следует ставить автоматически: для ComfyUI/SAM 2 обычно
  достаточно runtime из PyTorch wheel; `nvcc` добавляется только при необходимости
  сборки расширений.

Официальные источники:

- [Ubuntu 26.04 release announcement](https://lists.ubuntu.com/archives/ubuntu-announce/2026-April/000323.html)
- [Ubuntu 26.04 official images and SHA256SUMS](https://releases.ubuntu.com/releases/26.04/)
- [NVIDIA driver guide for Ubuntu](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/ubuntu.html)
- [CUDA Linux supported distributions](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)
- [PyTorch installation selector](https://pytorch.org/get-started/locally/)
- [Samsung SSD firmware downloads](https://semiconductor.samsung.com/consumer-storage/support/tools/)

## Стоп-условие

До явного подтверждения этой контрольной точки не уменьшать C:, не создавать
Linux-разделы, не менять BCD/ESP, не отключать Fast Startup и не стирать USB.
