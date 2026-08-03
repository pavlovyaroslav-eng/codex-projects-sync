# APT installation plan — simulation only

Дата: 2026-08-02  
Источник: текущие Ubuntu 24.04 Noble package indexes на `local-ai`  
Команда: `apt-get --print-uris --yes --download-only -o Debug::NoLocking=true
install ...`

APT indexes не обновлялись; пакеты не скачивались и не устанавливались.

## Уже присутствует

`build-essential`, `pkg-config`, `ccache`, `curl`, `ca-certificates`,
`python3-venv`, `python3-pip`, `file`, `binutils`, `xxd`, `gdb`, `strace`, `jq`
и `unzip` уже установлены в актуальных версиях доступного индекса.

## Предлагаемые группы

| Группа | Верхнеуровневые пакеты | Новых пакетов | Download | Disk |
|---|---|---:|---:|---:|
| base-static | `hexedit ltrace ripgrep p7zip-full cabextract libimage-exiftool-perl yara clamav` | 20 | 23.7 MB | 86.4 MB |
| binwalk | `binwalk` | 143 | 103 MB | 447 MB |
| guestfs | `libguestfs-tools xorriso` | 112 | 62.9 MB | 280 MB |
| Java/Android apt | `openjdk-21-jdk apktool` | 74 | 120 MB | 187 MB |
| rootless Podman | `podman uidmap slirp4netns fuse-overlayfs` | 17 | 32.5 MB | 131 MB |
| KVM/libvirt | `qemu-system-x86 libvirt-daemon-system libvirt-clients virt-manager ovmf swtpm` | 86 | 46.7 MB | 209 MB |

`qemu-kvm` в текущем индексе является неразрешённым virtual/transitional
именем; для воспроизводимости используется точный `qemu-system-x86`.

## Кандидаты основных пакетов

- hexedit 1.6-1; ltrace 0.7.3-6.4ubuntu3; ripgrep 14.1.0-1;
- p7zip-full 16.02+transitional.1; cabextract 1.11-2;
- ExifTool 12.76; YARA 4.5.0; ClamAV 1.5.3;
- binwalk 2.3.4 из Ubuntu — устарел относительно официального v3.1.0;
- libguestfs-tools 1.52.0; xorriso 1.5.6;
- OpenJDK 21.0.11; Ubuntu apktool 2.7.0 устарел относительно официального 3.0.3;
- Podman 4.9.3; libvirt 10.0.0; QEMU 8.2.2; virt-manager 4.1.0;
- OVMF 2024.02; swtpm 0.7.3.

Поэтому `binwalk` и `apktool` не следует устанавливать из APT вслепую:
предпочтительны изолированная установка официального binwalk 3.1.0 и
официальный `apktool_3.0.3.jar` с зафиксированным SHA-256.

## Службы и сетевое влияние

- base-static может создать/запустить `clamav-freshclam.service`; новых
  TCP-listeners не ожидается, но статус и сеть надо проверить после установки;
- Podman не требует постоянного root daemon и не должен открывать порт;
- libvirt создаёт systemd units/sockets и может создать default NAT network
  (`virbr0`/dnsmasq). Для аналитической VM default network не включать
  автоматически; сначала определить isolated libvirt network;
- Ghidra, JADX, apktool, capa и Rizin не создают службы;
- pyghidra-mcp создаст отдельный loopback-only service на 127.0.0.1:8000 после
  отдельного этапа.

Перед фактическим `apt install` повторить `apt update` только после
подтверждения, сохранить полный simulation log и заново показать зависимости,
download/disk size, создаваемые units и порты.

