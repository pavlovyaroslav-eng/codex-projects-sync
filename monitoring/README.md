# VPN Infrastructure Monitoring System

Комплексная система мониторинга для инфраструктуры из трёх VPN-серверов: `azazello`, `hometele`, и `www`.

## 📋 Состав системы

### 1. **server-health-check.sh**
Универсальный bash-скрипт для сбора метрик на серверах. Проверяет:
- Системные ресурсы (CPU, RAM, диск, uptime, load average)
- Состояние сервисов (systemd, Docker)
- VPN-статус (Xray, WireGuard, OpenVPN)
- Сетевые интерфейсы и открытые порты
- Безопасность (fail2ban, ufw)
- Критические порты (443 для azazello/hometele)

**Вывод:** JSON-формат для парсинга

### 2. **Run-ServerMonitoring.ps1**
PowerShell-скрипт для запуска мониторинга через SSH с Windows. Возможности:
- Автоматическое подключение ко всем серверам
- Развёртывание health-check скрипта
- Сбор и сохранение метрик в JSON
- Отображение сводки в терминале
- Непрерывный мониторинг с интервалом

### 3. **dashboard.html**
Веб-интерфейс для визуализации метрик:
- Красивый дашборд с картами серверов
- Прогресс-бары для ресурсов
- Статусы сервисов и критических портов
- Drag-and-drop загрузка отчётов
- Автообновление

## 🚀 Быстрый старт

### Предварительные требования

1. **Windows-машина** с установленными:
   - PowerShell 5.1+
   - OpenSSH Client (`ssh` и `scp` команды)
   - Современный браузер для dashboard

2. **SSH-доступ к серверам:**
   ```powershell
   # Проверьте наличие SSH-ключа
   Test-Path "$env:USERPROFILE\.ssh\id_rsa"
   
   # Если ключа нет, создайте его:
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   
   # Скопируйте ключ на серверы:
   ssh-copy-id -i ~/.ssh/id_rsa.pub suazzzi@azazello.raxla.org
   ssh-copy-id -i ~/.ssh/id_rsa.pub suazzzi@hometele.com.ru
   ssh-copy-id -i ~/.ssh/id_rsa.pub suazzzi@www-vpn-wiki-sync
   ```

3. **Настройте конфигурацию серверов** в `servers.json`:
   ```json
   {
     "servers": [
       {
         "name": "azazello",
         "host": "azazello.raxla.org",
         "ip": "91.242.163.206",
         "description": "Czech external gateway",
         "critical_services": ["xray", "docker"],
         "critical_ports": [443, 9443]
       },
       {
         "name": "hometele",
         "host": "hometele.com.ru",
         "ip": "185.71.196.110",
         "description": "Russian entry point",
         "critical_services": ["xray", "postfix"],
         "critical_ports": [443, 80]
       },
       {
         "name": "www",
         "host": "www-vpn-wiki-sync",
         "ip": "",
         "description": "Service node - Matrix, Git-WIKI",
         "critical_services": ["matrix-synapse", "nginx", "coturn"],
         "critical_ports": [8008, 8080, 5349]
       }
     ]
   }
   ```

## 📊 Использование

### Вариант 1: Одноразовая проверка

```powershell
# Базовый запуск
.\Run-ServerMonitoring.ps1

# С отображением dashboard в терминале
.\Run-ServerMonitoring.ps1 -ShowDashboard

# С нестандартным SSH-ключом
.\Run-ServerMonitoring.ps1 -SshKeyPath "C:\path\to\key" -SshPort 2222

# Отчёты сохраняются в ./monitoring-reports/
```

### Вариант 2: Непрерывный мониторинг

```powershell
# Мониторинг каждые 5 минут (300 сек)
.\Run-ServerMonitoring.ps1 -Continuous -IntervalSeconds 300 -ShowDashboard

# Мониторинг каждую минуту
.\Run-ServerMonitoring.ps1 -Continuous -IntervalSeconds 60
```

### Вариант 3: Веб-dashboard

```powershell
# 1. Запустите мониторинг для сбора данных
.\Run-ServerMonitoring.ps1

# 2. Откройте dashboard.html в браузере
Start-Process dashboard.html

# 3. Перетащите JSON-отчёты из ./monitoring-reports/ в окно браузера
# ИЛИ используйте кнопку "Load Reports"
```

### Вариант 4: Автоматизация через планировщик

Создайте задачу в Windows Task Scheduler:

```powershell
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\path\to\Run-ServerMonitoring.ps1`" -Continuous -IntervalSeconds 300"

$trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "VPN Infrastructure Monitoring" `
    -Description "Continuous monitoring of VPN servers"
```

## 📈 Метрики и алерты

### Критические параметры

Скрипт отслеживает следующие критические состояния:

| Метрика | Предупреждение | Критично |
|---------|----------------|----------|
| CPU Usage | > 70% | > 85% |
| Memory Usage | > 70% | > 85% |
| Disk Usage | > 70% | > 85% |
| Failed Services | > 0 | > 2 |
| Port 443 | Не слушает | N/A |

### Специфичные проверки для серверов

**azazello:**
- Xray/3x-ui статус
- Docker containers
- MTProto proxy (порт 9443)
- WARP outbound

**hometele:**
- Xray Reality (порт 443)
- Postfix (mail)
- OpenVPN tun79
- WireGuard wg-home

**www:**
- Matrix Synapse (порт 8008)
- Nginx
- Coturn (порт 5349)
- Synapse Admin (порт 8080)
- Git-WIKI sync status

## 🔒 Безопасность

### Read-Only режим

Все проверки выполняются в **read-only** режиме. Скрипты:
- ❌ НЕ перезапускают сервисы
- ❌ НЕ изменяют конфигурацию
- ❌ НЕ трогают порт TCP 443
- ❌ НЕ изменяют firewall
- ✅ Только читают состояние системы

