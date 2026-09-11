# Диагностика стабильности VPN и локального Hiddify — 2026-09-11

## Итог

- серверные health/deep checks прошли без ошибок;
- Hysteria2 и VLESS Reality доступны, в серии по 60 HTTP-проб потерь запросов не было;
- свежие переполнения UDP receive buffer устранены увеличением default socket buffers с 1 до 4 MiB на `hometele` и `azazello`;
- ошибка Hiddify `failed to start background core` локализована в Windows-клиенте 4.1.1: повторный запуск пытался создать уже существующий `tun0`;
- после полного завершения процесса, удаления `tun0` и чистого запуска клиент подключается без ошибки;
- установлен безопасный локальный launcher, который при неудачном старте освобождает TUN и выполняет один контролируемый повтор;
- AmneziaWG на `azazello` работает; клиентская ошибка 305 относится к SSH management-доступу, а не к UDP-туннелю.

Секреты, subscription token, UUID и ключи в документ не включены.

## Серверные измерения

Отчёт 60-пробного запуска:

```text
/opt/vpn-migration/reports/vpn-transport-monitor-20260911-194138.json
```

| Транспорт | Успешно | Потери HTTP | Среднее | p95 | Однопоточная скорость |
|---|---:|---:|---:|---:|---:|
| Hysteria2 | 60/60 | 0% | 0.2730 s | 0.7277 s | 6.79 Mbit/s |
| VLESS Reality | 60/60 | 0% | 0.7186 s | 5.3117 s | 11.47 Mbit/s |

Измерение скорости зависит от внешнего тестового объекта: повторная загрузка с GitHub была медленной и дошла до timeout. Это не сопровождалось потерей HTTP-проб или падением VPN-сервисов.

ICMP между `hometele` и `azazello`:

```text
hometele -> azazello: 0% loss, avg около 41.5 ms
azazello -> hometele: 6.67% loss, avg около 54.2 ms
```

Потери ICMP на внешнем маршруте не преобразовались в потери прикладных HTTP-проб через оба транспорта.

## UDP buffers

До изменения на `azazello` при нагрузке рос `UdpRcvbufErrors`; динамические UDP-сокеты `rw-core` имели receive buffer около 1 MiB. На обоих VPN-узлах применены:

```text
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
```

Максимальные буферы Hysteria2 остаются 16 MiB. После изменения за повторное нагрузочное окно счётчики не выросли:

```text
hometele:  UdpRcvbufErrors 12316 -> 12316
azazello:  UdpRcvbufErrors 7505860 -> 7505860
```

Rollback:

```text
hometele: /root/vpn-stability-rollbacks/20260911-194856/rollback.sh
azazello: /root/vpn-stability-rollbacks/20260911-194859/rollback.sh
```

## Hiddify 4.1.1 на Windows

Точная ошибка журнала:

```text
manager start inbound/tun[tun-in]: configure tun interface:
Cannot create a file when that file already exists
```

Это локальный lifecycle-конфликт TUN: сервер в момент ошибки оставался доступен. После clean stop были подтверждены удаление старого `tun0`, один процесс Hiddify и один новый TUN.

Безопасный launcher:

```text
C:\Users\ACER-X-02\AppData\Local\HiddifyTools\Hiddify-SafeStart.ps1
C:\Users\ACER-X-02\Desktop\Hiddify - безопасный запуск.lnk
C:\Users\ACER-X-02\AppData\Local\HiddifyTools\safe-start.log
```

Алгоритм launcher:

1. не перезапускает уже здоровое соединение, а только открывает существующее окно;
2. при отсутствии рабочего TUN завершает зависший процесс и ждёт удаления интерфейса;
3. запускает Hiddify и ждёт процесс, `tun0` и локальный core port;
4. если первый старт неуспешен, выполняет один clean retry;
5. пишет только технический результат без конфигурации и секретов.

Аварийный тест 2026-09-11: первый запуск не создал здоровый TUN за timeout; launcher очистил состояние и подключил VPN со второй попытки. После восстановления в новом `app.log` нет `failed to start bg core`.

Резервные копии локальных клиентов:

```text
C:\Users\ACER-X-02\AppData\Local\VPNClientBackups\20260911-192737
C:\Users\ACER-X-02\AppData\Local\VPNClientBackups\20260911-201111-hiddify-before-local-mtu
```

