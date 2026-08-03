#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

BACKUP_ROOT=/srv/local-ai/backups
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
STAGING="${BACKUP_ROOT}/.staging-${STAMP}"
ARCHIVE="${BACKUP_ROOT}/local-ai-config-${STAMP}.tar.zst"
install -d -m 0700 "${BACKUP_ROOT}" "${STAGING}"
cleanup_staging() {
  case "${STAGING}" in
    /srv/local-ai/backups/.staging-*) rm -rf -- "${STAGING}" ;;
    *) echo "Refusing to remove unexpected staging path: ${STAGING}" >&2 ;;
  esac
}
trap cleanup_staging EXIT

install -d -m 0700 "${STAGING}/etc" "${STAGING}/systemd" "${STAGING}/bin" "${STAGING}/manifests"
cp -a /etc/local-ai "${STAGING}/etc/" 2>/dev/null || true
cp -a /etc/ld.so.conf.d/local-ai-llama.conf /etc/profile.d/cuda-13-2.sh "${STAGING}/etc/" 2>/dev/null || true
cp -a /etc/systemd/system/local-ai-*.service /etc/systemd/system/local-ai-*.timer "${STAGING}/systemd/" 2>/dev/null || true
cp -a /etc/systemd/system/local-ai-*.service.d "${STAGING}/systemd/" 2>/dev/null || true
cp -a /usr/local/sbin/ai-mode /usr/local/sbin/ai-model /usr/local/bin/ai-transcribe \
  /usr/local/bin/sam2-video-test /usr/local/sbin/local-ai-test-models \
  "${STAGING}/bin/" 2>/dev/null || true
find /srv/local-ai/models -maxdepth 4 -type f \( -name 'manifest.json' -o -name '*.manifest.json' -o -name '*.sha256' \) \
  -exec cp --parents '{}' "${STAGING}/manifests/" \;

DB=/srv/local-ai/open-webui/data/webui.db
if [[ -f "${DB}" ]] && command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "${DB}" ".backup '${STAGING}/open-webui.db'"
fi

dpkg-query -W -f='${binary:Package}\t${Version}\n' >"${STAGING}/packages.tsv"
nvidia-smi -q >"${STAGING}/nvidia-smi.txt"
tar --zstd -C "${STAGING}" -cf "${ARCHIVE}" .
chmod 0600 "${ARCHIVE}"
sha256sum "${ARCHIVE}" >"${ARCHIVE}.sha256"
find "${BACKUP_ROOT}" -maxdepth 1 -type f -name 'local-ai-config-*.tar.zst*' -mtime +35 -delete
echo "${ARCHIVE}"
