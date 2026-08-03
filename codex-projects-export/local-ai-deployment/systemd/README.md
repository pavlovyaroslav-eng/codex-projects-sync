# systemd inventory

Canonical units are generated idempotently by the numbered Ubuntu stage scripts
so pinned paths, users and model filenames remain in one place.

| Unit | Purpose | Default |
|---|---|---|
| `local-ai-autostart.service` | selected LLM + Open WebUI at boot | enabled |
| `local-ai-llama.service` | Qwen3-14B OpenAI API | selected/on demand |
| `local-ai-coder30.service` | Qwen3-Coder-30B-A3B API | disabled, on demand |
| `local-ai-qwen-vl.service` | Qwen3-VL-8B multimodal API | disabled, on demand |
| `local-ai-open-webui.service` | Web UI for current LLM | started by model manager |
| `local-ai-comfyui.service` | SDXL/image/video UI | disabled, on demand |
| `local-ai-whisper.service` | faster-whisper API | disabled, on demand |
| `local-ai-health.timer` | read-only health report | enabled |
| `local-ai-cleanup.timer` | bounded temp cleanup | enabled |
| `local-ai-backup.timer` | config/database backup | enabled |

GPU units use `Conflicts=` and the `ai-model`/`ai-mode` frontends. Do not enable
Coder, VL, ComfyUI or Whisper simultaneously.
