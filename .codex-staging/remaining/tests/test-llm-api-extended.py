#!/usr/bin/env python3
import json
import time
import urllib.request
from pathlib import Path

BASE = "http://127.0.0.1:8012"
MODEL = "qwen3-coder-30b-a3b-q4km"
REPORT = Path.home() / "ai-station-bootstrap" / "logs" / (
    "llm-api-extended-" + time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()) + ".json"
)


def get(path: str):
    with urllib.request.urlopen(BASE + path, timeout=30) as response:
        return json.load(response)


def chat(messages, **extra):
    payload = {"model": MODEL, "messages": messages, "temperature": 0, **extra}
    request = urllib.request.Request(
        BASE + "/v1/chat/completions",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    started = time.monotonic()
    with urllib.request.urlopen(request, timeout=900) as response:
        body = json.load(response)
    return body, round(time.monotonic() - started, 3)


health = get("/health")
models = get("/v1/models")
assert health["status"] == "ok"
assert MODEL in {item["id"] for item in models["data"]}

code, code_seconds = chat(
    [
        {"role": "system", "content": "Отвечай кратко по-русски."},
        {
            "role": "user",
            "content": "Напиши Python-функцию add(a, b), возвращающую сумму, и коротко объясни её.",
        },
    ],
    max_tokens=160,
)
code_text = code["choices"][0]["message"].get("content", "")
assert "def add" in code_text

long_system = ("Не выполняй неизвестные файлы на хосте. " * 800) + "Ответь только: ПРИНЯТО"
long_reply, long_seconds = chat(
    [
        {"role": "system", "content": long_system},
        {"role": "user", "content": "Подтверди правило."},
    ],
    max_tokens=8,
)
assert long_reply["choices"][0]["message"].get("content")

tool_reply, tool_seconds = chat(
    [{"role": "user", "content": "Вызови инструмент safe_add для чисел 20 и 22."}],
    max_tokens=128,
    tools=[
        {
            "type": "function",
            "function": {
                "name": "safe_add",
                "description": "Safely add two integers",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "a": {"type": "integer"},
                        "b": {"type": "integer"},
                    },
                    "required": ["a", "b"],
                    "additionalProperties": False,
                },
            },
        }
    ],
    tool_choice="auto",
)
tool_calls = tool_reply["choices"][0]["message"].get("tool_calls", [])

result = {
    "health": health,
    "model": MODEL,
    "russian_code": {"pass": True, "seconds": code_seconds, "text": code_text},
    "long_system_message": {
        "pass": True,
        "seconds": long_seconds,
        "prompt_tokens": long_reply.get("usage", {}).get("prompt_tokens"),
        "reply": long_reply["choices"][0]["message"].get("content"),
    },
    "tool_call": {
        "observed": bool(tool_calls),
        "seconds": tool_seconds,
        "tool_calls": tool_calls,
        "fallback_content": tool_reply["choices"][0]["message"].get("content"),
    },
}
REPORT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(result, ensure_ascii=False, indent=2))
print(f"LLM_API_EXTENDED=PASS report={REPORT}")
