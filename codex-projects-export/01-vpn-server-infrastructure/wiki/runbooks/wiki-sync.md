# Импорт WIKI

1. Вручную загрузить существующий серверный ключ в Pageant.
2. Запустить `scripts/sync-vpn-wiki.ps1`.
3. Проверить журнал `%LOCALAPPDATA%\CodexProjectSync\vpn-wiki-sync.log`.
4. Убедиться, что изменён только `wiki/upstream`.
5. Проверить Git diff и выполнить обычный commit/push без force, merge или rebase.
