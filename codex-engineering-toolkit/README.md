# Codex Engineering Toolkit

Локальное инженерное окружение Yaroslav Pavlov для Codex на Windows. Toolkit хранит исходники персонального плагина, воспроизводимые сценарии обновления, реестр разрешённых пакетов и результаты проверок.

## Основные пути

- Исходники toolkit: C:\Users\ACER-X-02\Downloads\codex-projects-export\codex-engineering-toolkit
- Исходник персонального marketplace: C:\Users\ACER-X-02\plugins\yaroslav-engineering-toolkit
- Рабочая копия плагина: C:\Users\ACER-X-02\.codex\plugins\yaroslav-engineering-toolkit
- Marketplace: C:\Users\ACER-X-02\.agents\plugins\marketplace.json
- Логи: .\logs
- Резервные копии: .\backups

## Команды

Запустить пользовательское обновление:

    .\scripts\Run-Toolkit-Update.cmd

Проверить окружение:

    powershell.exe -NoProfile -File .\scripts\Test-EngineeringToolkit.ps1

Запустить системное обновление с UAC вручную:

    .\scripts\Run-SystemUpdateAsAdmin.cmd

Запустить проверку Remotion без рендера:

    cd .\tools\media-remotion
    npm run check

## Безопасность

- Пользовательский updater обращается только к реестрам обновлений; к управляемым Ubuntu-серверам не подключается и устройства не прошивает.
- Системный updater использует только точные ID из config\packages.json.
- winget upgrade --all запрещён.
- Логи, резервные копии, node_modules, временные файлы и секреты исключены из Git.
- Авторизация OAuth выполняется только пользователем.

Полные результаты установки находятся в SETUP_REPORT.md.