Оригинальный общий ярлык сохранён как `Hiddify-original.lnk` во второй резервной копии. Общий ярлык в `C:\Users\Public\Desktop` не менялся из-за отсутствия повышенного Windows token.

### MTU

Remnawave subscription template содержит TUN MTU `1280`. Hiddify 4.1.1 при стандартном режиме разбора профиля всё равно генерирует локальный gVisor TUN с виртуальным MTU `9000`; это поведение клиента, а не значение внешнего Ethernet/QUIC path MTU.

Контроль на локальном компьютере после восстановления:

```text
20/20 ICMP-проб к трём целям, потери 0%
DF payload до total MTU 1500 проходит
YouTube generate_204: 10/10
Telegram API: 10/10
Remnawave panel: 10/10
tun0 RX/TX errors/discards: 0/0/0/0
```

Поэтому повышать значение выше `9000` или принудительно уменьшать рабочий Windows TUN без подтверждённой фрагментации не требуется. Значение `1280` сохраняется в выдаваемом полном шаблоне для мобильных клиентов, которые исполняют inbound profile as-is.

## AmneziaVPN 4.8.21

- Windows service `AmneziaVPN-service` запущен автоматически от LocalSystem;
- контейнер `amnezia-awg2` на `azazello` работает и слушает UDP/39425;
- обнаружено 25 peer, два имели handshake за последние пять минут;
- накопленный обмен данными подтверждает реальный пользовательский трафик;
- SSH banner доступен на TCP/52000;
- TCP/22 принимает локальное TUN-соединение, но не выдаёт SSH banner и завершается timeout.

По официальной классификации Amnezia error 305 — SSH timeout. Для управления этим сервером клиент должен использовать SSH port `52000`; состояние UDP/39425 и WireGuard peer показывает, что сама VPN-служба не является причиной 305.

## Проверка после работ

```text
Hiddify process: 1
tun0: Up
local core 127.0.0.1:17078: LISTEN
VPN egress: foreign address confirmed
fresh background-core errors: 0
```

Для повторного серверного контроля:

```bash
sudo /opt/vpn-migration/tests/vpn-healthcheck.sh
sudo /opt/vpn-migration/tests/test-vpn.sh --deep
sudo /opt/vpn-migration/tests/monitor-vpn-transports.sh
```

## Откат

- локально восстановить каталоги Hiddify/Amnezia из указанной резервной копии только после полного завершения обоих клиентов;
- удалить пользовательский безопасный ярлык и launcher, затем вернуть сохранённый `Hiddify-original.lnk`, если требуется прежний запуск;
- UDP tuning откатывается соответствующим `rollback.sh` на каждом сервере;
- WIKI-запись откатывается отдельным `git revert` этого документа.

## Исправление синхронизации WIKI и baseline

На `hometele` и `azazello` ежедневный cron создавал локальные inventory/audit-коммиты, но отправка с 2026-09-04 отклонялась как `non-fast-forward`. Причины:

1. старый `/usr/local/sbin/vpn-wiki-sync-cron` выполнял `push` без предварительного `fetch`;
2. ветки серверов имеют независимые истории и не получают общую документацию из ветки `www` обычным merge;
3. часть объектов центрального bare-репозитория была записана от `root`, поэтому SSH-push сервисного пользователя завершался `unable to migrate objects to permanent storage`.

Исправлено:

- история каждой серверной ветки сначала сверяется с `origin/HOST`; допустим только fast-forward или уже содержащая remote локальная ветка, неизвестная дивергенция останавливает cron;
- общие документы копируются из `origin/www` строго по `scripts/wiki-common-paths.txt`, а host-specific `inventory/` и `notes/audit/` не перезаписываются;
- центральный bare-репозиторий и служебные файлы рабочих репозиториев принадлежат их штатным владельцам;
- baseline helper выполняет все Git-операции от владельца WIKI-репозитория, хотя health/audit остаются под `root`;
- актуальные audit path lists включают `/opt/remnanode`, Hysteria2 sysctl и, для `hometele`, `/opt/headscale`; старые пути удалённого standalone Xray/3x-ui исключены.

Резервные копии перед объединением историй и заменой cron:

```text
hometele: /root/vpn-stability-rollbacks/20260911-211300-wiki-sync/
azazello: /root/vpn-stability-rollbacks/20260911-211300-wiki-sync/
```

В каждом каталоге находятся старый cron и полный Git bundle соответствующей ветки.
