# VPN-доступ и локальные агенты

Состояние на 2026-08-03: изолированный OpenVPN-туннель работает, все три
VPN-службы включены в автозагрузку. Aider, OpenCode, Open Interpreter и
Matrix/Element-бот используют Qwen3 Coder через VPN endpoint `:8080`.

## Работа поверх Hiddify

На Windows проверен каскад из двух туннелей:

```text
ноутбук → Hiddify sing-tun (tun0) → matrix.hometele.com.ru:21200/udp
         → OpenVPN 10.93.0.11 → local-ai 10.93.0.10
```

Маршрут к публичному OpenVPN endpoint фактически проходит через Hiddify, а
`10.93.0.0/24` — через внутренний OpenVPN TAP. SSH и llama.cpp health в такой
схеме проверены. Поэтому при смене города достаточно подключить тот же Hiddify
профиль и иметь доступ в Интернет; `OpenVPNService` автоматически восстановит
внутренний туннель. Профиль содержит `persist-key`, `persist-tun` и
`resolv-retry infinite`.

Проверка каскада и открытие Open WebUI:

```powershell
powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\open-local-ai-via-hiddify.ps1
```

Только проверка, без открытия браузера:

```powershell
powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\open-local-ai-via-hiddify.ps1 `
  -CheckOnly
```

## Схема VPN

| Узел | VPN-адрес | Служба |
|---|---:|---|
| `matrix.hometele.com.ru` | `10.93.0.1` | `openvpn-server@local-ai.service` |
| Ubuntu `local-ai` | `10.93.0.10` | `openvpn-client@hometele-local-ai.service` |
| Windows-ноутбук владельца | `10.93.0.11` | `OpenVPNService` |

Сервер принимает OpenVPN на UDP `21200`, интерфейс — `tun93`, подсеть —
`10.93.0.0/24`. Клиентам не передаются default route и DNS; NAT и публичный
DNAT к ИИ-станции отсутствуют. Обычный интернет-трафик остаётся на прежнем
маршруте каждого устройства.

UFW ИИ-станции разрешает из `10.93.0.0/24` через `tun93` только TCP
`22`, `3000`, `8000`, `8080` и `8188`. SSH остаётся key-only. AI-интерфейсы
не имеют отдельной application-аутентификации, поэтому VPN-профили нужно
считать административными секретами.

## Удалённый доступ

```powershell
ssh -i C:\Users\ACER-X-02\.ssh\id_ed25519_local_ai_admin_v2 `
  -o HostKeyAlias=192.168.1.65 user@10.93.0.10
```

`HostKeyAlias` заставляет SSH сверять VPN-подключение с уже доверенным host key
этой же станции под LAN-адресом.

| Назначение | VPN URL |
|---|---|
| Open WebUI | `http://10.93.0.10:3000` |
| OpenAI-compatible API | `http://10.93.0.10:8080/v1` |
| PyGhidra MCP | `http://10.93.0.10:8000/mcp` в LLM mode |
| Whisper | `http://10.93.0.10:8000` в whisper mode |
| ComfyUI | `http://10.93.0.10:8188` |

Windows-профиль установлен в
`C:\Program Files\OpenVPN\config-auto\owner-laptop.ovpn`; ACL разрешает полный
доступ только `SYSTEM`/Administrators и чтение только службе OpenVPN. Защищённая
резервная копия находится вне репозитория в
`C:\Users\ACER-X-02\.local-ai-vpn`.

## Агенты на Windows

- Aider `0.86.2`: `C:\Users\ACER-X-02\.local\bin\aider.exe`;
- OpenCode `1.18.10`: `E:\EngineeringTools\npm-global\opencode.cmd`;
- Aider config: `C:\Users\ACER-X-02\.aider.conf.yml`;
- OpenCode config: `C:\Users\ACER-X-02\.config\opencode\opencode.json`.

Каталоги обоих исполняемых файлов добавлены в пользовательский `PATH`; команды
`aider` и `opencode` доступны в новых окнах PowerShell.

