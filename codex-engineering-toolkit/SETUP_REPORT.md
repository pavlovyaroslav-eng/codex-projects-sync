# Отчёт об установке Codex Engineering Toolkit

Дата проверки: 14 июля 2026 года
Компьютер: DESKTOP-5J9FAII
Репозиторий: C:\Users\ACER-X-02\Downloads\codex-projects-export
Статус отчёта: обновлён после повторной ручной установки PowerShell 7 и повторного запуска RF-зависимостей

## 1. System audit

- Windows 10 Pro 10.0.19042 x64, часовой пояс Europe/Moscow.
- Архитектура: AMD64.
- Пользователь: DESKTOP-5J9FAII\ACER-X-02.
- Аудит и основная установка выполнялись без административного токена; elevated = false.
- Codex Desktop установлен как OpenAI.Codex 26.707.8479.0.
- Основной Python: 3.12.10.
- Git-репозиторий обнаружен, ветка main, удалённый origin сохранён.
- Переменная CODEX_HOME глобально не задана; фактический пользовательский каталог Codex:
  C:\Users\ACER-X-02\.codex
- Каталог общих данных agents:
  C:\Users\ACER-X-02\.agents
- Доступные менеджеры: winget, npm, pip, pipx и Git.
- Chocolatey и Scoop отсутствуют и специально не устанавливались.
- WSL-команда присутствует в Windows, но современный вывод status этой версии не поддерживается; дистрибутивы не устанавливались и конфигурация WSL не изменялась.
- До установки на C: было около 12,46 ГБ свободно, на E: около 26,07 ГБ.
- После RF-установки и очистки только pip/npm download-cache: C: около 0,25 ГБ свободно из 228,18 ГБ; E: около 24,96 ГБ из 475,92 ГБ. Запас C: критически мал и отмечен как эксплуатационный риск.
- До изменений существовали задача Codex Projects Git Sync и MCP node_repl; оба сохранены.
- Docker, WSL, CUDA, драйверы и прошивки устройств не устанавливались и не изменялись.

### Обнаруженные менеджеры и реальные пути

| Компонент | Состояние | Путь |
|---|---|---|
| winget | доступен | C:\Users\ACER-X-02\AppData\Local\Microsoft\WindowsApps\winget.exe |
| npm | доступен | E:\EngineeringTools\NodeJS\node-v24.18.0-win-x64\npm.ps1 |
| pip | доступен | C:\Users\ACER-X-02\AppData\Local\Programs\Python\Python312\Scripts\pip.exe |
| pipx | доступен | C:\Users\ACER-X-02\AppData\Roaming\Python\Python312\Scripts\pipx.exe |
| Git | доступен | E:\EngineeringTools\Git\cmd\git.exe |
| Chocolatey | отсутствует | не устанавливался |
| Scoop | отсутствует | не устанавливался |

## 2. Backups created

- Создана очищенная от секретов резервная копия конфигурации:
  C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\backups\codex-config-20260714-002231
- В манифесте сохранены SHA256 и перечень 609 файлов, общий объём около 421,19 МБ.
- Исключены auth.json, sessions, attachments, SQLite, журналы, секретные переменные и каталоги credentials.
- Конфигурация config.toml сохранена только в очищенном виде без значений секретных переменных.
- Сценарий резервирования:
  C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Backup-CodexConfiguration.ps1
- Backup-сценарий повторяемый, создаёт отдельный каталог с timestamp и не перезаписывает предыдущую копию.

## 3. Codex status

- Codex CLI 0.144.3 установлен в E:\EngineeringTools\npm-global.
- До работ доступен был Codex Desktop и его внутренний runtime, но отдельная рабочая команда Codex CLI в shell отсутствовала.
- Официальный пакет @openai/codex установлен через npm в пользовательский prefix; системная копия и Desktop-пакет не удалялись.
- Успешно проверены codex --version, codex --help, codex plugin list --json, codex plugin marketplace list --json и codex mcp list.
- Существующий MCP node_repl сохранён, значения окружения при аудите не раскрывались.
- Персональный marketplace и локальный плагин доступны CLI.
- Для подхвата всех Desktop-плагинов после установки был нужен перезапуск; текущая сессия уже видит их skills.

