# Llama benchmark

Дата: 2026-08-02. Модель: Qwen3-Coder-30B-A3B-Instruct Q4_K_M;
llama.cpp b10229/CUDA; RTX 5070 12 GiB; 28 физических CPU cores.

## Профили llama-bench

Каждый профиль выполнил prompt 512 tokens и generation 32 tokens, exit 0.
K/V cache Q8_0, Flash Attention on, mmap, KV cache в RAM.

| Профиль | GPU layers | CPU MoE | Threads | Batch / µbatch | Prompt tok/s | Gen tok/s | Wall | Max RSS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| balanced | 99 | 32 | 28 | 512 / 128 | **115.50** | **35.07** | 13.15 s | 17.63 GiB |
| lower_gpu_layers | 70 | 32 | 28 | 512 / 128 | 115.36 | 34.69 | 12.86 s | 17.63 GiB |
| more_cpu_moe | 99 | 36 | 28 | 512 / 128 | 106.89 | 31.73 | 13.43 s | 17.63 GiB |
| smaller_batch_more_threads | 99 | 32 | 32 | 256 / 64 | 70.42 | 29.32 | 18.66 s | 17.63 GiB |

До теста GPU: 76 MiB, 36°C. В телеметрии максимальное framebuffer usage —
около 7002 MiB, максимальная температура — 46°C; после — 76 MiB и 44°C.
OOM и ненулевых exit codes не было. `mpstat -P ALL 1` записал загрузку всех
56 logical CPUs; firmware предоставляет один NUMA node, поэтому достоверно
разделить нагрузку по двум сокетам нельзя.

## Контекстная матрица

Каждый сервер запускался отдельно с выбранным профилем и выполнял реальный
OpenAI chat request примерно на половину заявленного context size.

| Context | Реальные prompt tokens | Startup | Request time | Наблюдаемый prompt tok/s | GPU used/free | Service memory |
|---:|---:|---:|---:|---:|---:|---:|
| 8192 | 4108 | 4.118 s | 11.880 s | 345.81 | 6918 / 4855 MiB | 747 MiB |
| 16384 | 8203 | 4.100 s | 24.311 s | 337.42 | 6926 / 4847 MiB | 1.12 GiB |
| 32768 | 16396 | 5.106 s | 52.384 s | 313.00 | 6946 / 4827 MiB | 1.93 GiB |

Все три режима завершили запрос с `finish_reason=stop`, без OOM и swap
thrashing. В рабочем сервисе после end-to-end тестов: 7053 MiB VRAM used,
4720 MiB free, 47°C, host available RAM 55 GiB, swap used 632 KiB,
`NRestarts=0`.

## Выбранная конфигурация

Выбран `balanced`: 99 GPU layers, 32 CPU MoE experts, 28 threads, batch 512,
µbatch 128, context 32768, parallel 1. Он дал лучший prompt throughput и
generation throughput, сохранив более 4.7 GiB VRAM. Это стабильнее и заметно
выше требуемого резерва 1–1.5 GiB.

Исходные данные: `logs/llama-benchmark-20260802T190816Z/` и
`logs/llm-context-matrix-20260802T191109Z/`.
