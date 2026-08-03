# Failed and incomplete steps

Дата: 2026-08-02

## `ufw status`

- команда: `ufw status` без `sudo`;
- результат: требуется административный доступ;
- причина: штатное ограничение UFW;
- безопасное исправление: после подтверждения выполнить только read-only
  `sudo ufw status numbered` и сохранить очищенный вывод.
- результат повторной проверки: выполнено `sudo ufw status verbose`; UFW
  активен, default incoming deny, правила ограничены `192.168.1.41` и `tun93`.

## `sshd -T`

- команда: `sshd -T` без root;
- результат: полезный вывод не получен;
- вероятная причина: непривилегированному процессу недоступны host keys либо
  полная конфигурация;
- безопасное исправление: после подтверждения `sudo sshd -T`, без reload.
- результат повторной проверки: `sudo sshd -t` завершился успешно, а
  `sudo sshd -T` подтвердил `permitrootlogin no`, `passwordauthentication no`
  и `pubkeyauthentication yes`; reload не выполнялся.

## `nvcc --version` через обычный `PATH`

- результат: команда не найдена в текущем `PATH`;
- причина подтверждена: путь CUDA не экспортирован в обычный `PATH`;
- повторная проверка: `/usr/local/cuda-13.2/bin/nvcc` существует, а package
  inventory подтверждает CUDA Toolkit 13.2.2 и `cuda-nvcc-13-2` 13.2.86;
- действие: переустановка не нужна; при сборке указывать `CUDA_HOME` и точный
  путь либо безопасно добавлять его только в окружение сборочного скрипта.

Других ошибок read-only аудита не зафиксировано.

## Первичная проверка `git status`

- команда: `git status --short --branch`, переданная через PowerShell pipeline
  в `ssh ... bash -s`;
- код возврата: 1;
- существенный stderr: `error: unknown option 'branch?'`;
- причина: завершающий CR из Windows CRLF попал в последний аргумент удалённой
  команды;
- безопасное исправление: команда повторена напрямую как
  `git -C /home/user/ai-station-bootstrap status -sb`; она завершилась с кодом 0
  и показала пустую ветку `main` с ожидаемыми новыми файлами.

## Составной static-tool inventory probe

- команда: read-only Bash inventory, переданный через PowerShell pipeline в
  `ssh ... bash -s`;
- код возврата: 1;
- существенный stderr: `syntax error: unexpected end of file`;
- причина: последний блок `dpkg-query` был повреждён при передаче многострочной
  команды; первая секция `command -v` успела корректно завершиться;
- безопасное исправление: версии пакетов и кандидаты повторно получены прямой
  SSH-командой с `LC_ALL=C`; установки не выполнялись.

## Загрузка двух remote-файлов одним SCP-вызовом

- команда: один `scp` с двумя remote source arguments;
- код возврата: 1;
- stderr: `protocol error: filename does not match request`;
- причина: strict filename checking OpenSSH SCP при нескольких remote sources;
- безопасное исправление: каждый файл загружен отдельным SCP-вызовом с
  сохранённым `StrictHostKeyChecking=yes`; `-T` не использовался.

## Первая post-install verification команда

- команда не дошла до удалённой станции;
- ошибка: локальный PowerShell parser отклонил неверно записанную Unicode escape
  sequence в формате `dpkg-query`;
- влияние: отсутствует, удалённые команды не выполнялись;
- безопасное исправление: повторная команда использовала штатный вывод
  `dpkg-query -W` и успешно сохранила полный post-install log.

## Проверка команды `7zz`

- результат: `7zz: command not found`;
- причина: Ubuntu transitional package `p7zip-full` установил актуальный пакет
  `7zip`, который предоставляет `/usr/bin/7z` и `/usr/bin/7zr`;
- безопасное исправление: проверка повторена через `7z`, версия 23.01
  подтверждена; переустановка не нужна.

## Первая составная команда проверки SSH/UFW

- команда не дошла до удалённой станции;
- ошибка: PowerShell интерпретировал часть вложенного регулярного выражения как
  локальную команду;
- влияние: отсутствует;
- безопасное исправление: `sshd -t`, `sshd -T` и `ufw status verbose`
  выполнены отдельными прямыми SSH-командами и завершились успешно.

## ClamAV FreshClam CDN

- команда: автоматический запуск `clamav-freshclam.service` из maintainer script
  официального Ubuntu-пакета;
- результат: exit status 17, HTTP 403 от `database.clamav.net`, CDN cooldown до
  `2026-08-03 17:53:04 MSK`; получен Cloudflare ray id, сохранённый в отдельном
  журнале этапа;
- состояние: пакеты ClamAV 1.5.3 установлены, но сигнатурных баз нет;
- безопасное действие: повторные запросы во время cooldown не выполняются,
  transient failed state очищен, unit оставлен `disabled/inactive`; перед
  использованием `clamscan` требуется успешное получение и проверка баз.

## Первая сводная final-verification команда