### Минимальные привилегии

Скрипт требует только:
- SSH-доступ с ключом
- Стандартные команды: `systemctl`, `ss`, `ip`, `wg`, `docker ps`
- `sudo` только для `ufw status` (безопасная read-only команда)

### Секреты

- SSH-ключи хранятся локально
- Отчёты **не содержат** паролей, токенов, приватных ключей
- MTProto secrets автоматически обезличиваются
- `.pub` ключи заменяются на fingerprints

## 📁 Структура директорий

```
monitoring/
├── server-health-check.sh      # Bash-скрипт для серверов
├── Run-ServerMonitoring.ps1    # PowerShell-обёртка
├── dashboard.html              # Веб-интерфейс
├── servers.json                # Конфигурация серверов (создаётся автоматически)
├── monitoring-reports/         # JSON-отчёты (создаётся автоматически)
│   ├── azazello-20260721-210530.json
│   ├── hometele-20260721-210531.json
│   └── www-20260721-210532.json
└── README.md                   # Этот файл
```

## 🐛 Troubleshooting

### Проблема: SSH connection failed

```powershell
# Проверьте доступность хоста
Test-NetConnection -ComputerName azazello.raxla.org -Port 22

# Проверьте SSH-ключ
ssh -i "$env:USERPROFILE\.ssh\id_rsa" suazzzi@azazello.raxla.org echo OK

# Если используется нестандартный порт:
.\Run-ServerMonitoring.ps1 -SshPort 2222
```

### Проблема: Permission denied

```bash
# На сервере проверьте права:
ls -la ~/.ssh/authorized_keys
# Должно быть: -rw------- (600)

# Если нет, исправьте:
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### Проблема: Script not executable

```bash
# На сервере:
chmod +x /tmp/server-health-check.sh
```

### Проблема: Dashboard не показывает данные

1. Убедитесь, что JSON-отчёты существуют в `./monitoring-reports/`
2. Откройте DevTools браузера (F12) и проверьте консоль на ошибки
3. Перетащите JSON-файлы прямо в окно браузера
4. Проверьте, что JSON-файлы валидны:

```powershell
Get-Content .\monitoring-reports\azazello-*.json | ConvertFrom-Json
```

## 🔧 Расширение системы

### Добавление новых метрик

Отредактируйте `server-health-check.sh`, добавив функции:

```bash
check_custom_service() {
    # Ваша логика проверки
    echo '{"status":"ok","details":"..."}'
}

# В main JSON output добавьте:
"custom": $(check_custom_service)
```

### Интеграция с alerting

Добавьте в PowerShell-скрипт отправку уведомлений:

```powershell
function Send-Alert {
    param($ServerName, $Message)
    
    # Telegram Bot
    $token = "YOUR_BOT_TOKEN"
    $chatId = "YOUR_CHAT_ID"
    Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" `
        -Method Post -Body @{ chat_id = $chatId; text = "$ServerName: $Message" }
}

# Вызовите при обнаружении проблем
if ($health.services.failed_count -gt 0) {
    Send-Alert -ServerName $server.name -Message "Failed services detected!"
}
```

### Экспорт в Prometheus

Создайте node exporter для метрик:

```bash
# На сервере установите:
apt install prometheus-node-exporter

# Метрики будут доступны на :9100/metrics
```

## 📝 Примеры использования

### Быстрая проверка всех серверов

```powershell
.\Run-ServerMonitoring.ps1 -ShowDashboard
```

**Вывод:**
```
[2026-07-21 21:05:30] [INFO] Loaded 3 servers from config
[2026-07-21 21:05:30] [INFO] Testing connection to azazello...
[2026-07-21 21:05:31] [SUCCESS] Connection successful to azazello
[2026-07-21 21:05:31] [INFO] Deploying health check script to azazello.raxla.org...
[2026-07-21 21:05:32] [SUCCESS] Script deployed successfully to azazello.raxla.org
...

╔════════════════════════════════════════════════════════════════╗
║          VPN Infrastructure Health Dashboard                   ║
╚════════════════════════════════════════════════════════════════╝

┌─ azazello ─────────────────────────────────
│ Uptime      : up 15 days
│ CPU Usage   : 12.5%
│ Memory      : 45.2% used
│ Disk Usage  : 62%
│ Load Avg    : 0.15, 0.20, 0.18
│
│ Services:
│   • xray                 : active
│   • docker               : active
│   • fail2ban             : active
│   • ufw                  : active
│
│ Xray        : true
│
│ Critical Ports:
│   • Port 443: listening
│   • Port 9443: listening
└────────────────────────────────────────────────────────
```

### Мониторинг с автообновлением в браузере

```powershell
# Терминал 1: Запустите непрерывный мониторинг
.\Run-ServerMonitoring.ps1 -Continuous -IntervalSeconds 60

# Терминал 2: Откройте dashboard
Start-Process dashboard.html

# Dashboard будет автоматически обновляться при перетаскивании новых отчётов
```

## 📚 Связанные документы

- [Architecture](../codex-projects-export/01-vpn-server-infrastructure/wiki/architecture.md)
- [Health Check Runbook](../codex-projects-export/01-vpn-server-infrastructure/wiki/runbooks/health-check.md)
- [Service Recovery](../codex-projects-export/01-vpn-server-infrastructure/wiki/runbooks/service-recovery.md)

## 📧 Поддержка

При возникновении проблем проверьте:
1. SSH-подключение к серверам
2. Логи в консоли PowerShell
3. Валидность JSON-отчётов
4. Права доступа на серверах

---

**Создано:** 2026-07-21  
**Версия:** 1.0  
**Лицензия:** Internal use only
