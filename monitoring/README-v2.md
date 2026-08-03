# VPN Infrastructure Monitoring System v2.0

## 🚀 Современная система мониторинга с веб-интерфейсом

Полнофункциональная система мониторинга VPN-инфраструктуры с real-time обновлениями, WebSocket-подключением и управлением через веб-интерфейс.

### 🎯 Основные возможности

✅ **Real-time мониторинг** - WebSocket для мгновенного обновления данных
✅ **Красивый веб-интерфейс** - Современный дизайн с темной темой
✅ **Автоматические обновления** - Настраиваемый интервал обновления
✅ **Управление серверами** - Выполнение команд через веб-интерфейс
✅ **Логи активности** - Отслеживание всех действий
✅ **Поддержка Pageant** - Работа с SSH через Pageant
✅ **VPN управление** - Добавление/удаление пользователей через интерфейс

---

## 📋 Структура проекта

```
monitoring/
├── server.js              # Node.js backend с WebSocket
├── package.json           # Зависимости Node.js
├── .env.example          # Пример конфигурации
├── server-health-check.sh # Bash-скрипт для серверов
├── public/
│   ├── index.html        # HTML веб-интерфейса
│   ├── styles.css        # CSS стили
│   └── app.js            # JavaScript клиент
└── README-v2.md          # Эта документация
```

---

## 🔧 Установка и настройка

### 1. Установите Node.js

