# Отчёт об установке Codex Engineering Toolkit

Дата проверки: 14 июля 2026 года
Компьютер: DESKTOP-5J9FAII
Репозиторий: C:\Users\ACER-X-02\Downloads\codex-projects-export

## 1. System audit

- Windows 10 Pro 10.0.19042 x64, часовой пояс Europe/Moscow.
- Codex Desktop установлен как OpenAI.Codex 26.707.8479.0.
- Основной Python: 3.12.10.
- Git-репозиторий обнаружен, ветка main, удалённый origin сохранён.
- Docker, WSL, CUDA, драйверы и прошивки устройств не устанавливались и не изменялись.

## 2. Backups created

- Создана очищенная от секретов резервная копия конфигурации:
  C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit\backups\codex-config-20260714-002231
- В манифесте сохранены SHA256 и перечень 609 файлов, общий объём около 421,19 МБ.
- Исключены auth.json, sessions, attachments, SQLite, журналы, секретные переменные и каталоги credentials.

## 3. Codex status

- Codex CLI 0.144.3 установлен в E:\EngineeringTools\npm-global.
- Существующий MCP node_repl сохранён, значения окружения при аудите не раскрывались.
- Персональный marketplace и локальный плагин доступны CLI.
- Для подхвата всех Desktop-плагинов после установки был нужен перезапуск; текущая сессия уже видит их skills.

## 4. Plugins installed

- yaroslav-engineering-toolkit 1.0.0 — установлен и включён из personal marketplace.
- Codex Security 0.1.11 — manifest подтверждён в кэше openai-curated-remote.
- Google Drive 0.1.8 — установлен.
- GitHub 0.1.8 — существующая установка сохранена.
- Browser, Computer Use и Visualize — существующие установки сохранены.
- Canva доступен как коннектор текущей среды.

## 5. Plugins unavailable

- Creative Production — точного официального кандидата в доступном каталоге нет.
- Отдельный официальный Remotion-плагин не найден; вместо него создан воспроизводимый локальный Remotion-проект.

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

## 8. Skills created

- ubuntu-server-ops
- kicad-pcb-engineer
- rf-antenna-lab
- 3d-print-engineer
- embedded-firmware
- media-local-pipeline

Skills содержат безопасные границы: серверные изменения и прошивка устройств выполняются только по прямому запросу после проверки цели; медиа и CAD-процессы сохраняют масштаб, исходники и проверяемые результаты.

## 9. Applications installed

- Git 2.55.0.2, GitHub CLI 2.96.0, Node.js LTS 24.18.0, npm 11.16.0.
- Python 3.12.10, pipx 1.15.0, CMake 4.4.0, Ninja 1.13.2.
- jq 1.8.2, ripgrep 15.1.0, 7-Zip 26.02.
- FFmpeg 8.1.1, ImageMagick 7.1.2.27, ExifTool 13.59.
- KiCad 9.0.4, FreeCAD 1.1.1, OpenSCAD 2021.01, Blender 5.1.2, MeshLab 2025.07, PrusaSlicer 2.9.6.
- Arduino CLI 1.5.1, PlatformIO Core 6.1.19, esptool 5.3.1, OpenOCD 0.12.0-7, AVRDUDE 8.2.
- GNU Octave 11.3.0.
- Remotion 4.0.489 и зависимости React установлены локально; npm audit сообщает 0 уязвимостей.

## 10. Applications updated

- Codex CLI установлен в отдельный пользовательский npm-prefix на диске E.
- Git и основные CLI-инструменты добавлены в разрешённые пользовательские каталоги.
- Плагины marketplace обновлены без массового системного обновления.

## 11. Applications skipped

- KiCad не обновлялся с 9.x до 10.x из-за запрета автоматического major upgrade.
- openEMS пропущен: доверенного точного WinGet-пакета и одобренного пользователем standalone-дистрибутива нет.
- WSL, Docker, CUDA, драйверы, preview/beta-пакеты и системные компоненты, требующие перезагрузки, пропущены.

## 12. Failed operations

- PowerShell 7.6.3.0 установлен как MSIX/AppX, но Windows отклоняет запуск: No applicable app licenses found.
- Рабочий обход: все installer, updater и weekly task совместимы с Windows PowerShell 5.1.
- Для восстановления PowerShell 7 следует удалить повреждённый MSIX и повторно установить официальный пакет Microsoft.PowerShell либо официальный portable ZIP. Эта операция оставлена ручной, так как может потребовать UAC и длительной загрузки.
- RF-библиотеки Python устанавливаются в фоне после сетевого read-timeout; процесс пишет отдельные stdout/stderr журналы и не блокирует toolkit.

## 13. Scheduled task

- Имя: Codex Engineering Toolkit - Weekly Update.
- Расписание: каждое воскресенье в 05:00 по локальному времени; ближайший запуск 19.07.2026 05:00.
- Запуск: Windows PowerShell 5.1, текущий пользователь, RunLevel Limited, Interactive.
- Политика: StartWhenAvailable, IgnoreNew, максимальная длительность 4 часа.
- Системный updater с UAC автоматически не запускается.

## 14. Verification results

- 29 компонентов прошли smoke-test.
- 1 компонент недоступен безопасно: openEMS.
- 1 реальный сбой: PowerShell 7 AppX license.
- 0 структурных ошибок.
- Валидны packages.json, plugin.json, marketplace.json и шесть skills.
- Remotion version check, Git scope и поиск credential-shaped значений пройдены.
- Машиночитаемый результат: installed-components.json.
- Последний подробный тест: logs\LAST_TEST_REPORT.md.

## 15. Security notes

- Скрипты не используют winget upgrade --all.
- Системный updater разрешает только точные ID из config\packages.json и пропускает major upgrade без ручного решения.
- Пользовательский updater обращается к реестрам обновлений, но не подключается к управляемым Ubuntu-серверам и не прошивает устройства.
- Логи, backups, node_modules, временные файлы и секреты исключены из Git.
- Существующие пользовательские изменения вне toolkit не изменялись.

## 16. Rollback instructions

1. Отключить или удалить задачу Codex Engineering Toolkit - Weekly Update.
2. Удалить локальную запись плагина командой codex plugin remove yaroslav-engineering-toolkit@personal, если она больше не нужна.
3. Восстановить нужные несекретные файлы из каталога backups\codex-config-20260714-002231 по backup-manifest.json.
4. Удалить пользовательские копии C:\Users\ACER-X-02\plugins\yaroslav-engineering-toolkit и C:\Users\ACER-X-02\.codex\plugins\yaroslav-engineering-toolkit только после проверки абсолютных путей.
5. Системные приложения удалять по одному по точному package ID; массовое удаление не предусмотрено.

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