### Marketplace после настройки

| Marketplace | Корень |
|---|---|
| personal | C:\Users\ACER-X-02 |
| openai-bundled | C:\Users\ACER-X-02\.codex\.tmp\bundled-marketplaces\openai-bundled |

CLI подтверждает установленными и enabled: yaroslav-engineering-toolkit, browser, computer-use и visualize. Remote-плагины Desktop проверялись дополнительно по manifest в кэше, поскольку они не публикуются локальным CLI marketplace list.

## 4. Plugins installed

Исходный аудит сохранял уже существующие Browser, Computer Use, Visualize, GitHub, Gmail, OpenAI Templates и пользовательское приложение; ни один из них не удалялся. После настройки добавлены Codex Security, Google Drive и персональный инженерный плагин.

- yaroslav-engineering-toolkit 1.0.0 — установлен и включён из personal marketplace.
- Codex Security 0.1.11 — manifest подтверждён в кэше openai-curated-remote.
- Google Drive 0.1.8 — установлен.
- GitHub 0.1.8 — существующая установка сохранена.
- Browser, Computer Use и Visualize — существующие установки сохранены.
- Canva доступен как коннектор текущей среды.
- Gmail 0.1.5, OpenAI Templates 0.1.0 и ранее установленное приложение app-69c320d803048191bc2682ea9ff3e5fa сохранены без удаления.
- Установленные remote manifests проверены только чтением файлов plugin.json; lifecycle hooks автоматически не запускались.

## 5. Plugins unavailable

- Creative Production — точного официального кандидата в доступном каталоге нет.
- Отдельный официальный Remotion-плагин не найден; вместо него создан воспроизводимый локальный Remotion-проект.
- openEMS не является Codex-плагином, но также недоступен как доверенный пакет; случайная сторонняя сборка не загружалась.

## 6. OAuth actions required

- Google Drive требует пользовательской авторизации при первом обращении.
- GitHub требует авторизации, если существующая сессия истекла или ещё не связана.
- Canva требует пользовательской авторизации при первом обращении.
- Секреты и OAuth-токены в репозиторий не записывались.

## 7. Local engineering plugin

- Исходник: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\plugins\yaroslav-engineering-toolkit
- Marketplace-копия: C:\Users\ACER-X-02\plugins\yaroslav-engineering-toolkit
- Рабочая копия: C:\Users\ACER-X-02\.codex\plugins\yaroslav-engineering-toolkit
- Marketplace: C:\Users\ACER-X-02\.agents\plugins\marketplace.json
- Manifest и все skills прошли официальные валидаторы.
- plugin.json: name yaroslav-engineering-toolkit, version 1.0.0, displayName Yaroslav Engineering Toolkit, developerName Yaroslav Pavlov, category Developer Tools.
- Плагин не содержит MCP-серверов и lifecycle hooks.
- В personal marketplace используется локальный относительный путь ./plugins/yaroslav-engineering-toolkit и политика AVAILABLE / ON_INSTALL.
- Повторная синхронизация выполняется robocopy с проверкой кодов возврата и не создаёт дубликатов marketplace.

## 8. Skills created

- ubuntu-server-ops
- kicad-pcb-engineer
- rf-antenna-lab
- 3d-print-engineer
- embedded-firmware
- media-local-pipeline

Skills содержат безопасные границы: серверные изменения и прошивка устройств выполняются только по прямому запросу после проверки цели; медиа и CAD-процессы сохраняют масштаб, исходники и проверяемые результаты.

Каждый SKILL.md содержит YAML frontmatter, назначение, workflow, проверки, ограничения и формат итогового отчёта. Для каждого skill также создан agents\openai.yaml. Пустых skills нет.

