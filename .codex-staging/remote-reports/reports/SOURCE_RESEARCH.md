# Official source research

Проверено: 2026-08-02. На станции ничего не скачивалось и не устанавливалось.

## Qwen Code

- официальный проект: <https://github.com/QwenLM/qwen-code>;
- актуальный release: `v0.21.3` от 2026-08-01;
- Linux x64 standalone: `qwen-code-linux-x64.tar.gz`, 82,925,537 bytes;
- SHA-256 из официального `SHA256SUMS`:
  `3cf9620770933926f74ba3f6e490cf7f91f2619c68dbb995ec96af20ee365f2a`;
- выбран standalone, поэтому Node.js не является обязательным;
- актуальный `modelProviders` использует auth type `openai`, protocol `openai`,
  model `id`, `baseUrl` и `envKey`;
- безопасный режим: `tools.approvalMode = "default"`, folder trust включён;
- HTTP MCP: `qwen mcp add --scope user --transport http ghidra
  http://127.0.0.1:8000/mcp`.

Документация:

- <https://qwenlm.github.io/qwen-code-docs/en/users/configuration/model-providers/>
- <https://qwenlm.github.io/qwen-code-docs/en/users/configuration/settings/>
- <https://qwenlm.github.io/qwen-code-docs/en/users/configuration/trusted-folders/>
- <https://qwenlm.github.io/qwen-code-docs/en/users/features/mcp/>

## Ghidra

- официальный проект: <https://github.com/NationalSecurityAgency/ghidra>;
- актуальный release asset: `ghidra_12.1.2_PUBLIC_20260605.zip`;
- размер: 572,803,866 bytes;
- SHA-256: `b62e81a0390618466c019c60d8c2f796ced2509c4c1aea4a37644a77272cf99d`;
- официальный release требует JDK 21 64-bit и запрещает использовать GitHub
  source archive вместо release asset;
- текущая станция имеет только Java runtime 21; JDK/`javac` отсутствует.

## PyGhidra MCP

- проект: <https://github.com/clearbluejar/pyghidra-mcp>;
- release/PyPI: `0.2.3`;
- Python: `>=3.10`; станция имеет Python 3.12.3;
- declared dependency: `pyghidra>=2.2.1`; актуальный официальный PyGhidra —
  3.1.0;
- рекомендуемый transport: `streamable-http`;
- default endpoint: `http://127.0.0.1:8000/mcp`.

Совместимость Ghidra 12.1.2 + PyGhidra + pyghidra-mcp должна быть доказана в
отдельном venv smoke-test; версия не считается совместимой только по диапазону
зависимостей.

## llama.cpp

- официальный проект: <https://github.com/ggml-org/llama.cpp>;
- актуальный release: `b10227` от 2026-08-02;
- станция использует `b10210`, commit prefix `0005475`;
- обновление допустимо только side-by-side с прежним symlink и проверяемым
  rollback, поскольку текущая версия уже обслуживает рабочие модели.

## Модель

- поиск в организации Qwen показывает base и FP8 repositories, но не
  официальный GGUF для `Qwen3-Coder-30B-A3B-Instruct`;
- приоритетный fallback: `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`, revision
  `b17cb02dd882d5b6ab62fc777ad2995f19668350`, Apache-2.0;
- текущий проверенный файл получен из `lmstudio-community`, SHA-256 записан в
  `VERSIONS.lock`; автоматически удалять или дублировать его нельзя.

## Дополнительные инструменты анализа

- capa `v9.4.0`, официальный Linux asset, SHA-256
  `07800a1d20a21eb18fc98716e2ae81b668e0c9a04defd588c8aa17ea3d3281e4`:
  <https://github.com/mandiant/capa/releases/tag/v9.4.0>;
- Rizin `v0.9.1`, официальный static x86_64 asset, SHA-256
  `9102249a9f0b6319c5334a2e5cf8d9cc3f2035e1d3def027c41f6a90f647e8cf`:
  <https://github.com/rizinorg/rizin/releases/tag/v0.9.1>;
- JADX `v1.5.6`, SHA-256
  `545ea2be9c242511bc145755cf4bda2485ade42966e096f8b4d3da2a230e8974`:
  <https://github.com/skylot/jadx/releases/tag/v1.5.6>;
- Apktool `v3.0.3`, SHA-256
  `dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423`:
  <https://github.com/iBotPeaches/Apktool/releases/tag/v3.0.3>;
- ghidrecomp `v0.5.9`:
  <https://github.com/clearbluejar/ghidrecomp/releases/tag/v0.5.9>;
- binwalk `v3.1.0`:
  <https://github.com/ReFirmLabs/binwalk/releases/tag/v3.1.0>.

## .NET

- актуальная LTS-линия: .NET 10; Ubuntu 24.04 предоставляет
  `dotnet-sdk-10.0` в собственном feed;
- актуальный ILSpy: `10.1`, требуется .NET 10;
- `ilspycmd` устанавливается как отдельный dotnet tool в выделенный каталог,
  не глобально для root.

Источники:

- <https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu-install>
- <https://github.com/icsharpcode/ILSpy/releases/tag/v10.1>