Оба клиента используют `http://10.93.0.10:8080/v1`, по умолчанию —
`qwen3-coder-30b-a3b-q4km`. Строка API key `local-no-auth` является технической
заглушкой OpenAI-compatible клиента, а не секретом; границей доступа служат
клиентские VPN-сертификаты и UFW.

Open Interpreter использует тот же endpoint из
`C:\Users\ACER-X-02\.openinterpreter\config.toml`, `native` harness и MCP
`ghidra` через `http://10.93.0.10:8000/mcp`. Вызовы Ghidra tools одобряются
автоматически; реальная декомпиляция `main` проверена. На `www` Matrix-бот
`hometele-ai.service` обращается к нему с адреса `10.93.0.1`; в Element запрос
отправляется командой `!ai текст вопроса`, а `!model` возвращает точное имя
активной модели. Доступ бота ограничен значением `ALLOWED_USER`, а старые
сообщения после перезапуска не воспроизводятся.

Open WebUI доступен на `:3000`; через LAN и VPN разрешены только точные origins.
Compatibility endpoint `:8080` также отдаёт встроенную страницу llama.cpp без
прежней gzip-ошибки, но для обычной работы в браузере использовать Open WebUI.

Ghidra и Whisper разделяют VPN-порт `8000`. Переключение выполняется только
штатными командами `sudo ai-mode whisper` и `sudo ai-mode llm`, которые
освобождают порт и восстанавливают нужную службу автоматически.
Полный цикл переключения проверен: Whisper получил `0.0.0.0:8000`, затем LLM
вернул Qwen API, Open WebUI, loopback MCP и VPN MCP socket; итоговый health-check
— `0 error(s)`.

OpenCode настроен на локальный primary-agent: максимум 6 шагов, subagents и
web-инструменты отключены, чтение разрешено, команды и изменения требуют
подтверждения. Это предотвращает бесконечный инструментальный цикл локальной
модели, но сохраняет работу с кодом.

Универсальный запуск с автоматическим выбором модели на ИИ-станции:

```powershell
powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\start-local-ai-agent.ps1 `
  -Agent aider -Profile coder30

powershell -ExecutionPolicy Bypass -File `
  E:\codex-projects-export\codex-projects-export\local-ai-deployment\scripts\start-local-ai-agent.ps1 `
  -Agent opencode -Profile coder30
```

Скрипт проверяет VPN, переключает взаимно исключающий GPU-профиль через SSH,
ждёт `/health` и только затем запускает агент в текущем каталоге.

## Диагностика

```powershell
Get-Service OpenVPNService
Get-NetIPAddress -IPAddress 10.93.0.11
Invoke-RestMethod http://10.93.0.10:8080/health
Get-Content C:\ProgramData\OpenVPN\Log\owner-laptop.log -Tail 50
```

```bash
# Ubuntu local-ai
systemctl status openvpn-client@hometele-local-ai.service
ip -br address show tun93
sudo journalctl -u openvpn-client@hometele-local-ai.service -n 50 --no-pager

# hometele
systemctl status openvpn-server@local-ai.service
ip -br address show tun93
sudo journalctl -u openvpn-server@local-ai.service -n 50 --no-pager
```

## Резервные копии и откат

- hometele: `/var/backups/openvpn-local-ai-20260801T050342Z`;
- local-ai: `/var/lib/local-ai/rollback/openvpn-client-20260801T050451Z`;
- Windows: `C:\ProgramData\LocalAI-Deployment\rollback\windows-openvpn-20260801-083134`;
- серверный rollback: `scripts/rollback-hometele-openvpn-server.sh`.

Для отключения Windows-клиента без удаления пакета администратор останавливает
`OpenVPNService` и удаляет только `owner-laptop.ovpn` из `config-auto`. Для
отзыва доступа дополнительно отозвать CN `owner-laptop` в серверной PKI и
перевыпустить CRL. Не переиспользовать один профиль на нескольких устройствах.
