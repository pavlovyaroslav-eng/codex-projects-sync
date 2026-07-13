# WIKI инфраструктуры VPN-серверов

Сводная документация по серверам `www`, `hometele` и `azazello`. Каталог `upstream/` — автоматически обезличенное одностороннее зеркало центрального Git-WIKI. Ручные изменения выполняются только в остальных разделах `wiki/`.

Ветки `www`, `hometele` и `azazello` импортированы через Pageant в пакетном режиме. Их базовые `01-INVENTORY.md`, `02-RUNBOOK.md`, `03-SELF-HEALING.md` и `README-VPN-SERVER.md` совпадают; серверные снимки и audit-baselines хранятся отдельно в каждой ветке.

- [Архитектура](architecture.md)
- [Текущее состояние](current-state.md)
- [Серверы](servers/)
- [Сервисы](services/)
- [Инструкции](runbooks/)
- [Автоматическое зеркало](upstream/README.md)
