#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

ROOT = Path("/opt/hometele-ai")
SECRET_NAME = re.compile(r"(token|secret|password|passwd|api.?key|credential|authorization|cookie)", re.I)
RELEVANT = re.compile(r"(deepseek|openai|base.?url|api.?url|model|chat/completions|requests\.|httpx|aiohttp|matrix|command|prefix)", re.I)


def redact_line(line: str) -> str:
    if SECRET_NAME.search(line):
        match = re.match(r"(\s*[A-Za-z_][A-Za-z0-9_]*\s*=).*", line)
        if match:
            return match.group(1) + " <redacted>"
        return "<redacted secret-bearing line>"
    line = re.sub(r"Bearer\s+[^\s'\"]+", "Bearer <redacted>", line, flags=re.I)
    line = re.sub(r"(https?://)[^/@\s]+:[^/@\s]+@", r"\1<redacted>@", line)
    return line


print("== unit properties ==")
subprocess.run(
    [
        "systemctl",
        "show",
        "hometele-ai.service",
        "--property=FragmentPath,User,Group,WorkingDirectory,ExecStart,EnvironmentFiles,ActiveState,UnitFileState",
        "--no-pager",
    ],
    check=False,
)

print("== files ==")
if ROOT.is_dir():
    for path in sorted(ROOT.rglob("*")):
        if path.is_file() and len(path.relative_to(ROOT).parts) <= 2:
            st = path.stat()
            print(f"{path.relative_to(ROOT)} mode={oct(st.st_mode & 0o777)} bytes={st.st_size}")

print("== relevant sanitized configuration/code ==")
for path in sorted(ROOT.rglob("*")) if ROOT.is_dir() else []:
    if not path.is_file() or path.suffix.lower() not in {".py", ".conf", ".ini", ".toml", ".yaml", ".yml", ".json", ".env"}:
        continue
    if "venv" in path.parts:
        continue
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        continue
    matches = [(n, redact_line(line)) for n, line in enumerate(lines, 1) if RELEVANT.search(line)]
    if matches:
        print(f"-- {path} --")
        for number, line in matches:
            print(f"{number}: {line}")

print("== service journal tail (sanitized) ==")
result = subprocess.run(
    ["journalctl", "-u", "hometele-ai.service", "-n", "80", "--no-pager", "-o", "cat"],
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
for line in result.stdout.splitlines():
    print(redact_line(line))
