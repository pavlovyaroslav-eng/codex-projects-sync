# Rollback

Откат выполнять с физической консоли или по существующему SSH, обычным sudo с
паролем. Не удалять модели/релизы до проверки восстановленной службы.

## Вернуть прежний LLM

```bash
sudo systemctl disable --now qwen3-coder.service
sudo tar -C / -xzf /srv/local-ai/backups/ai-station-bootstrap-20260802T191338Z/pre-qwen-service.tar.gz
sudo systemctl daemon-reload
sudo systemctl enable --now local-ai-autostart.service
sudo systemctl start local-ai-llama.service
curl -fsS http://127.0.0.1:8080/health
```

До восстановления сверить архив с SHA-256
`3cebcd967e2c9a5f306239105b81179d31fd8046446a502e7d98fd13b5396985`.
Новый GGUF можно оставить выключенным; это безопаснее удаления.

## Qwen Code

Выбрать последний нужный каталог
`~/ai-station-bootstrap/backups/qwen-code-*/`, проверить вложенные `.sha256` и
вернуть `settings.json`, `trustedFolders.json`, `.env` и `QWEN.md` в
`~/.qwen/`. Wrapper `/opt/ai-stack/bin/qwen` восстанавливать только после
сравнения с `opt-ai-stack-bin-qwen` из того же backup.

## Совместимый API 8080

Точный backup unit и health-check:
`/srv/local-ai/backups/api-compat-20260802T203904Z/`. Инструкция находится в
`ROLLBACK.txt`. Краткое отключение внешнего endpoint без остановки backend:

```bash
sudo systemctl disable --now local-ai-qwen3-tool-proxy.service
curl -fsS http://127.0.0.1:8012/health
```

UFW при установке адаптера не менялся, поэтому firewall rollback не требуется.

## Ghidra MCP

```bash
sudo systemctl disable --now pyghidra-mcp.service
```

Предыдущий unit сохранён в
`/srv/local-ai/backups/ai-station-bootstrap-20260802T183300Z/`. Перед
восстановлением проверить SHA-256, затем выполнить `systemd-analyze verify`,
`daemon-reload` и только после этого запуск. Удалять venv или Ghidra для
отключения не требуется.

## Статический контейнер и VM

Rootless image можно вывести из эксплуатации без удаления:

```bash
podman image exists localhost/ai-static-tools:1.0
```

VM откатывается к проверенному состоянию командой
`virsh -c qemu:///system snapshot-revert windows-analysis empty-template`.
Для полного вывода VM из эксплуатации сначала выключить её, сохранить XML и
qcow2, затем отключить autostart сети. Не использовать `undefine --remove-all-storage`
и не удалять qcow2 автоматически.

## Базовые пакеты и конфигурация

Полный pre-base archive:
`/srv/local-ai/backups/ai-station-bootstrap-20260802T145102Z/pre-base-config.tar.gz`
(SHA-256 `ba98213c1b3ed9d6fc11480f5258ce3ff5fb5faa04b3caacab36e0b4fe1e75d9`).
Массовое удаление APT packages не является безопасным автоматическим откатом;
сначала использовать `apt-get --simulate remove` и проверить зависимости.

EFI, GRUB, Windows Boot Manager и разделы в ходе установки не менялись и
отката не требуют.

## Health timer

Предыдущие варианты `/usr/local/sbin/local-ai-health-check` сохранены в:

- `/srv/local-ai/backups/ai-station-bootstrap-20260802T200840Z/`;
- `/srv/local-ai/backups/ai-station-bootstrap-20260802T201351Z/`.

Для отката выбрать нужный `local-ai-health-check`, проверить соседний SHA-256,
выполнить `bash -n`, установить как `root:root 0755`, затем запустить
`local-ai-health.service` и проверить `/var/lib/local-ai/health-latest.txt`.
