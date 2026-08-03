# Зафиксированные ComfyUI custom nodes

Ноды устанавливаются только из исходных GitHub-репозиториев в detached commit.
Автообновление отключено. `install.py` и другие post-install scripts не
выполняются; зависимости ставятся явными командами из
`scripts/ubuntu-stage10-comfy-nodes.sh`. Уже проверенные Torch 2.12/cu132 и
torchvision исключены из прямой установки requirements-файла ControlNet Aux.

| Нода | Commit | Назначение | Лицензия |
|---|---|---|---|
| [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) | `2b40deba7d04afeee29ee70c88f6c336e43dc9ca` | локальное управление workflow/nodes | GPL-3.0 |
| [VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) | `4ee72c065db22c9d96c2427954dc69e7b908444b` | загрузка кадров, видео и сборка | GPL-3.0 |
| [ComfyUI SAM 2](https://github.com/kijai/ComfyUI-segment-anything-2) | `0c35fff5f382803e2310103357b5e985f5437f32` | SAM 2 masks/tracking | Apache-2.0 |
| [Frame Interpolation](https://github.com/Fannovel16/ComfyUI-Frame-Interpolation) | `26545cc2dd95bc3d27f056016300673bdeee78f5` | RIFE/VFI | MIT |
| [ControlNet Aux](https://github.com/Fannovel16/comfyui_controlnet_aux) | `e8b689a513c3e6b63edc44066560ca5919c0576e` | preprocessors | Apache-2.0 |
| [WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper) | `088128b224242e110d3906c6750e9a3a348a659b` | image/video model integration | Apache-2.0 |

Установка wrapper не означает загрузку всех Wan weights. Тяжёлые модели не
запускаются автоматически и должны добавляться отдельно только в VRAM-safe
профиле. Рабочая проверка базового video pipeline выполняется официальным SAM
2.1 Hiera Small и FFmpeg с сохранением аудио.

Фактически установленные commits также записываются на Ubuntu в
`/srv/local-ai/models/comfyui/custom-nodes-manifest.json`.

Проверка `/object_info` после установки: 857 nodes всего, из них по группам
поиска 40 video/VHS, 5 SAM2, 14 RIFE/VFI, 51 ControlNet preprocessors и 110
WanVideo. Ошибок запуска ComfyUI не обнаружено.