### Реализованные ограничения skills

- ubuntu-server-ops по умолчанию работает read-only, требует backup, diff и rollback; alias www-vpn-wiki-sync описан как строго read-only.
- kicad-pcb-engineer фиксирует требования односторонней платы, максимум двух перемычек, дорожек 0,8 мм, углов 45°, полигонов GND и обязательных ERC/DRC.
- rf-antenna-lab требует расчётов, единиц, параметров материала и не заявляет S11, КСВ или усиление без симуляции/измерения.
- 3d-print-engineer сохраняет масштаб и исходник, проверяет manifold, стенки, нормали, самопересечения и сравнение до/после.
- embedded-firmware разрешает автоматическую компиляцию, но запрещает прошивку, erase, fuse и eFuse без прямого подтверждения.
- media-local-pipeline сохраняет исходники, FPS, разрешение и звук, ограничивает редактируемый объект/интервал и требует проверку кадров.

## 9. Applications installed

- Git 2.55.0.2, GitHub CLI 2.96.0, Node.js LTS 24.18.0, npm 11.16.0.
- Python 3.12.10, pipx 1.15.0, CMake 4.4.0, Ninja 1.13.2.
- jq 1.8.2, ripgrep 15.1.0, 7-Zip 26.02.
- FFmpeg 8.1.1, ImageMagick 7.1.2.27, ExifTool 13.59.
- KiCad 9.0.4, FreeCAD 1.1.1, OpenSCAD 2021.01, Blender 5.1.2, MeshLab 2025.07, PrusaSlicer 2.9.6.
- Arduino CLI 1.5.1, PlatformIO Core 6.1.19, esptool 5.3.1, OpenOCD 0.12.0-7, AVRDUDE 8.2.
- GNU Octave 11.3.0.
- Python RF: numpy 2.5.1, scipy 1.18.0, matplotlib 3.11.0, h5py 3.16.0, scikit-rf 2.0.1.
- Remotion 4.0.489 и зависимости React установлены локально; npm audit сообщает 0 уязвимостей.

### Фактические версии и smoke-test

| Компонент | Версия | Результат |
|---|---:|---|
| Codex CLI | 0.144.3 | passed |
| Git | 2.55.0.2 | passed |
| GitHub CLI | 2.96.0 | passed |
| OpenSSH Client | Windows built-in | passed |
| PowerShell 7 | 7.6.3.0 | failed: AppX license |
| Python | 3.12.10 | passed |
| pipx | 1.15.0 | passed |
| Node.js LTS | 24.18.0 | passed |
| npm | 11.16.0 | passed |
| 7-Zip | 26.02 | passed |
| jq | 1.8.2 | passed |
| ripgrep | 15.1.0 | passed |
| CMake | 4.4.0 | passed |
| Ninja | 1.13.2 | passed |
| FFmpeg | 8.1.1 | passed |
| ImageMagick | 7.1.2.27 | passed |
| ExifTool | 13.59 | passed |
| KiCad CLI | 9.0.4 | passed |
| FreeCADCmd | 1.1.1 | passed |
| OpenSCAD | 2021.01 | passed |
| Blender | 5.1.2 | passed |
| MeshLab | 2025.07 | passed by executable/file check |
| PrusaSlicer | 2.9.6 | passed; version command returns documented non-zero code |
| Arduino CLI | 1.5.1 | passed |
| PlatformIO Core | 6.1.19 | passed |
| esptool | 5.3.1 | passed |
| OpenOCD | 0.12.0-7 | passed |
| AVRDUDE | 8.2 | passed; help command may return non-zero |
| GNU Octave | 11.3.0 | passed |
| Python RF libraries | numpy 2.5.1; scipy 1.18.0; matplotlib 3.11.0; h5py 3.16.0; scikit-rf 2.0.1 | passed import smoke-test |
| openEMS | не установлен | unavailable, безопасно пропущен |
| Remotion project | 4.0.489 | passed |

## 10. Applications updated

