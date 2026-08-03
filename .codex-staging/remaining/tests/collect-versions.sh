#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; printf "collect-versions: error line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit "$rc"' ERR

export PATH="/opt/ai-stack/bin:/opt/ai-stack/tools/rizin/bin:/opt/ai-stack/tools/jadx/bin:${HOME}/.dotnet/tools:${PATH}"

/opt/ai-stack/bin/llama-server --version
/opt/ai-stack/bin/qwen --version
grep -E '^(application.name|application.version|application.release.name)=' \
  /opt/ghidra/current/Ghidra/application.properties
/opt/ai-stack/venvs/pyghidra-mcp/bin/python - <<'PY'
import importlib.metadata as m
for package in ("pyghidra-mcp", "pyghidra", "ghidrecomp", "mcp"):
    print(f"{package}={m.version(package)}")
PY
podman --version
virsh --version
qemu-system-x86_64 --version | sed -n '1p'
binwalk --help | sed -n '1p'
rizin -v | sed -n '1p'
capa --version
jadx --version
apktool --version
dotnet --version
ilspycmd --version | sed -n '1,2p'
/opt/ai-stack/venvs/analysis-tools/bin/python - <<'PY'
import importlib.metadata as m
for package in ("pefile", "lief", "capstone", "unicorn", "yara-python", "python-magic"):
    print(f"{package}={m.version(package)}")
PY
