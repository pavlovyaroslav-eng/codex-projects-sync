# Руководство по интеграции локальных медиа-инструментов в Qwen Code

## Общее описание

Цель: Подключить к Qwen Code дополнительные локальные инструменты для работы с видео, звуком и текстовыми документами, сохранив работоспособность существующего Ghidra MCP.

## Требования

1. **Видео и изображения**:
   - FFmpeg и ffprobe
   - ComfyUI и связанные компоненты
   - SAM2
   - ImageMagick и ExifTool
   - Qwen3-VL

2. **Звук**:
   - faster-whisper
   - Whisper модель turbo
   - ai-transcribe
   - FFmpeg и ffprobe

3. **Текст и документы**:
   - pdftotext, pdfinfo, mutool, qpdf
   - Tesseract OCR
   - OCRmyPDF
   - Pandoc
   - LibreOffice headless
   - Python библиотеки для работы с документами

## Архитектура решения

### Новый MCP сервер
Создать один локальный MCP-сервер через stdio с именем local-media:

- **Не создавать публичный сетевой listener**
- **Использовать существующие компоненты**, не устанавливать новые
- **Ограничить рабочие каталоги**:
  - /home/user/AI-Workbench
  - /srv/local-ai/input
  - /srv/local-ai/output
  - Специально созданный каталог временных файлов

### Инструменты для видео:
- video_probe
- video_extract_frames
- video_extract_audio
- video_transcode
- video_trim
- video_concat
- video_resize
- video_create_preview
- video_add_subtitles
- video_audio_replace
- video_sam2_track
- video_comfyui_submit
- video_comfyui_status
- video_comfyui_result

### Инструменты для аудио:
- audio_probe
- audio_convert
- audio_extract_from_video
- audio_normalize
- audio_trim
- audio_merge
- audio_transcribe
- audio_create_subtitles
- audio_detect_silence
- audio_split_on_silence

### Инструменты для текста/документов:
- text_read
- text_search
- document_info
- pdf_extract_text
- pdf_extract_images
- ocr_image
- ocr_pdf
- docx_extract_text
- pptx_extract_text
- xlsx_extract_cells
- document_convert_to_text
- subtitle_read
- subtitle_translate_prepare

## Безопасность

- **Не использовать произвольные shell-строки**
- **Разрешить только конкретные программы и аргументы**
- **Проверять существование входного файла**
- **Проверять realpath**
- **Ограничивать размеры файлов**
- **Устанавливать timeout**
- **Ограничивать объём stdout/stderr**
- **Сохранять логи без содержимого секретов**
- **Не перезаписывать исходные файлы**
- **Создавать новые файлы в output-каталоге**

## Режимы работы

- **Сохранить существующий режимный менеджер**: ai-mode llm, image, video, whisper, off
- **Не переключать режимы автоматически**
- **Ghidra MCP работает в режиме LLM**
- **Whisper использует VPN-порт 8000**
- **Система не должна конфликтовать с существующей архитектурой**

## Реализация

### 1. Подготовка структуры проекта

Создать каталоги:
- /home/user/codex-projects-export/local-ai-deployment/media-tools/
- /home/user/codex-projects-export/local-ai-deployment/media-tools/scripts/
- /home/user/codex-projects-export/local-ai-deployment/media-tools/config/

### 2. Создание скриптов

Создать скрипты обертки для каждого инструмента, использующие:
- FFmpeg для видео/аудио
- Tesseract для OCR
- PDF-инструменты для документов
- Whisper для транскрипции

### 3. Настройка MCP сервера

Создать конфигурационный файл для нового MCP сервера с именем local-media.

### 4. Обновление конфигурации Qwen

Добавить новый сервер local-media в файл настроек без удаления ghidra.

### 5. Тестирование

Создать тестовые файлы и выполнить проверку работы всех инструментов.

## Резервные копии

Все изменяемые файлы должны быть скопированы перед изменением:
- /home/user/.qwen/settings.json
- Конфигурационные файлы скриптов
- Скрипты обертки

## Требования к реализации

1. **Не изменять существующий Ghidra MCP**
2. **Не удалять или заменять существующую конфигурацию**
3. **Использовать только уже установленные компоненты**
4. **Создавать только безопасные инструменты**
5. **Сохранить все существующие функции**

## Проверка безопасности

1. Всегда проверять realpath входных файлов
2. Ограничивать допустимые расширения
3. Ограничивать размеры файлов
4. Устанавливать timeout на выполнение
5. Не использовать произвольные абсолютные пути
6. Не запускать неизвестные бинарные файлы
