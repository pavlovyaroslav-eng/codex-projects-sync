#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_ROOT=/srv/local-ai/backups
case "${1:-list}" in
  list)
    find "${BACKUP_ROOT}" -maxdepth 1 -type f -name 'local-ai-config-*.tar.zst' -printf '%TY-%Tm-%Td %TH:%TM  %p\n' | sort -r
    ;;
  qwen14)
    if [[ ${EUID} -ne 0 ]]; then echo "Run with sudo." >&2; exit 1; fi
    /usr/local/sbin/ai-model start qwen14
    ;;
  inspect)
    archive="${2:-}"
    [[ -f "${archive}" ]] || { echo "Archive not found." >&2; exit 2; }
    [[ "${archive}" == "${BACKUP_ROOT}"/local-ai-config-*.tar.zst ]] || {
      echo "Refusing archive outside ${BACKUP_ROOT}." >&2; exit 2;
    }
    sha256sum -c "${archive}.sha256"
    tar --zstd -tf "${archive}"
    echo "Inspection only; no live files were changed. Follow docs/recovery.md for selective restore."
    ;;
  *)
    echo "Usage: rollback.sh {list|qwen14|inspect /srv/local-ai/backups/ARCHIVE.tar.zst}" >&2
    exit 2
    ;;
esac

