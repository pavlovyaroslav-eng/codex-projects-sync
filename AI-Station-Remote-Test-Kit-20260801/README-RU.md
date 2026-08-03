# Проверка удалённой ИИ-станции HomeTele

Комплект предназначен для тестировщика на Windows 10/11. Он проверяет доступ к
Qwen3-14B через выданный администратором VLESS/VPN и при необходимости запускает
Open Interpreter с удалённой моделью.

## Что не входит в архив

Архив **не содержит VLESS URL, UUID, паролей или приватных ключей**. Получите
индивидуальную VLESS-ссылку у администратора по отдельному защищённому каналу.

## Быстрый порядок проверки

1. Полностью распакуйте ZIP в обычную папку, например на Рабочий стол.
2. Запустите `00-VERIFY-FILES.cmd`; ожидаемый результат — `PASS`.
3. Импортируйте выданную VLESS-ссылку в VPN-клиент.
4. Включите TUN/VPN mode. Адрес `10.93.0.10/32` должен идти через `proxy`, а не
   через `Bypass LAN/private networks`.
5. Дважды щёлкните `01-TEST-AI-STATION.cmd`.
6. Ожидаемый результат: все строки заканчиваются `[OK]`, итог — `PASS`.
7. Откройте `http://10.93.0.10:8080/` в браузере и отправьте короткий вопрос.
8. Для Open Interpreter сначала запустите `02-INSTALL-OPEN-INTERPRETER.cmd`,
   затем `03-RUN-OPEN-INTERPRETER.cmd`.

## Что проверяет первый тест

- TCP-соединение с `10.93.0.10:8080`;
- `GET /health`;
- список моделей `GET /v1/models`;
- загрузку web-интерфейса с gzip;
- реальный `POST /v1/chat/completions`;
- наличие непустого ответа и корректной UTF-8 кириллицы.

Отчёт сохраняется в `reports` и не содержит VLESS UUID или содержимое ответа
модели. Отправьте администратору полученный `.txt` и, если нужно, скриншот.

## Open Interpreter

Установщик создаёт изолированное окружение `.open-interpreter-venv` внутри этой
папки и устанавливает зафиксированную версию из `requirements.txt`. Требуется
Python 3.10 или 3.11 и доступ к PyPI во время установки.

Модель выполняется на HomeTele AI, но Python, PowerShell и другие команды Open
Interpreter запускаются **на компьютере тестировщика**. Подтверждайте только те
команды, смысл которых понятен. В комплекте не используется `-y` и не включён
автоматический запуск команд.

Параметры запуска:

```text
API base: http://10.93.0.10:8080/v1
Model: openai/qwen3-14b-q4km
Context: 8192
Max output tokens: 2048
Function calling: disabled; используются подтверждаемые code blocks
```

Для выхода из Open Interpreter нажмите `Ctrl+C`.

## Если тест не проходит

- `TCP` или `/health`: убедитесь, что VLESS подключён и TUN mode включён.
- Частный адрес обходит VPN: отключите `Bypass LAN/private networks` либо
  добавьте правило `10.93.0.10/32 -> proxy`.
- `/v1/models` работает, а Open Interpreter нет: пришлите отчёт и полный текст
  ошибки без VLESS-ссылки.
- Установщик не видит Python: установите 64-bit Python 3.11 с python.org и
  повторите запуск.
- Не запускайте файлы прямо из окна ZIP — сначала распакуйте архив.

## Контроль целостности

Файл `SHA256SUMS.txt` содержит SHA-256 всех файлов комплекта. Проверка в
PowerShell:

```powershell
Get-FileHash .\scripts\Test-AIStation.ps1 -Algorithm SHA256
```

Сравните результат со строкой для этого файла в `SHA256SUMS.txt`.

## Официальные источники

- https://docs.openinterpreter.com/getting-started/setup
- https://docs.openinterpreter.com/guides/running-locally
- https://github.com/OpenInterpreter/open-interpreter
