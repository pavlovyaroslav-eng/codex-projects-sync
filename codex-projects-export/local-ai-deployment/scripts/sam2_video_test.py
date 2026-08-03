#!/usr/bin/env python3
import argparse
import json
import subprocess
import time
from pathlib import Path

import numpy as np
import torch
from PIL import Image, ImageDraw
from sam2.build_sam import build_sam2_video_predictor


def run(command: list[str]) -> None:
    subprocess.run(command, check=True)


def main() -> None:
    started = time.perf_counter()
    parser = argparse.ArgumentParser(description="Synthetic SAM 2.1 tracking and FFmpeg audio-preservation test")
    parser.add_argument("--checkpoint", default="/srv/local-ai/models/sam2/sam2.1_hiera_small.pt")
    parser.add_argument("--output", default="/srv/local-ai/output/sam2-test")
    args = parser.parse_args()

    output = Path(args.output)
    generated = output / "generated"
    frames = output / "frames"
    masks = output / "masks"
    overlays = output / "overlays"
    for directory in (generated, frames, masks, overlays):
        directory.mkdir(parents=True, exist_ok=True)
        for old in directory.glob("*"):
            old.unlink()

    width = height = 512
    count = 18
    fps = 6
    for index in range(count):
        image = Image.new("RGB", (width, height), "white")
        draw = ImageDraw.Draw(image)
        center_x = 70 + index * 19
        center_y = 256 + round(35 * np.sin(index / 3))
        draw.ellipse((center_x - 46, center_y - 46, center_x + 46, center_y + 46), fill=(215, 35, 45))
        draw.rectangle((360, 70, 465, 175), fill=(30, 90, 210))
        image.save(generated / f"{index:05d}.png")

    source = output / "source-with-audio.mp4"
    run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-framerate", str(fps), "-start_number", "0", "-i", str(generated / "%05d.png"),
        "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=48000:duration=3",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", "-shortest", str(source),
    ])
    run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(source),
        "-start_number", "0", "-q:v", "2", str(frames / "%05d.jpg"),
    ])

    predictor = build_sam2_video_predictor(
        "configs/sam2.1/sam2.1_hiera_s.yaml",
        args.checkpoint,
        device="cuda",
    )
    state = predictor.init_state(video_path=str(frames))
    predictor.reset_state(state)
    points = np.array([[70, 256]], dtype=np.float32)
    labels = np.array([1], dtype=np.int32)
    with torch.inference_mode(), torch.autocast("cuda", dtype=torch.bfloat16):
        predictor.add_new_points_or_box(state, frame_idx=0, obj_id=1, points=points, labels=labels)
        propagated = {}
        for frame_idx, object_ids, mask_logits in predictor.propagate_in_video(state):
            propagated[frame_idx] = (mask_logits[0] > 0.0).cpu().numpy().squeeze()

    tracked_pixels = []
    for index in range(count):
        mask = propagated[index]
        tracked_pixels.append(int(mask.sum()))
        mask_image = Image.fromarray((mask * 255).astype(np.uint8), mode="L")
        mask_image.save(masks / f"{index:05d}.png")
        frame = Image.open(frames / f"{index:05d}.jpg").convert("RGBA")
        tint = Image.new("RGBA", frame.size, (0, 255, 90, 0))
        tint.putalpha(mask_image.point(lambda value: 110 if value else 0))
        Image.alpha_composite(frame, tint).convert("RGB").save(overlays / f"{index:05d}.png")

    final = output / "tracked-with-original-audio.mp4"
    encode = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-framerate", str(fps), "-start_number", "0", "-i", str(overlays / "%05d.png"),
        "-i", str(source), "-map", "0:v:0", "-map", "1:a:0", "-shortest",
        "-c:v", "h264_nvenc", "-preset", "p4", "-cq", "23", "-c:a", "copy", str(final),
    ]
    try:
        run(encode)
        encoder = "h264_nvenc"
    except subprocess.CalledProcessError:
        encode[encode.index("h264_nvenc")] = "libx264"
        run(encode)
        encoder = "libx264"

    probe = subprocess.check_output([
        "ffprobe", "-v", "error", "-show_entries", "stream=codec_type,codec_name",
        "-of", "json", str(final),
    ], text=True)
    result = {
        "status": "ok",
        "frames": count,
        "resolution": f"{width}x{height}",
        "tracked_pixel_min": min(tracked_pixels),
        "tracked_pixel_max": max(tracked_pixels),
        "encoder": encoder,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "torch_peak_allocated_mib": round(torch.cuda.max_memory_allocated() / 1024 / 1024),
        "gpu_temperature_c": int(subprocess.check_output([
            "nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits"
        ], text=True).strip()),
        "output": str(final),
        "streams": json.loads(probe)["streams"],
    }
    (output / "result.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
