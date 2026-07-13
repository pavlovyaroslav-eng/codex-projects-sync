# Безопасность

Экспорт очищен от известных секретов. Перед публикацией или отправкой третьим лицам дополнительно проверьте:

- `.env`, `.ini`, `.json`, `.yaml`, `.conf` и резервные копии конфигураций;
- SSH/WireGuard/OpenVPN ключи;
- Matrix access tokens, room invites и bot tokens;
- почтовые пароли и relay credentials;
- сертификаты с приватными ключами;
- архивы, дампы и диагностические логи с персональными данными.

Рекомендуемый поиск перед коммитом:

```bash
grep -RniE 'password|passwd|token|secret|private.key|BEGIN.*PRIVATE|api[_-]?key' .
```
