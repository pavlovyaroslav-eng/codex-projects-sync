# NVIDIA verification report

Дата проверки: 2026-08-02 18:13 MSK  
Хост: `local-ai`  
ОС: Ubuntu 24.04.4 LTS  
Ядро: `7.0.0-28-generic`

## Источники решения

- живой вывод `lspci`, `ubuntu-drivers`, APT, `modinfo`, `nvidia-smi` и
  `journalctl` на целевой станции;
- официальная документация Ubuntu:
  <https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/>;
- официальный пакет Ubuntu:
  <https://packages.ubuntu.com/noble/nvidia-driver-595-open>.

## GPU и рекомендация Ubuntu

- GPU: NVIDIA GeForce RTX 5070;
- PCI ID: `10de:2f04`, subsystem `1458:417e`, address `0000:02:00.0`;
- VRAM по NVML: 12227 MiB;
- kernel driver in use: `nvidia`;
- рекомендованный пакет: `nvidia-driver-595-open`;
- установленная версия: `595.84-0ubuntu0.24.04.1`;
- APT candidate: `595.84-0ubuntu0.24.04.1`;
- симуляция установки: 0 upgraded, 0 newly installed, 0 removed.

Вывод: переустановка не нужна. Перезагрузка не запрашивалась и не выполнялась.

## Модуль ядра

- runtime module: NVIDIA UNIX Open Kernel Module 595.84;
- лицензия: `Dual MIT/GPL`;
- подпись: `Canonical Ltd. Kernel Module Signing`, PKCS#7;
- файл: `/lib/modules/7.0.0-28-generic/kernel/nvidia-595-open/nvidia.ko`;
- пакет: `linux-modules-nvidia-595-open-7.0.0-28-generic`
  `7.0.0-28.28~24.04.1+3`;
- `nouveau` не загружен;
- DKMS не установлен и не нужен для используемого prebuilt module;
- `mokutil` сообщает, что система не поддерживает Secure Boot.

## Runtime и CUDA

- `nvidia-smi` успешно видит RTX 5070 и driver 595.84;
- idle state при аудите: 35 °C, около 7.89 W;
- PCIe runtime после CUDA: Gen3 x16, что соответствует максимуму root port;
- CUDA Toolkit уже существовал: 13.2.2, `nvcc` 13.2.86;
- `tests/cuda-smoke.cu` скомпилирован с `-arch=native`;
- kernel launch, synchronization, H2D/D2H copy и проверка результата успешны;
- результат: `CUDA_OK`, compute capability 12.0, значение 42.

## Kernel journal и PCIe

- `NVRM Xid`: 0;
- Fatal/Non-Fatal AER: 0 по текущему `lspci -vv`;
- Correctable PCIe AER для GPU: 16 событий в текущей загрузке;
- тип: Data Link Layer, Transmitter ID, Timeout;
- первое: 2026-08-01 08:35:11 MSK;
- последнее: 2026-08-02 12:54:39 MSK;
- после CUDA smoke в 18:10 новых NVIDIA kernel events нет.

Correctable AER не равен подтверждённому отказу GPU: runtime, CUDA и AI API
работают. Возможные аппаратные причины — гипотезы, а не установленный диагноз.
Если события возобновятся, безопасный следующий порядок: мониторинг счётчика,
затем отдельное согласование остановки станции и физической проверки посадки
карты, кабелей питания и режима PCIe в BIOS.

## Изменения и откат

Пакеты, модули, initramfs, GRUB, BIOS и systemd не изменялись. Откат NVIDIA не
требуется. Для документации backup перед записью:
`/home/user/ai-station-bootstrap/backups/docs-20260802T151306Z`.
