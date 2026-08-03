#!/usr/bin/env bash
set -Eeuo pipefail

readonly VERSION="0.2.3"
readonly PYGHIDRA_VERSION="3.1.0"
readonly VENV="/opt/ai-stack/venvs/pyghidra-mcp"
readonly EMBEDDING_URL="https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz"
readonly EMBEDDING_SHA256="913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3"
readonly REPO="${HOME}/ai-station-bootstrap"
readonly UNIT_SRC="$REPO/services/pyghidra-mcp.service"
readonly UNIT_DST="/etc/systemd/system/pyghidra-mcp.service"
mkdir -p "$REPO/logs"
readonly LOG_FILE="$REPO/logs/75-install-ghidra-mcp-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR

if [[ "${1:-}" != "--apply" ]]; then
  printf 'PLAN: install pyghidra-mcp %s and PyGhidra %s in %s; bind only 127.0.0.1:8000.\n' "$VERSION" "$PYGHIDRA_VERSION" "$VENV"
  exit 0
fi

test -x /opt/ghidra/current/support/analyzeHeadless
java -version 2>&1 | grep -q 'version "21\.'
python3 -c 'import sys; assert sys.version_info >= (3, 10)'

if ! id ghidramcp >/dev/null 2>&1; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  identity_backup="/srv/local-ai/backups/ai-station-bootstrap-${stamp}/pre-ghidramcp-identity.tar.gz"
  sudo install -d -o root -g root -m 0700 "$(dirname "$identity_backup")"
  sudo tar -C / -czf "$identity_backup" etc/passwd etc/group etc/shadow etc/gshadow
  sudo useradd --system --home-dir /var/lib/ghidramcp --create-home --shell /usr/sbin/nologin ghidramcp
  echo "Identity backup: $identity_backup"
fi
if ! getent group ai-analysis >/dev/null; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  group_backup="/srv/local-ai/backups/ai-station-bootstrap-${stamp}/pre-ai-analysis-group.tar.gz"
  sudo install -d -o root -g root -m 0700 "$(dirname "$group_backup")"
  sudo tar -C / -czf "$group_backup" etc/passwd etc/group etc/shadow etc/gshadow
  sudo groupadd --system ai-analysis
  echo "Group identity backup: $group_backup"
fi
sudo usermod -aG ai-analysis user
sudo usermod -aG ai-analysis ghidramcp
sudo install -d -o ghidramcp -g ai-analysis -m 0710 /var/lib/ghidramcp
sudo install -d -o ghidramcp -g ghidramcp -m 0700 /var/lib/ghidramcp/projects
sudo install -d -o ghidramcp -g ai-analysis -m 2770 /var/lib/ghidramcp/incoming
sudo install -o root -g root -m 0755 "$REPO/configs/bin/ai-ghidra-stage" /usr/local/bin/ai-ghidra-stage

if [[ ! -x "$VENV/bin/python" ]]; then
  sudo python3 -m venv "$VENV"
fi
sudo "$VENV/bin/python" -m pip install --disable-pip-version-check --upgrade 'pip==26.0.1'
sudo "$VENV/bin/python" -m pip install --disable-pip-version-check "pyghidra-mcp==${VERSION}" "pyghidra==${PYGHIDRA_VERSION}" 'pyghidra-mcp-cli==0.2.3'
sudo "$VENV/bin/python" -m pip install --disable-pip-version-check 'mcp[cli]==1.29.0'
sudo "$VENV/bin/python" -m pip freeze | sudo tee "$VENV/requirements.lock" >/dev/null
sudo chown -R root:root "$VENV"

embedding_cache="/var/lib/ghidramcp/.cache/chroma/onnx_models/all-MiniLM-L6-v2"
cached_embedding="$REPO/.downloads/chroma-all-MiniLM-L6-v2-onnx.tar.gz"
mkdir -p "$REPO/.downloads"
if [[ ! -f "$cached_embedding" ]] || ! printf '%s  %s\n' "$EMBEDDING_SHA256" "$cached_embedding" | sha256sum --check --strict; then
  curl --fail --location --retry 5 --output "${cached_embedding}.part" "$EMBEDDING_URL"
  printf '%s  %s\n' "$EMBEDDING_SHA256" "${cached_embedding}.part" | sha256sum --check --strict
  mv "${cached_embedding}.part" "$cached_embedding"
fi
sudo install -d -o ghidramcp -g ghidramcp -m 0700 "$embedding_cache"
sudo install -o ghidramcp -g ghidramcp -m 0600 "$cached_embedding" "$embedding_cache/onnx.tar.gz"

GHIDRA_INSTALL_DIR=/opt/ghidra/current JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
  "$VENV/bin/python" -c 'import importlib.metadata as m; import pyghidra; assert m.version("pyghidra-mcp") == "0.2.3"; assert m.version("pyghidra") == "3.1.0"; print("pyghidra compatibility import: OK")'
"$VENV/bin/pyghidra-mcp" --version
systemd-analyze verify "$UNIT_SRC"

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="/srv/local-ai/backups/ai-station-bootstrap-${stamp}"
sudo install -d -o root -g root -m 0700 "$backup_dir"
if [[ -e "$UNIT_DST" || -L "$UNIT_DST" ]]; then
  sudo cp -a "$UNIT_DST" "$backup_dir/pyghidra-mcp.service"
  sudo sha256sum "$backup_dir/pyghidra-mcp.service" | sudo tee "$backup_dir/pyghidra-mcp.service.sha256" >/dev/null
fi
sudo install -o root -g root -m 0644 "$UNIT_SRC" "$UNIT_DST"
sudo systemctl daemon-reload
sudo systemctl enable pyghidra-mcp.service
sudo systemctl restart pyghidra-mcp.service

for _ in {1..60}; do
  if ss -ltnH 'sport = :8000' | grep -Fq '127.0.0.1:8000'; then
    break
  fi
  sleep 2
done
systemctl is-active --quiet pyghidra-mcp.service
ss -ltnH 'sport = :8000' | grep -F '127.0.0.1:8000'
if ss -ltnH 'sport = :8000' | grep -Fq '0.0.0.0:8000'; then
  echo "Unsafe wildcard MCP bind detected" >&2
  exit 1
fi

qwen_backup="$backup_dir/qwen-settings.json"
sudo cp -a "$HOME/.qwen/settings.json" "$qwen_backup"
sudo sha256sum "$qwen_backup" | sudo tee "$qwen_backup.sha256" >/dev/null
if ! jq -e '.mcpServers.ghidra' "$HOME/.qwen/settings.json" >/dev/null; then
  /opt/ai-stack/bin/qwen mcp add --scope user --transport http --timeout 300000 \
    --description 'Local headless Ghidra analysis server' ghidra http://127.0.0.1:8000/mcp
fi
jq -e '.mcpServers.ghidra.httpUrl == "http://127.0.0.1:8000/mcp"' "$HOME/.qwen/settings.json" >/dev/null
echo "pyghidra-mcp ${VERSION} is active on localhost only."