Скачайте и установите Node.js 18+ с [nodejs.org](https://nodejs.org/)

Проверьте установку:
```bash
node --version
npm --version
```

### 2. Установите зависимости

```bash
cd C:\Users\ACER-X-02\Downloads\codex-projects-export\monitoring
npm install
```

### 3. Настройте SSH-доступ

#### Вариант A: Использование Pageant (рекомендуется)

1. **Запустите Pageant** (обычно в трее Windows)
2. **Добавьте ваш SSH-ключ** в Pageant:
   - Правый клик на иконке Pageant → Add Key
   - Выберите ваш приватный ключ (`.ppk` для PuTTY или `.pem`)
   - Введите passphrase если требуется

3. **Проверьте что ключ загружен**:
   - Правый клик на Pageant → View Keys
   - Должен быть виден ваш ключ

4. **Тестовое подключение**:
```bash
ssh -p 52000 suazzzi@azazello.raxla.org
ssh -p 52000 suazzzi@hometele.com.ru
ssh -p 52000 suazzzi@www.hometele.com.ru
```

#### Вариант B: Использование SSH-ключа напрямую

1. Скопируйте `.env.example` в `.env`:
```bash
cp .env.example .env
```

2. Укажите путь к вашему SSH-ключу в `.env`:
```
SSH_USER=suazzzi
SSH_PORT=52000
SSH_KEY_PATH=C:/Users/ACER-X-02/.ssh/id_rsa
PORT=3000
```

### 4. Проверьте подключение к серверам

```bash
# Тест подключения к azazello
ssh -p 52000 suazzzi@azazello.raxla.org "echo 'OK'"

# Тест подключения к hometele
ssh -p 52000 suazzzi@hometele.com.ru "echo 'OK'"

# Тест подключения к www
ssh -p 52000 suazzzi@www.hometele.com.ru "echo 'OK'"
```

Если видите "OK" для всех серверов - SSH настроен правильно!

---

## 🎮 Запуск системы

### Режим 1: Разработка (с автоперезапуском)

```bash
npm run dev
```

### Режим 2: Продакшн

```bash
npm start
```

После запуска откройте браузер:
```
http://localhost:3000
```

Вы увидите:
```
╔════════════════════════════════════════════════════════════════╗
║   VPN Infrastructure Monitor - Server Running                  ║
╚════════════════════════════════════════════════════════════════╝

🌐 Web Interface: http://localhost:3000
🔌 WebSocket: ws://localhost:3000
📊 Monitoring 3 servers
🔑 SSH Port: 52000
👤 SSH User: suazzzi

⏳ Waiting for connections...
```

---

## 💻 Использование веб-интерфейса

### 1. Главный экран

После открытия `http://localhost:3000` вы увидите:

- **Header** с кнопками управления:
  - 🔄 Refresh All - Обновить данные всех серверов
  - ⏱️ Auto: OFF/ON - Автоматическое обновление каждые 60 сек
  - 🟢 Connected - Статус WebSocket подключения

- **Карточки серверов**:
  - **azazello** - Чешский выходной шлюз
  - **hometele** - Российская входная точка
  - **www** - Сервисный узел (Matrix, Git-WIKI)

- **Лог активности** внизу страницы

### 2. Мониторинг сервера

Каждая карточка сервера показывает:

**Системные ресурсы:**
- Uptime - Время работы с последней перезагрузки
- CPU Usage - Загрузка процессора с прогресс-баром
- Memory - Использование RAM с прогресс-баром
- Disk - Использование диска с прогресс-баром
- Load Average - Средняя нагрузка

**Сервисы:**
- Зеленый бейдж = сервис активен (active)
- Красный бейдж = сервис неактивен (inactive/failed)

**Цветовая индикация прогресс-баров:**
- 🟢 Зеленый: < 70% (нормально)
- 🟠 Оранжевый: 70-85% (предупреждение)
- 🔴 Красный: > 85% (критично)

### 3. Управление сервером

Каждая карточка имеет кнопки:

**🔄 Refresh** - Обновить данные конкретного сервера

**⚙️ Commands** - Открывает модальное окно с командами:

#### Доступные команды:

1. **Service Status** - Проверить статус сервиса
   - Введите имя сервиса: `xray`, `nginx`, `matrix-synapse`, etc.
   - Показывает полный вывод `systemctl status`

2. **Restart Service** - Перезапустить сервис
   - ⚠️ Используйте осторожно!
   - Требует sudo прав

3. **Fail2Ban Status** - Статус Fail2Ban
   - Показывает активные jails и заблокированные IP

4. **Check Ports** - Проверка открытых портов
   - Список всех слушающих портов (`ss -lntup`)

5. **VPN Users List** - Список VPN-пользователей (только hometele)
   - Показывает всех пользователей Xray Reality

6. **Add VPN User** - Добавить VPN-пользователя (только hometele)
   - Введите username (2-32 символа, латиница/цифры)
   - Автоматически генерирует UUID и добавляет в Xray
   - Возвращает конфиг для подключения

7. **Delete VPN User** - Удалить VPN-пользователя (только hometele)
   - Введите username существующего пользователя
   - Удаляет из конфигурации Xray

### 4. Автоматическое обновление

Нажмите **⏱️ Auto: OFF** чтобы включить автообновление:
- Статус изменится на **⏱️ Auto: ON**
- Каждые 60 секунд автоматически обновляются данные всех серверов
- Обновления приходят через WebSocket без перезагрузки страницы

### 5. Лог активности

Внизу страницы отображается лог всех действий:
- 🔵 **INFO** - Информационные сообщения
- 🟢 **SUCCESS** - Успешные операции
- 🟠 **WARNING** - Предупреждения
- 🔴 **ERROR** - Ошибки

Кнопка **Clear** очищает лог.

---

## 🔒 Безопасность

### Read-Only режим по умолчанию

Большинство команд выполняются в **read-only** режиме:
- Мониторинг НЕ изменяет конфигурацию
- НЕ перезапускает сервисы автоматически
- НЕ трогает критический порт TCP 443

### Опасные операции требуют подтверждения

- Перезапуск сервисов
- Добавление/удаление VPN-пользователей
- Изменение конфигурации

### SSH-ключи

- Приватные ключи хранятся локально или в Pageant
- Соединение через защищенный SSH порт 52000
- Использование forced command для ограничения доступа

---

## 📊 Архитектура системы

```
┌─────────────┐         WebSocket         ┌──────────────┐
│   Browser   │ <─────────────────────────> │   Node.js    │
│             │                             │   Server     │
│  React UI   │         HTTP REST           │              │
│             │ <─────────────────────────> │  server.js   │
└─────────────┘                             └──────┬───────┘
                                                   │ SSH (port 52000)
                                                   │ via Pageant
                                    ┌──────────────┼──────────────┐
                                    │              │              │
                                    ▼              ▼              ▼
                            ┌───────────┐  ┌───────────┐  ┌───────────┐
                            │ azazello  │  │ hometele  │  │    www    │
                            │           │  │           │  │           │
                            │ health-   │  │ health-   │  │ health-   │
                            │ check.sh  │  │ check.sh  │  │ check.sh  │
                            └───────────┘  └───────────┘  └───────────┘
```

### Поток данных:

1. **Браузер** подключается к Node.js серверу через WebSocket
2. **Node.js** подключается к серверам через SSH (порт 52000)
3. **Bash-скрипт** собирает метрики на сервере
4. **JSON-ответ** отправляется обратно через WebSocket
5. **Браузер** обновляет интерфейс в real-time

---

## 🐛 Troubleshooting

### Проблема: "WebSocket disconnected"

**Причина:** Node.js сервер не запущен

**Решение:**
```bash
cd C:\Users\ACER-X-02\Downloads\codex-projects-export\monitoring
npm start
```

---

### Проблема: "SSH connection failed"

**Причина:** Pageant не запущен или ключ не загружен

**Решение:**
1. Запустите Pageant
2. Добавьте SSH-ключ: Pageant → Add Key
3. Проверьте: Pageant → View Keys
4. Тестовое подключение:
```bash
ssh -p 52000 suazzzi@azazello.raxla.org
```

---

### Проблема: "Health check script not found"

**Причина:** Скрипт не развернут на сервере

**Решение:** Система автоматически развернет скрипт при первом подключении. Если ошибка повторяется:

```bash
# Вручную скопируйте скрипт на сервер
scp -P 52000 server-health-check.sh suazzzi@azazello.raxla.org:/tmp/
ssh -p 52000 suazzzi@azazello.raxla.org "chmod +x /tmp/server-health-check.sh"
```

---

### Проблема: "Cannot execute command on server"

**Причина:** Недостаточно прав или команда недоступна

**Решение:** Проверьте права пользователя:
```bash
ssh -p 52000 suazzzi@hometele.com.ru "sudo -l"
```

Для VPN-команд на hometele проверьте:
```bash
ssh -p 52000 suazzzi@hometele.com.ru "/usr/local/sbin/hometele-vpn-user list"
```

---

### Проблема: Порт 3000 уже занят

**Причина:** Другое приложение использует порт 3000

**Решение:** Измените порт в `.env`:
```
PORT=8080
```

Затем откройте `http://localhost:8080`

---

## 🚀 Продвинутое использование

### Запуск как Windows Service

Используйте [node-windows](https://github.com/coreybutler/node-windows):

```bash
npm install -g node-windows
npm link node-windows
```

Создайте `install-service.js`:
```javascript
const Service = require('node-windows').Service;

const svc = new Service({
  name: 'VPN Infrastructure Monitor',
  description: 'Real-time VPN infrastructure monitoring',
  script: 'C:\\Users\\ACER-X-02\\Downloads\\codex-projects-export\\monitoring\\server.js'
});

svc.on('install', () => {
  svc.start();
});

svc.install();
```

Запустите:
```bash
node install-service.js
```

### Интеграция с Telegram

Добавьте в `server.js` после строки `const SSH_CONFIG = {...}`:

```javascript
const TELEGRAM_BOT_TOKEN = 'YOUR_BOT_TOKEN';
const TELEGRAM_CHAT_ID = 'YOUR_CHAT_ID';

async function sendTelegramAlert(message) {
    const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            chat_id: TELEGRAM_CHAT_ID,
            text: message,
            parse_mode: 'Markdown'
        })
    });
}

// Использование:
if (healthData.services.failed_count > 0) {
    sendTelegramAlert(`⚠️ *${server.name}*: ${healthData.services.failed_count} failed services!`);
}
```

### Запуск на внешнем IP

Для доступа из локальной сети:

1. Измените в `server.js`:
```javascript
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
});
```

2. Откройте порт в Windows Firewall:
```powershell
New-NetFirewallRule -DisplayName "VPN Monitor" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

3. Доступ с других устройств:
```
http://<ваш-IP>:3000
```

---

## 📈 Мониторинг метрик

### Критические пороги

Система использует следующие пороги:

| Метрика | OK | Предупреждение | Критично |
|---------|-----|----------------|----------|
| CPU     | < 70% | 70-85% | > 85% |
| Memory  | < 70% | 70-85% | > 85% |
| Disk    | < 70% | 70-85% | > 85% |
| Failed Services | 0 | 1-2 | > 2 |

### Специфичные проверки серверов

**azazello:**
- Xray/3x-ui (TCP 443) - критический
- MTProto (TCP 9443)
- Docker containers
- WireGuard wg-home

**hometele:**
- Xray Reality (TCP 443) - критический
- Postfix (TCP 25)
- OpenVPN tunnels (tun79, tun88-92)
- WireGuard wg-home

**www:**
- Matrix Synapse (TCP 8008)
- Nginx (TCP 80, 443)
- Coturn (TCP/UDP 5349)
- Command Agent
- Synapse Admin (Docker)

---

## 🔗 Связанные документы

- [server-health-check.sh](./server-health-check.sh) - Bash-скрипт мониторинга
- [server.js](./server.js) - Node.js backend
- [Git Infrastructure Docs](../codex-projects-export/01-vpn-server-infrastructure/)
- [Health Check Runbook](../codex-projects-export/01-vpn-server-infrastructure/wiki/runbooks/health-check.md)

---

## 📝 Changelog

### v2.0.0 (2026-07-21)
- ✅ Real-time WebSocket мониторинг
- ✅ Современный веб-интерфейс
- ✅ Поддержка SSH порта 52000
- ✅ Интеграция с Pageant
- ✅ Управление VPN-пользователями
- ✅ Автоматическое обновление данных
- ✅ Лог активности
- ✅ REST API endpoints

### v1.0.0 (предыдущая версия)
- PowerShell скрипты
- Статический HTML dashboard
- Ручная загрузка JSON-отчетов

---

## 💬 Поддержка

При возникновении проблем:

1. Проверьте логи Node.js сервера в консоли
2. Проверьте логи браузера (F12 → Console)
3. Убедитесь что Pageant запущен и ключ загружен
4. Проверьте SSH-подключение вручную
5. Проверьте файрвол Windows

---

**Версия:** 2.0.0  
**Дата:** 2026-07-21  
**Автор:** VPN Infrastructure Team  
**Лицензия:** Internal use only
