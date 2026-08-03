# Open ports — final snapshot

Дата: 2026-08-02 после переключения LLM.

| Bind | Порт | Служба | Решение |
|---|---:|---|---|
| `127.0.0.1` | 8012/tcp | Qwen3-Coder / llama.cpp | новый LLM, loopback-only |
| `0.0.0.0` | 8080/tcp | OpenAI/tool-call compatibility proxy | Acer `192.168.1.41/32` и `tun93` `10.93.0.0/24` only |
| `127.0.0.1` | 8000/tcp | PyGhidra MCP | loopback-only |
| `0.0.0.0`, `[::]` | 22/tcp | OpenSSH | существующий key-only admin access |
| `127.0.0.1`, `[::1]` | 631/tcp | CUPS | loopback-only |
| `127.0.0.53/54` | 53 tcp/udp | systemd-resolved | локальный resolver |
| wildcard UDP | 5353 и dynamic | mDNS/legacy discovery | существующее состояние, не менялось |

3000/tcp не слушает. Проверка с Acer к `192.168.1.65:8000` и `:8012`
завершилась connection timeout; `:8080` отвечает по LAN и OpenVPN и возвращает
модель `qwen3-coder-30b-a3b-q4km`.

UFW active: default incoming deny, routed deny. Существующие allow rules
ограничены controller `192.168.1.41` и VPN `tun93`. Для `:8080` использованы уже
существовавшие точные правила; новые firewall rules не добавлялись и область
доступа не расширялась. Публичного проброса нет.

## Актуализация 2026-08-03

Предыдущая строка о закрытом `3000/tcp` историческая и больше не отражает
runtime:

| Bind | Порт | Служба | Scope |
|---|---:|---|---|
| `0.0.0.0` | 3000/tcp | Open WebUI | controller/VPN UFW only |
| `127.0.0.1` | 8000/tcp | PyGhidra MCP | loopback backend |
| `10.93.0.10` | 8000/tcp | MCP socket proxy | VPN only, LLM mode |
| `0.0.0.0` | 8000/tcp | Whisper | whisper mode вместо MCP |

`ai-mode` и systemd `Conflicts` исключают одновременное владение портом 8000.
