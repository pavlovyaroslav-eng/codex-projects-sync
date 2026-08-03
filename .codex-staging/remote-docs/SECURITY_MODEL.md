# Security model

## Границы доверия

- Ubuntu `local-ai` — основной вычислительный хост; Acer — административный
  клиент, а не место установки.
- Файлы в `incoming` и `quarantine` недоверенные: их запрещено исполнять на
  хосте. Первичная обработка — только статическая.
- Динамический анализ разрешён только в `windows-analysis` после установки
  лицензированной Windows владельцем.
- SSH keys, токены, VPN-профили и сертификаты в репозиторий не добавляются.
  Значение `local-not-required` — не секрет, а фиктивный ключ для локального
  OpenAI-compatible клиента.

## Реализованные меры

- LLM слушает только `127.0.0.1:8012`, MCP — только `127.0.0.1:8000`;
  соединения с Acer на LAN-адрес этих портов истекают по timeout. Отдельный
  совместимый адаптер слушает `0.0.0.0:8080`, но UFW допускает к нему только
  контроллер `192.168.1.41/32` и `10.93.0.0/24` через `tun93`.
- `qwenllm` и `ghidramcp` — системные пользователи с `nologin`; services имеют
  `NoNewPrivileges`, filesystem/kernel hardening и IPAddressDeny/Allow.
- Qwen Code использует approval mode `default`, включённый folder trust и один
  явный MCP `ghidra`. YOLO не включён, `/` и весь home не доверены.
- rootless Podman запускает статические утилиты с `--network none`, read-only
  input, tmpfs, drop-all capabilities и без host secrets/devices/sockets.
- VM использует сеть без forwarding, loopback SPICE, read-only ISO; shared
  folders, clipboard, file transfer, drag-and-drop и USB redirection отсутствуют.
- временный унаследованный `/etc/sudoers.d/90-local-ai-user` с
  `NOPASSWD: ALL` удалён после последней привилегированной операции; итоговый
  кандидат без этого drop-in заранее проверен `visudo -cf`, а новый SSH-сеанс
  подтвердил, что `sudo -n` теперь требует пароль.
- UFW, SSH, диски, partitions, EFI/GRUB, BIOS и Secure Boot не изменялись.

## Остаточные риски

- Legacy Open WebUI после reboot не запущен и порт 3000 не слушает; прежние UFW
  rules сохранены, но не имеют соответствующего listener.
- API `:8080` не имеет отдельной application-аутентификации: границей доверия
  служат source-limited UFW и сертификаты изолированного OpenVPN. Публичного
  DNAT/port-forward нет; VPN-профили считаются административными секретами.
- ClamAV базы отсутствуют до окончания CDN cooldown; YARA/capa и прочий
  статический анализ работают, но ClamAV не считается защитным сигналом.
- В текущей загрузке было 16 исторических Correctable PCIe AER событий GPU,
  без Xid/Fatal/Non-Fatal; после CUDA и LLM нагрузок новых событий не найдено.
- VM пока без Windows, поэтому безопасность guest OS и отсутствие guest
  internet после установки ещё требуют отдельной проверки.
- Реальный reboot выполнен: Qwen, MCP, NVIDIA, health timer и изолированная
  libvirt-сеть вернулись в ожидаемое состояние. Позднее намеренно добавлен один
  wildcard listener `:8080`, защищённый прежними UFW rules; failed units нет.
