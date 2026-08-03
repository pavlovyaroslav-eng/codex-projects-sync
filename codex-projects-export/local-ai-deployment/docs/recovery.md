# Восстановление загрузки и конфигурации

## GRUB/Ubuntu

Загрузить Ubuntu 24.04 USB именно в UEFI mode, смонтировать установленный root и
существующий EFI System Partition, затем выполнить chroot:

```bash
sudo mount /dev/nvme0n1p4 /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot/efi
for path in /dev /dev/pts /proc /sys /run; do sudo mount --bind "$path" "/mnt$path"; done
sudo chroot /mnt /usr/local/sbin/local-ai-recover-grub
```

Скрипт проверяет UEFI и mount `/boot/efi`, переустанавливает только Ubuntu GRUB,
обновляет меню и выводит `efibootmgr -v`. EFI-раздел не форматируется.

## Windows Boot Manager

Если требуется восстановить только Windows, загрузить Windows Recovery USB в
UEFI mode, открыть Command Prompt, определить букву Windows и EFI через
`diskpart`, временно назначить EFI букву `S:`, затем:

```text
bcdboot C:\Windows /s S: /f UEFI
bcdedit /enum firmware
```

Команда восстанавливает файлы Microsoft Boot Manager; она не должна форматировать
EFI. После восстановления Windows загрузки GRUB можно вернуть инструкцией выше.

## Конфигурация Local AI

Проверить SHA256 архива в `/srv/local-ai/backups`, распаковать его во временный
каталог и сравнить изменения до копирования:

```bash
sha256sum -c local-ai-config-YYYYmmddTHHMMSSZ.tar.zst.sha256
mkdir /tmp/local-ai-restore
tar --zstd -xf local-ai-config-YYYYmmddTHHMMSSZ.tar.zst -C /tmp/local-ai-restore
sudo diff -ruN /etc/local-ai /tmp/local-ai-restore/etc/local-ai
```

Восстановление выполняется выборочно. Не копировать архив поверх `/etc` целиком и
не восстанавливать старые systemd units без просмотра diff.