- журнал: `logs/10-final-verification-20260802T150150Z.log`;
- результат: проверка документального backup была запущена не из каталога с
  `SHA256SUMS`, а вложенные кавычки повредили форматный аргумент `stat`;
- дополнительная ошибка обвязки: составная команда не использовала `set -e`,
  поэтому промежуточные ошибки не определили итоговый код возврата;
- влияние: система и конфигурация не изменялись; этот журнал помечен как
  неавторитетный и не используется для вывода об успехе;
- безопасное исправление: все проверки повторены отдельными SSH-вызовами с
  контролем каждого exit code. Авторитетный журнал:
  `logs/10-final-verification-corrected-20260802T150227Z.log`;
- повторная проверка: root backup и documentation backup прошли
  `sha256sum -c`, `dpkg --audit` пуст, скрипт прошёл `bash -n`, failed units
  отсутствуют, API/GPU/порты проверены.

## Quoting в NVIDIA read-only probes

- несколько составных команд не дошли до удалённой станции либо завершились до
  полезной проверки: PowerShell интерпретировал `$(uname -r)` локально,
  регулярное выражение с `|` было разделено на команды, а вложенная команда
  `find ... -exec` получила повреждённые кавычки;
- один цикл ошибочно счёл штатный exit code 1 от `journalctl --grep` при
  отсутствии совпадений за сбой;
- влияние: конфигурация и пакеты не изменялись, команды были read-only;
- безопасное исправление: package name передан с экранированным remote command
  substitution, `lspci` и journal patterns выполнены отдельными SSH-вызовами,
  а exit code 1 для пустого journal query обработан явно. Итоговые проверки
  завершились успешно и сохранены в логах этапа 20.

## Требование «отсутствие ошибок ядра» для NVIDIA

- `NVRM Xid`, Fatal и Non-Fatal AER не найдены;
- найдено 16 событий `PCIe Bus Error: severity=Correctable, type=Data Link
  Layer` с флагом Timeout для `0000:02:00.0`, последнее 2026-08-02 12:54:39;
- после CUDA smoke новых NVIDIA kernel events нет, runtime и CUDA исправны;
- статус: требование нельзя отметить безусловно выполненным из-за Correctable
  AER; переустановка драйвера не показана. Нужны мониторинг и отдельное
  согласование перед физической проверкой слота, питания или BIOS PCIe.

## Первая проверка `20-install-nvidia.sh` во временном каталоге

- синтаксис скрипта и отдельная CUDA-компиляция были успешны;
- runtime script завершился кодом 2 в безопасном plan-only режиме;
- причина: локализованный русский вывод `apt-cache policy` не содержал
  английского поля `Candidate:`, поэтому parser получил пустую версию;
- влияние: пакеты, драйвер и конфигурация не изменялись;
- исправление: для `apt-cache policy` задан `LC_ALL=C`; после этого кандидат
  `595.84-0ubuntu0.24.04.1` корректно совпал с установленной версией.

## Первая journal-выборка исправленного NVIDIA-скрипта

- скрипт успешно завершил runtime/CUDA-проверки, но показал 0 Correctable AER;
- причина: анализировались последние 500 строк всего kernel journal, из которых
  более ранние NVIDIA AER события уже выпали;
- влияние: система не изменялась, отдельный специализированный журнал уже
  сохранял все 16 событий;
- исправление: `journalctl` сначала фильтруется по `nvidia`, затем ограничивает
  результат 500 строками; повторная проверка должна показать 16 событий.

## Первый архив Ghidra

- команда: official Ghidra 12.1.2 asset download через `curl --continue-at -`;
- результат: неверные size/SHA-256, загрузку продолжали два orphan curl process;
- причина: два предыдущих SSH client timeout оставили удалённые writer process;
- безопасное исправление: найдены и остановлены только точные PID этих curl,
  повреждённый `.part` перемещён в отдельное имя, asset скачан заново и прошёл
  SHA-256 `b62e81a0390618466c019c60d8c2f796ced2509c4c1aea4a37644a77272cf99d`;
  повреждённый временный архив удалён после успешной установки.

## PyGhidra MCP dependency conflict

- команда: первая установка `pyghidra-mcp==0.2.3` с автоматически выбранным
  `mcp==2.0.0`;
- код возврата: 1;
- stderr: `ModuleNotFoundError: No module named 'mcp.server.fastmcp'`;
- причина: pyghidra-mcp 0.2.3 использует API MCP 1.x;
- исправление: venv изолирован, `mcp[cli]==1.29.0` зафиксирован, imports и
  service проверены. Ghidra не понижалась.

## MCP embedding cache при network isolation

- результат первого code/string indexing: модель Chroma не могла быть получена
  службой с `IPAddressDeny=any`;
- причина: ожидаемое противоречие между first-run download и network deny;
- исправление: официальный `all-MiniLM-L6-v2/onnx.tar.gz` скачан вне службы,
  проверен SHA-256 `913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3`
  и preseeded в private cache `ghidramcp`; indexing затем прошёл без сети.

