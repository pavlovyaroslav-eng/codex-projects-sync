# Модели и зафиксированные источники

| Компонент | Файл/версия | Размер, bytes | SHA256 | Источник |
|---|---|---:|---|---|
| Qwen3-14B | `Qwen3-14B-Q4_K_M.gguf` | 9,001,753,376 | `5ff1fe7a07aebc8d090682d01b17cf268a1b4680c6477050ce75a600aecb9efb` | `ggml-org/Qwen3-14B-GGUF` |
| Qwen3-Coder-30B-A3B | `Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf` | 18,632,186,176 | `79ad15a5ee3caddc3f4ff0db33a14454a5a3eb503d7fa1c1e35feafc579de486` | `lmstudio-community`, quantizer bartowski; base `Qwen/Qwen3-Coder-30B-A3B-Instruct` |
| Qwen3-VL-8B | `Qwen3VL-8B-Instruct-Q4_K_M.gguf` | 5,027,784,800 | `67d1659bfe71b89d50b45a4ad1a9e5b997e5bb16ce5da66a6a6167abd569e9e2` | официальный `Qwen/Qwen3-VL-8B-Instruct-GGUF` |
| Qwen3-VL mmproj | `mmproj-Qwen3VL-8B-Instruct-Q8_0.gguf` | 752,289,728 | `c6ba85508d82f42590e6eb77d5340369ab6fecf107a7561d809523d8aa5f3bfd` | официальный `Qwen/Qwen3-VL-8B-Instruct-GGUF` |
| SDXL Base 1.0 | `sd_xl_base_1.0.safetensors` | 6,938,078,334 | `31e35c80fc4829d14f90153f4c74cd59c90b779f6afe05a74cd6120b893f7e5b` | `stabilityai/stable-diffusion-xl-base-1.0` |
| Whisper | `turbo` CTranslate2 cache | зафиксирован локальным manifest | зафиксирован локальным manifest | faster-whisper 1.2.1 automatic model mapping |
| SAM 2.1 | `sam2.1_hiera_small.pt` | 184,416,285 | `6d1aa6f30de5c92224f8172114de081d104bbd23dd9dc5c58996f0cad5dc4d38` | официальный `facebook/sam2.1-hiera-small` |

Все GGUF и SDXL-файлы принимаются только после совпадения ожидаемых размера и
SHA256. Локальный manifest расположен рядом с каждым файлом. Лицензии базовых
Qwen и SAM 2 — Apache-2.0; для SDXL сохранена ссылка на CreativeML Open RAIL++-M.

Зафиксированные версии кода:

- llama.cpp `b10210`, commit prefix `0005475`;
- ComfyUI `v0.29.2`, commit prefix `3221224`;
- faster-whisper `1.2.1`;
- SAM 2 commit `2b90b9f5ceec907a1c18123530e92e794ad901a4`;
- ComfyUI-Manager `2b40deba7d04afeee29ee70c88f6c336e43dc9ca`;
- VideoHelperSuite `4ee72c065db22c9d96c2427954dc69e7b908444b`;
- ComfyUI-segment-anything-2 `0c35fff5f382803e2310103357b5e985f5437f32`;
- ComfyUI-Frame-Interpolation `26545cc2dd95bc3d27f056016300673bdeee78f5`;
- comfyui_controlnet_aux `e8b689a513c3e6b63edc44066560ca5919c0576e`;
- ComfyUI-WanVideoWrapper `088128b224242e110d3906c6750e9a3a348a659b`.

Политика установки и лицензии custom nodes приведены в `docs/custom-nodes.md`.
