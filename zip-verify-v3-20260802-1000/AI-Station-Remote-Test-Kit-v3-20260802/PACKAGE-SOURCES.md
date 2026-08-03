# Источники и зафиксированные версии

- `open-interpreter==0.4.3`
- `litellm==1.41.26`
- PyPI: https://pypi.org/project/open-interpreter/0.4.3/
- Wheel: `open_interpreter-0.4.3-py3-none-any.whl`
- SHA-256 wheel: `bb694b826b11986a305b7d34acbabae830481bb1180b52fe1b912e882a21b590`
- LiteLLM wheel: `litellm-1.41.26-py3-none-any.whl`
- LiteLLM wheel SHA-256: `b4090403dace2349b3325768a700bde868b5f7d9f24ff89895e8bdd2171e28b2`
- LiteLLM PyPI: https://pypi.org/project/litellm/1.41.26/
- Официальная установка: https://docs.openinterpreter.com/getting-started/setup
- Custom/local endpoint: https://docs.openinterpreter.com/guides/running-locally
- Python 3.11.9: https://www.python.org/downloads/release/python-3119/
- Windows installer: https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
- SHA-256 installer: `5ee42c4eee1e6b4464bb23722f90b45303f79442df63083f05322f1785f5fdde`

При отсутствии Python используется официальный Windows installer x64. Перед
запуском скрипт проверяет SHA-256 и Authenticode-подпись Python Software Foundation.

`requirements-lock.txt` разрешён для Windows/Python 3.11 с отсечкой выпусков
2024-10-27 — сразу после публикации Open Interpreter 0.4.3.

Wheel использовался только для проверки версии и совместимости параметров.
Он не включён в архив; установщик загружает пакет и зависимости напрямую из
PyPI в отдельное виртуальное окружение.