- Codex CLI установлен в отдельный пользовательский npm-prefix на диске E.
- Git и основные CLI-инструменты добавлены в разрешённые пользовательские каталоги.
- Плагины marketplace обновлены без массового системного обновления.
- PATH дополнен только пользовательскими каталогами установленных CLI; существующий remote и ветка Git не изменялись.
- CMake, PlatformIO и esptool установлены в изолированном режиме pipx.
- Remotion использует фиксированные версии и package-lock.json; глобальная установка Remotion не выполнялась.

## 11. Applications skipped

- KiCad не обновлялся с 9.x до 10.x из-за запрета автоматического major upgrade.
- openEMS пропущен: доверенного точного WinGet-пакета и одобренного пользователем standalone-дистрибутива нет.
- WSL, Docker, CUDA, драйверы, preview/beta-пакеты и системные компоненты, требующие перезагрузки, пропущены.
- USB-драйверы не устанавливались; микроконтроллеры не подключались и не прошивались.
- Тяжёлые рендеры, симуляции и подключения к Ubuntu-серверам не запускались.

## 12. Failed operations

- PowerShell 7.6.3.0 установлен как MSIX/AppX, но Windows отклоняет запуск: No applicable app licenses found.
- Пользователь выполнил ручную переустановку; winget и Get-AppxPackage показывают пакет 7.6.3.0 со статусом Ok, однако фактический запуск pwsh --version по-прежнему завершается ошибкой лицензии.
- Дополнительно выполнена точечная повторная регистрация AppxManifest.xml. Она завершилась без ошибки, но запуск pwsh не восстановился.
- Рабочий обход: все installer, updater и weekly task совместимы с Windows PowerShell 5.1.
- Для окончательного восстановления PowerShell 7 нужен официальный portable ZIP или MSI-вариант, не зависящий от AppX-лицензии. Он пока не установлен из-за низкого свободного места C: и медленной сети.
- Первая фоновая установка RF-библиотек завершилась ошибкой SHA256: загруженный wheel не совпал с хэшем индекса после нескольких сетевых разрывов.
- Частично загруженный wheel из первой попытки не устанавливался; сразу после ошибки импорты numpy, scipy, matplotlib, h5py и skrf отсутствовали.
- Повторная установка выполнена с --no-cache-dir, timeout 600 и 20 retries. Временный каталог был перенесён на E:\EngineeringTools\temp\python-rf, чтобы не заполнять C: временными wheels.
- Повторная установка завершилась успешно. Отдельный import smoke-test подтвердил numpy 2.5.1, scipy 1.18.0, matplotlib 3.11.0, h5py 3.16.0 и scikit-rf 2.0.1.
- После проверки временный каталог RF, pip download-cache 116,7 МБ и npm download-cache около 362 МБ были удалены; установленные пакеты не затронуты.

## 13. Scheduled task

- Имя: Codex Engineering Toolkit - Weekly Update.
- Расписание: каждое воскресенье в 05:00 по локальному времени; ближайший запуск 19.07.2026 05:00.
- Запуск: Windows PowerShell 5.1, текущий пользователь, RunLevel Limited, Interactive.
- Политика: StartWhenAvailable, IgnoreNew, максимальная длительность 4 часа.
- Системный updater с UAC автоматически не запускается.
- Задача аккуратно обновляется по тому же имени, имеет RunLevel Limited, LogonType Interactive, StartWhenAvailable, MultipleInstances IgnoreNew и ExecutionTimeLimit 4 часа.
- Пароль пользователя в задаче не хранится.
- После восстановления рабочего PowerShell 7 task можно безопасно перевести на pwsh; сейчас оставлен рабочий Windows PowerShell 5.1.

## 14. Verification results

