# Ghidra MCP test

Дата: 2026-08-02. Ghidra 12.1.2 PUBLIC, JDK 21, PyGhidra 3.1.0,
pyghidra-mcp 0.2.3. Endpoint: `http://127.0.0.1:8000/mcp`.

## Объекты

Безопасная программа `tests/safe_add.c` собрана с symbols и отдельной stripped
копией. Оба файла staged через `ai-ghidra-stage`, импортированы и автоматически
проанализированы. Для обоих подтверждены `analysis_complete=true`,
`code_indexed=true`, `strings_indexed=true`.

## Реально вызванные MCP tools

- `list_project_binaries` — обе программы обнаружены;
- `search_symbols_by_name` — список функций, `main` и `add_numbers`;
- `list_imports` — `printf`, `__libc_start_main` и runtime imports;
- `search_strings` — строка `Result: %d\n` по адресу `00102004`;
- `decompile_function(main)` — вызов `add_numbers(0x14,0x16)` и `printf`;
- `decompile_function(add_numbers)` — восстановлено `return b + a;`;
- `list_xrefs(add_numbers)` — найден call из `main` по `00101173`;
- `set_comment` — добавлен безопасный decompiler comment;
- `save` — проект сохранён;
- `search_symbols_by_name` для stripped copy — символ `main` ожидаемо не
  найден, обработка завершилась без ошибки.

Все зафиксированные calls имеют `isError=false`. Headless analyzer отдельно
вернул `Analysis succeeded`; GUI foreground smoke под Xvfb прожил 20 секунд без
ошибки и был штатно остановлен timeout-кодом 124.

Полный машинный журнал: `logs/75-ghidra-mcp-test.json`.

## Open Interpreter через VPN — 2026-08-03

Endpoint для Acer: `http://10.93.0.10:8000/mcp`; HTTP header `Host` задан как
`127.0.0.1:8000` для совместимости с DNS-rebinding protection FastMCP. Backend
по-прежнему слушает только loopback.

Open Interpreter использует `harness = "native"` и
`default_tools_approval_mode = "approve"`. Подтверждены настоящие MCP events:

- `ghidra/list_project_binaries (completed)` — возвращены debug и stripped ELF;
- `ghidra/decompile_function (completed)` — для `main` возвращён C-код с
  `add_numbers(0x14,0x16)` и `printf("Result: %d\\n", ...)`.

Пустой MCP resources list не является отказом: PyGhidra публикует tools.

Для нового файла с Acer сначала выполняются SSH-копирование в
`/home/user/AI-Workbench/incoming`, `ai-ingest-file` и `ai-ghidra-stage` без
исполнения файла. Только полученный Ubuntu path передаётся в
`ghidra/import_binary`; локальный Windows path PyGhidra не видит.
