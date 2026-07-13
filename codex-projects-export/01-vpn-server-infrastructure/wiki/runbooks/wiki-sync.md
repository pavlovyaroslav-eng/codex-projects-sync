# Импорт WIKI

1. Проверить alias `www-vpn-wiki-sync` командой `git ls-remote www-vpn-wiki-sync:/opt/git/vpn-server-wiki.git`.
2. Запустить `scripts/sync-vpn-wiki.ps1`; он использует Windows OpenSSH и `IdentityAgent=none`.
3. Проверить журнал `%LOCALAPPDATA%\CodexProjectSync\vpn-wiki-sync.log`.
4. Убедиться, что изменён только `wiki/upstream`.
5. Проверить Git diff и выполнить обычный commit/push без force, merge или rebase.
