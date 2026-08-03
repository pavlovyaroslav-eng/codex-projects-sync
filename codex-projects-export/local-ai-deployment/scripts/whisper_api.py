#!/usr/bin/env python3
import json
import os
import shutil
import threading
import uuid
from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse, Response
from faster_whisper import WhisperModel

MODEL_NAME = os.getenv("WHISPER_MODEL", "turbo")
COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8_float16")
MODEL_ROOT = Path(os.getenv("WHISPER_MODEL_ROOT", "/srv/local-ai/models/whisper"))
INPUT_ROOT = Path(os.getenv("WHISPER_INPUT_ROOT", "/srv/local-ai/input/whisper"))
MAX_UPLOAD_BYTES = int(os.getenv("WHISPER_MAX_UPLOAD_BYTES", str(512 * 1024 * 1024)))

app = FastAPI(title="Local AI Whisper", version="1.0")
_model = None
_model_lock = threading.Lock()
_inference_lock = threading.Lock()


def get_model() -> WhisperModel:
    global _model
    with _model_lock:
        if _model is None:
            MODEL_ROOT.mkdir(parents=True, exist_ok=True)
            _model = WhisperModel(
                MODEL_NAME,
                device="cuda",
                compute_type=COMPUTE_TYPE,
                download_root=str(MODEL_ROOT),
            )
    return _model


def stamp(seconds: float, srt: bool = False) -> str:
    milliseconds = max(0, round(seconds * 1000))
    hours, milliseconds = divmod(milliseconds, 3_600_000)
    minutes, milliseconds = divmod(milliseconds, 60_000)
    secs, milliseconds = divmod(milliseconds, 1000)
    separator = "," if srt else "."
    return f"{hours:02d}:{minutes:02d}:{secs:02d}{separator}{milliseconds:03d}"


def render_srt(segments: list[dict]) -> str:
    blocks = []
    for index, segment in enumerate(segments, 1):
        blocks.append(
            f"{index}\n{stamp(segment['start'], True)} --> {stamp(segment['end'], True)}\n"
            f"{segment['text'].strip()}"
        )
    return "\n\n".join(blocks) + "\n"


def render_vtt(segments: list[dict]) -> str:
    blocks = ["WEBVTT"]
    for segment in segments:
        blocks.append(
            f"{stamp(segment['start'])} --> {stamp(segment['end'])}\n{segment['text'].strip()}"
        )
    return "\n\n".join(blocks) + "\n"


def transcribe(path: Path, language: str | None, prompt: str | None) -> dict:
    with _inference_lock:
        segments_iter, info = get_model().transcribe(
            str(path),
            language=language or None,
            initial_prompt=prompt or None,
            beam_size=5,
            vad_filter=True,
            word_timestamps=True,
        )
        segments = []
        for segment in segments_iter:
            segments.append(
                {
                    "id": segment.id,
                    "start": segment.start,
                    "end": segment.end,
                    "text": segment.text,
                    "words": [
                        {
                            "start": word.start,
                            "end": word.end,
                            "word": word.word,
                            "probability": word.probability,
                        }
                        for word in (segment.words or [])
                    ],
                }
            )
    return {
        "task": "transcribe",
        "language": info.language,
        "duration": info.duration,
        "language_probability": info.language_probability,
        "text": "".join(item["text"] for item in segments).strip(),
        "segments": segments,
    }


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return """<!doctype html><meta charset="utf-8"><title>Local AI Whisper</title>
<style>body{font:16px system-ui;max-width:760px;margin:48px auto;padding:0 20px}input,select,button{font:inherit;margin:8px 0;padding:8px}button{cursor:pointer}</style>
<h1>Local AI Whisper</h1><p>Файлы: WAV, MP3, M4A, MP4. Лимит 512 МБ.</p>
<form action="/v1/audio/transcriptions" method="post" enctype="multipart/form-data">
<input type="hidden" name="model" value="turbo"><input type="hidden" name="response_format" value="text">
<p><input type="file" name="file" required></p><p>Язык: <input name="language" placeholder="ru / en / auto"></p>
<button type="submit">Распознать</button></form>"""


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "model": MODEL_NAME, "loaded": _model is not None}


@app.get("/v1/models")
def models() -> dict:
    return {"object": "list", "data": [{"id": MODEL_NAME, "object": "model", "owned_by": "local-ai"}]}


@app.post("/v1/audio/transcriptions")
async def audio_transcriptions(
    file: Annotated[UploadFile, File()],
    model: Annotated[str, Form()] = "turbo",
    language: Annotated[str | None, Form()] = None,
    prompt: Annotated[str | None, Form()] = None,
    response_format: Annotated[str, Form()] = "json",
) -> Response:
    if model not in {"turbo", MODEL_NAME, "whisper-1"}:
        raise HTTPException(status_code=400, detail=f"Unknown model: {model}")
    if response_format not in {"json", "verbose_json", "text", "srt", "vtt"}:
        raise HTTPException(status_code=400, detail="Unsupported response_format")

    INPUT_ROOT.mkdir(parents=True, exist_ok=True)
    suffix = Path(file.filename or "audio.bin").suffix[:16]
    temporary = INPUT_ROOT / f"upload-{uuid.uuid4().hex}{suffix}"
    written = 0
    try:
        with temporary.open("wb") as destination:
            while chunk := await file.read(8 * 1024 * 1024):
                written += len(chunk)
                if written > MAX_UPLOAD_BYTES:
                    raise HTTPException(status_code=413, detail="File exceeds upload limit")
                destination.write(chunk)
        result = transcribe(temporary, language, prompt)
    finally:
        await file.close()
        temporary.unlink(missing_ok=True)

    if response_format == "text":
        return PlainTextResponse(result["text"] + "\n")
    if response_format == "srt":
        return PlainTextResponse(render_srt(result["segments"]), media_type="application/x-subrip")
    if response_format == "vtt":
        return PlainTextResponse(render_vtt(result["segments"]), media_type="text/vtt")
    if response_format == "json":
        return JSONResponse({"text": result["text"]})
    return JSONResponse(result)

