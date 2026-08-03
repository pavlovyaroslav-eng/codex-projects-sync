# Проверочные workflows

## SDXL

`sdxl-smoke-api.json` — воспроизводимый API workflow: SDXL Base 1.0, Euler,
20 steps, 768×768. На установленной RTX 5070 результат сохраняется в
`/srv/local-ai/output/comfyui/smoke`.

## SAM 2 + FFmpeg video

Функциональный workflow реализован скриптами
`scripts/sam2_video_test.py` и `/usr/local/bin/sam2-video-test`:

1. создаются 18 кадров 512×512 с движущимся объектом;
2. FFmpeg формирует исходный H.264/AAC MP4;
3. кадры извлекаются в JPEG;
4. SAM 2.1 Hiera Small получает положительную point-подсказку на первом кадре;
5. маска распространяется на все кадры и сохраняется отдельно;
6. поверх кадров формируется проверочный overlay;
7. FFmpeg собирает H.264 через NVENC (с fallback на x264) и копирует исходный
   аудиопоток;
8. `ffprobe` проверяет наличие video и audio stream, итог записывается в
   `/srv/local-ai/output/sam2-test/result.json`.

Запуск:

```bash
sam2-video-test
```

ComfyUI custom nodes для пользовательских video workflows закреплены в
`docs/custom-nodes.md`. Wan weights сознательно не запускаются автоматически:
для них нужен отдельный 12-GB VRAM профиль и явно выбранный checkpoint.
