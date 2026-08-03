# Локальная среда Open Interpreter

- Рабочая система — Windows 11, командная оболочка — PowerShell 7 (`pwsh`).
- Для команд используй нативный синтаксис PowerShell. Не применяй Unix-флаги к
  PowerShell aliases: `ls -a`, `cp -r`, `rm -rf`, `grep -R` и подобные команды
  недопустимы.
- Для показа всех файлов используй `Get-ChildItem -Force`; для рекурсивного
  поиска текста — `rg` или `Get-ChildItem ... | Select-String`.
- Перед выполнением команды учитывай, что `ls` в PowerShell — alias
  `Get-ChildItem`, а параметр `-a` неоднозначен.
- Если команда завершилась ошибкой синтаксиса оболочки, исправь её для
  PowerShell и кратко объясни причину; не трактуй такую ошибку как отказ API.
- Для анализа через MCP `ghidra` вызывай именно инструменты сервера:
  `ghidra/list_project_binaries`, `ghidra/search_symbols_by_name`,
  `ghidra/decompile_function` и другие доступные Ghidra tools. Не используй
  `list_mcp_resources` или `list_mcp_resource_templates`: PyGhidra MCP не
  публикует resources/templates, его функциональность предоставлена tools.
- Не делай вывод, что Ghidra недоступна, только из пустого списка MCP resources.
  Сначала вызови `ghidra/list_project_binaries`; при ошибке сообщи точный код и
  текст именно этого tool call.
- Если пользователь указывает путь к новому бинарнику на Acer, Ghidra не может
  открыть Windows-путь напрямую. Проверь файл локально, скопируй его по SSH на
  `user@10.93.0.10:/home/user/AI-Workbench/incoming/`, затем на станции выполни
  безопасные `ai-ingest-file` и `ai-ghidra-stage` без запуска бинарника. После
  этого вызови `ghidra/import_binary` с полученным remote path и продолжай
  анализ инструментами MCP. Используй SSH-ключ
  `C:\Users\ACER-X-02\.ssh\id_ed25519_local_ai_admin_v2` и
  `HostKeyAlias=192.168.1.65`.
- Никогда не исполняй исследуемый бинарник на Acer или Ubuntu-хосте. Динамический
  анализ допустим только в изолированной VM по отдельному прямому запросу.