- 30 компонентов прошли smoke-test.
- 1 компонент недоступен безопасно: openEMS.
- 1 реальный сбой: PowerShell 7 AppX license.
- 0 структурных ошибок.
- Валидны packages.json, plugin.json, marketplace.json и шесть skills.
- Remotion version check, Git scope и поиск credential-shaped значений пройдены.
- Машиночитаемый результат: installed-components.json.
- Последний подробный тест: logs\LAST_TEST_REPORT.md.
- Полный тест не выполняет рендер, RF-симуляцию, прошивку или серверное подключение.
- Проверка охватывает executable paths, JSON, plugin manifest, YAML frontmatter, personal marketplace, scheduled task, Remotion versions, Git scope и credential-shaped значения.
- Скрипты Install-EngineeringToolkit.ps1, Update-UserComponents.ps1, Update-SystemComponents.ps1, Test-EngineeringToolkit.ps1 и Backup-CodexConfiguration.ps1 прошли синтаксический разбор PowerShell.

### Соответствие автоматическому обновлению

- Update-UserComponents.ps1: mutex от параллельного запуска, backup Codex, npm-обновление Codex, marketplace upgrade, pipx upgrade разрешённых пакетов, robocopy-синхронизация плагина, npm ci по lock-файлу и итоговый тест.
- Update-SystemComponents.ps1: требует elevation, выбирает только winget ID из packages.json, проверяет major version, не использует upgrade --all, продолжает после необязательных ошибок и запускает тест.
- Run-SystemUpdateAsAdmin.cmd запускает только системный updater через UAC.
- Обёртки и PowerShell-файлы сохранены в UTF-8 и корректно заключают пути с пробелами.

## 15. Security notes

- Скрипты не используют winget upgrade --all.
- Системный updater разрешает только точные ID из config\packages.json и пропускает major upgrade без ручного решения.
- Пользовательский updater обращается к реестрам обновлений, но не подключается к управляемым Ubuntu-серверам и не прошивает устройства.
- Логи, backups, node_modules, временные файлы и секреты исключены из Git.
- Существующие пользовательские изменения вне toolkit не изменялись.
- Windows Defender, UAC, sandbox и системная Execution Policy не отключались.
- Не выполнялись автоматические major upgrades и не устанавливались preview/beta-версии.
- Секрет-скан исходников toolkit прошёл; auth.json, OAuth-токены, SSH private keys и значения MCP env не вошли в Git.
- Резервные копии, logs, node_modules, out, temp, credentials и secret-файлы исключены через .gitignore.
- Системный диск C: имеет критически малый запас; до освобождения места не рекомендуется запускать дополнительные тяжёлые установки.

## 16. Rollback instructions

1. Отключить или удалить задачу Codex Engineering Toolkit - Weekly Update.
2. Удалить локальную запись плагина командой codex plugin remove yaroslav-engineering-toolkit@personal, если она больше не нужна.
3. Восстановить нужные несекретные файлы из каталога backups\codex-config-20260714-002231 по backup-manifest.json.
4. Удалить пользовательские копии C:\Users\ACER-X-02\plugins\yaroslav-engineering-toolkit и C:\Users\ACER-X-02\.codex\plugins\yaroslav-engineering-toolkit только после проверки абсолютных путей.
5. Системные приложения удалять по одному по точному package ID; массовое удаление не предусмотрено.
6. Для отмены только RF-повтора завершить проверенный python-процесс pip и удалить E:\EngineeringTools\temp\python-rf; установленные ранее рабочие Python-пакеты это не затрагивает.
7. Git rollback выполнять обычным revert коммитов c705504 и 47fa6da; reset --hard для этого не требуется.

## 17. Exact paths

