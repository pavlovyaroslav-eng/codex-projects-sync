#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

import requests


def stamp(seconds: float, srt: bool = False) -> str:
    value = max(0, round(seconds * 1000))
    hours, value = divmod(value, 3_600_000)
    minutes, value = divmod(value, 60_000)
    secs, value = divmod(value, 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d}{',' if srt else '.'}{value:03d}"


def main() -> None:
    parser = argparse.ArgumentParser(description="Transcribe one media file and write TXT/SRT/VTT/JSON")
    parser.add_argument("file", type=Path)
    parser.add_argument("--language", default="")
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--server", default="http://127.0.0.1:8000")
    args = parser.parse_args()

    source = args.file.expanduser().resolve()
    output = (args.output_dir or source.parent).expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    with source.open("rb") as handle:
        response = requests.post(
            f"{args.server.rstrip('/')}/v1/audio/transcriptions",
            files={"file": (source.name, handle)},
            data={"model": "turbo", "language": args.language, "response_format": "verbose_json"},
            timeout=None,
        )
    response.raise_for_status()
    data = response.json()
    base = output / source.stem
    base.with_suffix(".txt").write_text(data["text"] + "\n", encoding="utf-8")
    base.with_suffix(".json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    srt = []
    vtt = ["WEBVTT"]
    for index, segment in enumerate(data["segments"], 1):
        text = segment["text"].strip()
        srt.append(f"{index}\n{stamp(segment['start'], True)} --> {stamp(segment['end'], True)}\n{text}")
        vtt.append(f"{stamp(segment['start'])} --> {stamp(segment['end'])}\n{text}")
    base.with_suffix(".srt").write_text("\n\n".join(srt) + "\n", encoding="utf-8")
    base.with_suffix(".vtt").write_text("\n\n".join(vtt) + "\n", encoding="utf-8")
    print(f"Created: {base}.txt/.srt/.vtt/.json")


if __name__ == "__main__":
    main()

