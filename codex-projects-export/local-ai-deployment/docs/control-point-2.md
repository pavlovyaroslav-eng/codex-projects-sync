# Контрольная точка №2 — фактический Ubuntu dual boot

Дата решения: 2026-07-31  
ОС: Ubuntu 24.04.4 Desktop AMD64  
Статус: подтверждена владельцем, применена; Ubuntu загружена и настроена.

Целевой накопитель: Samsung SSD 990 PRO 1 TB, GPT. Windows C: был уменьшен
штатным `Resize-Partition` до 420 GiB, после чего установщик Ubuntu использовал
освободившиеся 511,4 GiB.

## Фактическая таблица после установки

| Устройство | Файловая система/размер | Фактическое действие | Mount point/статус |
|---|---|---|---|
| `/dev/nvme0n1p1` | EFI System FAT32, 100 MiB | не форматировался; добавлен Ubuntu bootloader | `/boot/efi` |
| `/dev/nvme0n1p2` | Microsoft Reserved, 16 MiB | без изменений | — |
| `/dev/nvme0n1p3` | Windows NTFS, 420 GiB | без изменений после shrink | Windows C: сохранён |
| `/dev/nvme0n1p4` | ext4, около 511,4 GiB | создан установщиком Ubuntu | `/` |
| `/swap.img` | swap file, 16 GiB | создан после установки | swap |

Предварительный план предполагал отдельные `/` и `/srv/local-ai`, но в ручном
установщике владелец создал один Linux ext4-раздел. Это работоспособно; каталог
`/srv/local-ai` расположен на root и контролируется health-check порогом свободного
места 50 GiB. Windows-раздел из Linux не изменялся.

## Проверенный результат

- Ubuntu загружается в UEFI, ESP смонтирован без форматирования.
- `efibootmgr` содержит Ubuntu и Windows Boot Manager.
- GRUB видим, timeout 10 секунд, `GRUB_DEFAULT=saved`, `GRUB_SAVEDEFAULT=true`.
- В меню GRUB присутствует Windows Boot Manager.
- BitLocker был выключен; Fast Startup/hibernation отключены до установки.
- NVMe SMART здоров: 0 media errors, 0% wear.
- Root имеет достаточное место для установленного набора моделей.

Физическая загрузка Windows через GRUB после установки Ubuntu остаётся ручной
проверкой владельца. Наличие EFI entry/menuentry подтверждено, но удалённо
переключать ОС без гарантированного обратного канала не выполнялось.

Инструкции восстановления обеих загрузок: [`recovery.md`](recovery.md).

