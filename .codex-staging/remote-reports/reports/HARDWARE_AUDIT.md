# Hardware audit — local-ai

Дата live-аудита: 2026-08-02 15:51:52 MSK  
Target: `user@192.168.1.65` (`local-ai`)  
Режим: read-only SSH без `sudo`

## Итог

Это заявленная ИИ-станция: 2 × Xeon E5-2680 v4, 64 GiB RAM, RTX 5070 12 GiB и
Samsung 990 PRO 1 TB. Ubuntu уже установлена рядом с Windows, а существующие
llama.cpp и модели работают. Новые установки не выполнялись.

## ОС и прошивка

- Ubuntu 24.04.4 LTS, kernel `7.0.0-28-generic`, x86-64.
- Плата: `INTEL X99`; BIOS American Megatrends 5.11 от 2024-03-06.
- Загрузка: UEFI; системный NVMe использует GPT.
- `mokutil --sb-state`: `This system doesn't support Secure Boot`.
- В UEFI присутствуют отдельные записи Ubuntu и Windows Boot Manager.
- Текущий root: `/dev/nvme0n1p4`, ext4, `rw,relatime`.

## CPU, виртуализация и NUMA

- 2 × Intel Xeon E5-2680 v4, 14 ядер/28 потоков на сокет.
- Итого: 28 физических ядер, 56 логических CPU.
- VT-x, EPT, AVX2 присутствуют; `/dev/kvm` существует.
- Пользователь `user` пока не входит в группу `kvm`; QEMU/libvirt не установлены.
- ОС видит один NUMA-узел для обоих сокетов. Перед performance tuning следует
  проверить Node Interleaving/NUMA в BIOS, но BIOS автоматически не менять.

## Память

- Всего по `free -h`: 62 GiB; доступно на момент аудита 51 GiB.
- Swap: файл 16 GiB, использовано 0.

## GPU

- NVIDIA GeForce RTX 5070, 12 227 MiB VRAM.
- Драйвер 595.84; `ubuntu-drivers` помечает установленный пакет
  `nvidia-driver-595-open` 595.84 как recommended; `nvidia-smi` сообщает CUDA
  13.2.
- На момент аудита: 34 °C, P8, занято около 9 195 MiB VRAM работающей LLM.
- CUDA Toolkit 13.2.2 установлен. `nvcc` 13.2.86 найден по точному пути
  `/usr/local/cuda-13.2/bin/nvcc`, но этот каталог отсутствует в обычном `PATH`.

## Накопители и dual boot

| Раздел | FS | Размер | Назначение |
|---|---|---:|---|
| `/dev/nvme0n1p1` | FAT32 | 100 MiB | EFI System, `/boot/efi` |
| `/dev/nvme0n1p2` | — | 16 MiB | Microsoft Reserved |
| `/dev/nvme0n1p3` | NTFS | 420 GiB | сохранённая Windows |
| `/dev/nvme0n1p4` | ext4 | 511.4 GiB | Ubuntu `/` |

Root filesystem: 503 GiB usable, 99 GiB used, 379 GiB available. Требование
оставлять не менее 150 GiB свободного места сейчас выполняется.

## Сеть

- `enp5s0`: `192.168.1.65/24`, link 100 Mb/s Full Duplex.
- `tun93`: `10.93.0.10/24` для изолированной административной VPN.
- Default route остаётся через LAN `192.168.1.1`; VPN не заменяет его.
- 100 Mb/s является ограничением для крупных загрузок моделей.

## Инструменты

| Компонент | Факт |
|---|---|
| Python | 3.12.3, `/usr/bin/python3` |
| Git | 2.43.0, `/usr/bin/git` |
| CMake / Ninja | 3.28.3 / 1.11.1 |
| Java | OpenJDK runtime 21.0.11; `javac` отсутствует |
| Docker / Podman | не найдены |
| QEMU / libvirt / virsh | не найдены |
| Node.js / npm | не найдены |
| VS Code CLI | не найден |
| Qwen Code | не найден |
| Ghidra / Ghidra MCP | не найдены |

## Уже существующий AI-стек

- `/opt/local-ai/apps/llama.cpp-b10210` и `/opt/local-ai/src/llama.cpp`;
- Qwen3-14B, Qwen3-Coder-30B-A3B Q4_K_M и Qwen3-VL-8B;
- активны `local-ai-llama.service` и `local-ai-open-webui.service`;
- Coder и tool proxy установлены как on-demand units, но во время аудита
  неактивны;
- `~/AI-Workbench`, `/opt/ghidra`, `/opt/ai-stack` и `/srv/ai` отсутствуют.

## Риски и блокеры

1. `sudo -n -l` показывает широкое `(ALL : ALL) NOPASSWD: ALL`.
2. llama API слушает `0.0.0.0:8080`, а новая политика требует loopback-only.
3. Существующий проверенный Coder GGUF имеет источник `lmstudio-community`, не
   новый приоритет Qwen/Unsloth.
4. Один NUMA-узел может снижать производительность dual-socket системы.
5. Live UFW rules без `sudo` не перечитаны; сетевую защиту нельзя считать
   повторно подтверждённой только по WIKI.
6. `NeedDaemonReload=yes` для llama, Coder и tool-proxy units: файлы на диске
   новее загруженного systemd state. До backup/diff запрещены reload и restart.

## Источники фактов

`hostnamectl`, `/etc/os-release`, `uname`, `/sys/class/dmi/id`, `mokutil`,
`efibootmgr`, `lscpu`, `/proc/cpuinfo`, `/dev/kvm`, `numactl`, `free`, `swapon`,
`lsblk`, `findmnt`, `df`, `nvidia-smi`, `ip`, `ethtool`, `ss`, `command -v`,
version commands, `dpkg-query`, `systemctl`, `sudo -n -l`, `stat` и `find`.
