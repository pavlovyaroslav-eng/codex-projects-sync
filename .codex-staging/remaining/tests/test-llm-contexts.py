#!/usr/bin/env python3
import json
import sys
import time
import urllib.request

if len(sys.argv) != 3:
    raise SystemExit("usage: test-llm-contexts.py BASE_URL APPROX_TOKENS")
base = sys.argv[1].rstrip("/")
tokens = int(sys.argv[2])
prompt = "code review token " * max(1, tokens // 3)
payload = {
    "model": "qwen3-coder-30b-a3b-q4km",
    "messages": [{"role": "user", "content": prompt + "\nReply only: OK"}],
    "temperature": 0,
    "max_tokens": 2,
}
req = urllib.request.Request(
    base + "/v1/chat/completions",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"},
)
started = time.monotonic()
with urllib.request.urlopen(req, timeout=900) as response:
    body = json.load(response)
elapsed = time.monotonic() - started
usage = body.get("usage", {})
result = {
    "requested_approx_tokens": tokens,
    "prompt_tokens": usage.get("prompt_tokens"),
    "completion_tokens": usage.get("completion_tokens"),
    "elapsed_seconds": round(elapsed, 3),
    "observed_prompt_tokens_per_second": (
        round(usage.get("prompt_tokens", 0) / elapsed, 3) if elapsed else None
    ),
    "finish_reason": body["choices"][0].get("finish_reason"),
}
print(json.dumps(result, ensure_ascii=False))
