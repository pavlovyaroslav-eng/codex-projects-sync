# Проверенные результаты

Хост: 2 × Xeon E5-2680 v4, 64 GiB RAM, RTX 5070 12 GiB, Ubuntu 24.04.4,
driver 595.84. Значения — фактические smoke/functional tests, не заявленные
производителем показатели.

| Компонент | Режим | VRAM | RAM | Скорость/время | Контекст/разрешение | Результат |
|---|---|---:|---:|---:|---:|---|
| PyTorch 2.12 cu132 | FP32 matmul | — | — | 0,334 s | 4096×4096 | PASS, CUDA device RTX 5070 |
| Qwen3-14B Q4_K_M | full GPU, flash-attn, Q8 KV | 9 269 MiB peak | не зафиксировано | 64,736 tok/s generation | 8 192 | PASS, русский ответ `Система готова.` |
| SDXL Base 1.0 | ComfyUI, Euler, 20 steps | 7 354 MiB peak | не зафиксировано | 10,7 s | 768×768 | PASS, PNG сохранён |
| Whisper turbo | CTranslate2 `int8_float16` | отдельный GPU mode | — | функциональный test | audio 3,516875 s | PASS, русский текст распознан дословно |
| Qwen3-Coder-30B-A3B | Q4_K_M, 32 MoE layers on CPU | 7 546 MiB | service RSS 930 263 040 B | 40,425 tok/s; 1,616 s request | 8 192 | PASS, корректная Python-функция |
| Qwen3-VL-8B | Q4_K_M + Q8_0 mmproj | 6 670 MiB | service RSS 454 639 616 B | 106,174 tok/s; 0,761 s request | 8 192 + SDXL image | PASS, робот и надпись `LOCAL` распознаны по-русски |
| SAM 2.1 Hiera Small | bf16, video tracking | 859 MiB Torch allocated peak | — | 4,679 s | 512×512, 18 frames | PASS, H.264 NVENC + исходный AAC |

Температуры: Qwen short test — 62 °C; SDXL generation — 68 °C; Coder — 47 °C;
VL — 52 °C; SAM2 — 43 °C. OOM, CUDA errors
и driver reset в выполненных тестах не обнаружены.

Длинные LLM context 16K/32K и сравнительный SMT/NUMA benchmark сознательно не
запускались в сокращённом режиме проверок; рабочий профиль зафиксирован на 8K.