## KVM verification pipeline

- команда: первый `scripts/95-create-analysis-vm.sh --apply`;
- код возврата: 141;
- существенный stderr: trap указал pipe с `grep -q`;
- причина: `pipefail` воспринял SIGPIPE producer после раннего выхода grep;
- исправление: вывод `virsh` сначала захватывается, затем проверяется here-string;
  повторный запуск, safe ISO test, snapshot и revert успешны.

## Финальная проверка model download script

- команда: `scripts/40-download-model.sh --apply`, строка проверки
  `sha256sum -c SHA256SUMS`;
- код возврата: 1 после уже успешных download/hash/atomic rename;
- stderr: `sha256sum: SHA256SUMS: Permission denied`;
- причина: manifest и model были правильно переведены в `root:qwenllm 0640`,
  а финальную проверку пытался выполнить `user`;
- исправление: проверка выполняется как `qwenllm`; повторный полный SHA-256 —
  PASS. Модель не перекачивалась.

## Первые benchmark/service prechecks

- команды: `tests/benchmark-llama.sh` и
  `scripts/50-configure-llm-service.sh --apply`;
- код возврата: 1 на `test -r MODEL`;
- причина: администратор намеренно не входит в группу `qwenllm`, model 0640;
- исправление: benchmark запускается под `qwenllm`, service precheck выполняется
  через `sudo -u qwenllm`; четыре профиля и service cutover затем успешны.

## Extended LLM context request

- команда: первый long-system API test с 2500 повторами русской фразы;
- код возврата: 1, HTTP 400;
- причина: tokenized request превысил context 32768;
- исправление: размер снижен без обхода лимита; фактический long request на
  11,228 prompt tokens вернул `ПРИНЯТО`. Отдельный context test успешно
  обработал 16,396 prompt tokens.

## Qwen Code local provider activation

- первая non-interactive команда без `--auth-type`: exit 1,
  `No auth type is selected`;
- после добавления auth type, но с неподдерживаемой runtime-схемой provider:
  команда завершила CLI-сеанс с API error 401 от Alibaba endpoint;
- причина: Qwen Code 0.21.3 runtime ожидает `modelProviders.openai` как массив,
  `security.auth.selectedType=openai` и доступный `OPENAI_API_KEY`;
- исправление: использована фактическая схема standalone 0.21.3, base URL
  `http://127.0.0.1:8012/v1` и фиктивное non-secret значение
  `local-not-required`. Запуск без CLI override вернул `QWEN_OK`; MCP connected.

## PowerShell/SSH quoting в поздних read-only probes

- несколько сводных one-liner проверок получили локальную интерпретацию `$()`
  или повреждённые кавычки `jq`, а короткий SSH timeout отсоединил клиент во
  время удалённого SHA-256;
- влияние: затронутые проверки были read-only либо удалённый hash продолжился;
  системные настройки не повреждены;
- исправление: сложная логика перенесена в versioned scripts, проверки
  повторены отдельными SSH-вызовами; authoritative final log —
  `logs/99-verify-stack-20260802T192654Z.log`.

## Внешние незавершённые компоненты

- ClamAV signatures: CDN HTTP 403/cooldown, безопасное действие — не повторять
  до 2026-08-03 17:53 MSK;
- Windows guest: ISO отсутствует, поэтому установлена только проверенная
  изолированная VM definition/snapshot; FLARE-VM не устанавливалась;
- reboot test: выполнен после отдельного подтверждения, итог PASS;
- Git commit: не создавался без `user.name`/`user.email` владельца.

## Legacy health timer после LLM cutover

- команда: `systemctl --failed --no-legend`;
- исходное состояние: `local-ai-health.service` failed, timer active каждые пять минут;
- причина: существующий `/usr/local/sbin/local-ai-health-check` жёстко опрашивает
  снятый `http://127.0.0.1:8080/health`, тогда как новый API находится на 8012;
- влияние: ложный мониторинговый alarm; `qwen3-coder` и `pyghidra-mcp` active,
  их health/API проверки проходят;
- применённое исправление: `scripts/98-update-legacy-health-check.sh --apply`
  создаёт root backup, проверяет новый script через `bash -n`, заменяет checker,
  запускает oneshot и очищает failed state;
- backup первого варианта:
  `/srv/local-ai/backups/ai-station-bootstrap-20260802T200840Z/`;
- первый post-reboot timer run снова вернул 1, потому что legacy Open WebUI не
  имеет autostart и порт 3000 ожидаемо отсутствовал;
- окончательное исправление: Open WebUI проверяется только если его unit active;
  обязательные Qwen/MCP/NVIDIA/disk checks сохранены. Второй backup:
  `/srv/local-ai/backups/ai-station-bootstrap-20260802T201351Z/`;
- итог: oneshot status 0, `Result: 0 error(s)`, timer active/enabled,
  `systemctl --failed` пуст; health-check SHA-256
  `087949de327fc545d403ad021745dc9742cd49c6f752958fa82a528c62f2de50`.
