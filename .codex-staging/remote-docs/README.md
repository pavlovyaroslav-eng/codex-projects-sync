# AI Station Bootstrap

Воспроизводимая конфигурация удалённой станции `local-ai` (`192.168.1.65`) на
Ubuntu 24.04.4 LTS. Станция работает в одной LAN с ноутбуком Acer. Сам LLM и
MCP остаются loopback-only; совместимый OpenAI API опубликован адаптером на
`:8080` только для контроллера Acer и клиентов изолированного OpenVPN `tun93`.

## Состояние

- `qwen3-coder.service`: Qwen3-Coder-30B-A3B Q4_K_M, OpenAI API
  `http://127.0.0.1:8012/v1`, active/enabled;
- `local-ai-qwen3-tool-proxy.service`: внешний совместимый endpoint
  `http://10.93.0.10:8080/v1` → `127.0.0.1:8012`, active/enabled;
- `pyghidra-mcp.service`: PyGhidra MCP `http://127.0.0.1:8000/mcp`,
  active/enabled;
- Qwen Code 0.21.3 использует только локальный endpoint, approval mode
  `default`, folder trust и MCP `ghidra`;
- Ghidra 12.1.2 установлена в `/opt/ghidra`, GUI/headless проверены;
- rootless Podman и образ `localhost/ai-static-tools:1.0` готовы для
  безсетевого статического анализа;
- KVM/libvirt и выключенный шаблон `windows-analysis` готовы; сеть VM не имеет
  forwarding, shared folders/clipboard/file transfer отсутствуют;
- Windows в VM не установлена: лицензионный ISO не предоставлен;
- прежние `/opt/local-ai`, `/srv/local-ai` и Coder GGUF сохранены для отката.
- `local-ai-health.timer` проверяет Qwen 8012, совместимый API 8080 и MCP 8000;
  post-reboot
  oneshot завершился с `Result: 0 error(s)` и failed units отсутствуют.

Полная проверка: [`reports/FINAL_VERIFICATION.md`](reports/FINAL_VERIFICATION.md).
Измерения: [`reports/LLAMA_BENCHMARK.md`](reports/LLAMA_BENCHMARK.md).
Ошибки и ограничения: [`reports/FAILED_STEPS.md`](reports/FAILED_STEPS.md).

## Основные команды

```bash
ai-model-status
ai-model-test
ai-model-logs
qwen
ghidra
ai-ingest-file /path/to/file
ai-static-scan /path/to/file
ai-software-search <query>
ai-software-plan <package>
```

Запуск/остановка модели выполняются командами `ai-model-start`,
`ai-model-stop`, `ai-model-restart` и требуют обычного sudo с паролем.
`ai-software-install` требует буквального подтверждения `INSTALL` и sudo; YOLO
и широкие sudoers-правила не используются.

## Репозиторий

Поэтапные скрипты находятся в `scripts/00-*` … `scripts/99-*`, тесты — в
`tests/`, журналы — в `logs/`, отчёты — в `reports/`. Перед заменой существующих
конфигураций создавались архивы в `/srv/local-ai/backups/` или точечные копии в
`backups/`. Репозиторий инициализирован как Git `main`; commit не создавался,
поскольку владельцем не задана Git identity.

Не выполнялись изменения дисков, разделов, EFI/GRUB, BIOS, Secure Boot, SSH,
UFW или Windows Boot Manager. Разрешённая перезагрузка выполнена; автозапуск
Qwen, MCP, health timer, NVIDIA и изолированной libvirt-сети проверен.