- Toolkit: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit
- Report: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\SETUP_REPORT.md
- Package registry: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\config\packages.json
- Plugin registry: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\config\plugin-candidates.json
- Verification: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\installed-components.json
- User updater: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Update-UserComponents.ps1
- System updater: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Update-SystemComponents.ps1
- Remotion project: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\tools\media-remotion
- RF stdout log: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\logs\python-rf-install.stdout.log
- RF stderr log: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\logs\python-rf-install.stderr.log
- README: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\README.md
- AGENTS: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\AGENTS.md
- Update policy: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\UPDATE_POLICY.md
- Installer: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Install-EngineeringToolkit.ps1
- Backup script: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Backup-CodexConfiguration.ps1
- Test script: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Test-EngineeringToolkit.ps1
- User update wrapper: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Run-Toolkit-Update.cmd
- System update wrapper: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\scripts\Run-SystemUpdateAsAdmin.cmd
- Local plugin source: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\plugins\yaroslav-engineering-toolkit
- Personal marketplace: C:\Users\ACER-X-02\.agents\plugins\marketplace.json
- Sanitized backup manifest: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\backups\codex-config-20260714-002231\backup-manifest.json
- RF retry stdout: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\logs\python-rf-retry.stdout.log
- RF retry stderr: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\logs\python-rf-retry.stderr.log
- RF temporary directory: E:\EngineeringTools\temp\python-rf — удалён после успешной установки

### Полный перечень исходных файлов toolkit

Все следующие относительные пути разрешаются от:
C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit

- .gitignore
- README.md
- AGENTS.md
- SETUP_REPORT.md
- UPDATE_POLICY.md
- installed-components.json
- config\packages.json
- config\plugin-candidates.json
- plugins\yaroslav-engineering-toolkit\.codex-plugin\plugin.json
- plugins\yaroslav-engineering-toolkit\skills\ubuntu-server-ops\SKILL.md
- plugins\yaroslav-engineering-toolkit\skills\ubuntu-server-ops\agents\openai.yaml
- plugins\yaroslav-engineering-toolkit\skills\kicad-pcb-engineer\SKILL.md
- plugins\yaroslav-engineering-toolkit\skills\kicad-pcb-engineer\agents\openai.yaml
- plugins\yaroslav-engineering-toolkit\skills\rf-antenna-lab\SKILL.md
- plugins\yaroslav-engineering-toolkit\skills\rf-antenna-lab\agents\openai.yaml
- plugins\yaroslav-engineering-toolkit\skills\3d-print-engineer\SKILL.md
- plugins\yaroslav-engineering-toolkit\skills\3d-print-engineer\agents\openai.yaml
- plugins\yaroslav-engineering-toolkit\skills\embedded-firmware\SKILL.md
- plugins\yaroslav-engineering-toolkit\skills\embedded-firmware\agents\openai.yaml
- plugins\yaroslav-engineering-toolkit\skills\media-local-pipeline\SKILL.md
- plugins\yaroslav-engineering-toolkit\skills\media-local-pipeline\agents\openai.yaml
- scripts\Install-EngineeringToolkit.ps1
- scripts\Update-UserComponents.ps1
- scripts\Update-SystemComponents.ps1
- scripts\Test-EngineeringToolkit.ps1
- scripts\Backup-CodexConfiguration.ps1
- scripts\Run-Toolkit-Update.cmd
- scripts\Run-SystemUpdateAsAdmin.cmd
- tools\media-remotion\package.json
- tools\media-remotion\package-lock.json
- tools\media-remotion\src\index.jsx
- tools\media-remotion\src\Root.jsx
- tools\media-remotion\src\EngineeringIntro.jsx

### Диагностические файлы, исключённые из Git

- logs\LAST_TEST_REPORT.md
- logs\codex-plugins-after.json
- logs\codex-marketplaces-after.json
- logs\codex-mcp-after.txt
- logs\python-rf-install.stdout.log
- logs\python-rf-install.stderr.log
- logs\python-rf-retry.stdout.log
- logs\python-rf-retry.stderr.log
- backups\codex-config-20260714-002231\backup-manifest.json

### Git history

- 47fa6da — существующий безопасный sync-workflow зафиксировал исходники локального плагина и backup-сценарий во время работы.
- c705504 — feat(codex): add engineering toolkit and safe updater.
- Remote, имя ветки main и конфигурация Git не изменялись.
- Push вручную в рамках установки не выполнялся.
