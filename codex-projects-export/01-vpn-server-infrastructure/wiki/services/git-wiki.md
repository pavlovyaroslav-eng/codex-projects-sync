# Центральный Git-WIKI

Центральный bare-репозиторий расположен на `www`: `/opt/git/vpn-server-wiki.git`. Рабочие копии серверов находятся в `/opt/vpn-server-wiki`. Ветки: `www`, `hometele`, `azazello`.

Импорт в Codex односторонний. Скрипт `scripts/sync-vpn-wiki.ps1` экспортирует ветки через временный каталог, проверяет секреты и обновляет только `wiki/upstream`.
