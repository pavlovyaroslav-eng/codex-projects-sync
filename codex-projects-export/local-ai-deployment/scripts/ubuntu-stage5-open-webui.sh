#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${1:-user}"
CONTROLLER_CIDR="${CONTROLLER_CIDR:-192.168.1.41/32}"
OPEN_WEBUI_VERSION="0.9.5"
VENV="/opt/local-ai/venvs/open-webui-${OPEN_WEBUI_VERSION}"
DATA_ROOT="/srv/local-ai/open-webui"
SERVICE_FILE="/etc/systemd/system/local-ai-open-webui.service"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0750 \
  "${DATA_ROOT}/data" "${DATA_ROOT}/cache/huggingface"
chown "${TARGET_USER}:${TARGET_USER}" "${DATA_ROOT}"
install -d -o "${TARGET_USER}" -g "${TARGET_USER}" -m 0755 \
  /opt/local-ai/venvs

if [[ ! -x "${VENV}/bin/python" ]]; then
  runuser -u "${TARGET_USER}" -- python3 -m venv "${VENV}"
fi
runuser -u "${TARGET_USER}" -- "${VENV}/bin/python" -m pip install --upgrade pip setuptools wheel
runuser -u "${TARGET_USER}" -- "${VENV}/bin/python" -m pip install --no-cache-dir \
  "open-webui==${OPEN_WEBUI_VERSION}"

cat >"${SERVICE_FILE}" <<EOF
[Unit]
Description=Local AI Open WebUI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${TARGET_USER}
Group=${TARGET_USER}
WorkingDirectory=${DATA_ROOT}
Environment=HOME=/home/${TARGET_USER}
Environment=DATA_DIR=${DATA_ROOT}/data
Environment=HF_HOME=${DATA_ROOT}/cache/huggingface
Environment=WEBUI_URL=http://192.168.1.65:3000
Environment=CORS_ALLOW_ORIGIN=http://192.168.1.65:3000;http://localhost:3000
Environment=WEBUI_AUTH=False
Environment=ENABLE_SIGNUP=False
Environment=ENABLE_LOGIN_FORM=False
Environment=ENABLE_PERSISTENT_CONFIG=False
Environment=ENABLE_OLLAMA_API=False
Environment=ENABLE_OPENAI_API=True
Environment=OPENAI_API_BASE_URL=http://127.0.0.1:8080/v1
Environment=OPENAI_API_KEY=local-no-auth
Environment=ENABLE_OPENAI_API_PASSTHROUGH=False
Environment=ENABLE_PLUGINS=False
Environment=ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS=False
Environment=ENABLE_CODE_EXECUTION=False
Environment=SAFE_MODE=True
Environment=UVICORN_WORKERS=1
ExecStart=${VENV}/bin/open-webui serve --host 0.0.0.0 --port 3000
Restart=on-failure
RestartSec=5
TimeoutStopSec=60
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=read-only
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

ufw allow from "${CONTROLLER_CIDR}" to any port 3000 proto tcp \
  comment "local-ai Open WebUI"
systemctl daemon-reload
systemctl enable --now local-ai-open-webui.service

for _ in $(seq 1 180); do
  if curl -fsS http://127.0.0.1:3000/health >/dev/null; then
    curl -fsS http://127.0.0.1:3000/health
    echo
    echo "Open WebUI ready: http://192.168.1.65:3000"
    exit 0
  fi
  sleep 2
done

systemctl --no-pager --full status local-ai-open-webui.service >&2 || true
exit 1
