#!/usr/bin/env bash
set -Eeuo pipefail

readonly VERSION="0.21.3"
readonly ASSET="qwen-code-linux-x64.tar.gz"
readonly URL="https://github.com/QwenLM/qwen-code/releases/download/v${VERSION}/${ASSET}"
readonly SHA256="3cf9620770933926f74ba3f6e490cf7f91f2619c68dbb995ec96af20ee365f2a"
readonly ROOT="/opt/ai-stack/releases/qwen-code-v${VERSION}"
readonly REPO="${HOME}/ai-station-bootstrap"
readonly LOG_DIR="${REPO}/logs"
mkdir -p "$LOG_DIR"
readonly LOG_FILE="${LOG_DIR}/60-install-qwen-code-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR

if [[ "${1:-}" != "--apply" ]]; then
  printf 'PLAN: install official Qwen Code v%s standalone at %s\n' "$VERSION" "$ROOT"
  printf 'Source: %s\nSHA-256: %s\n' "$URL" "$SHA256"
  exit 0
fi

if [[ -x "$ROOT/bin/qwen" ]]; then
  test "$($ROOT/bin/qwen --version)" = "$VERSION"
  echo "Qwen Code v${VERSION} release is already installed."
else
  if [[ -e "$ROOT" || -L "$ROOT" ]]; then
    echo "Existing incomplete release path requires manual inspection: $ROOT" >&2
    exit 1
  fi
  work_dir="$(mktemp -d)"
  trap 'rc=$?; rm -rf -- "$work_dir"; if (( rc != 0 )); then printf "FAILED rc=%s\n" "$rc"; fi; exit "$rc"' EXIT
  archive="$work_dir/$ASSET"
  cached_archive="$REPO/.downloads/qwen-code-linux-x64-v${VERSION}.tar.gz"
  if [[ -f "$cached_archive" ]] && printf '%s  %s\n' "$SHA256" "$cached_archive" | sha256sum --check --strict; then
    cp --reflink=auto "$cached_archive" "$archive"
  else
    curl --fail --location --retry 5 --continue-at - --output "$archive" "$URL"
  fi
  printf '%s  %s\n' "$SHA256" "$archive" | sha256sum --check --strict
  if tar -tzf "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
    echo "Unsafe path found in release archive" >&2
    exit 1
  fi
  tar -xzf "$archive" -C "$work_dir"
  test -x "$work_dir/qwen-code/bin/qwen"
  test "$(jq -r .version "$work_dir/qwen-code/manifest.json")" = "$VERSION"
  sudo install -d -o root -g root -m 0755 "$(dirname "$ROOT")"
  sudo cp -a "$work_dir/qwen-code" "$ROOT"
  sudo chown -R root:root "$ROOT"
  rm -rf -- "$work_dir"
  trap - EXIT
fi
test "$($ROOT/bin/qwen --version)" = "$VERSION"

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="$REPO/backups/qwen-code-$stamp"
mkdir -m 0700 "$backup_dir"
backup_if_present() {
  local path="$1" name="$2"
  if [[ -e "$path" || -L "$path" ]]; then
    cp -a "$path" "$backup_dir/$name"
    sha256sum "$backup_dir/$name" >"$backup_dir/$name.sha256"
  fi
}

mkdir -p "$HOME/.qwen"
chmod 0700 "$HOME/.qwen"
if [[ -f "$HOME/.qwen/settings.json" ]]; then
  backup_if_present "$HOME/.qwen/settings.json" settings.json
  settings_tmp="$(mktemp "$HOME/.qwen/settings.json.XXXXXX")"
  jq -s '.[0] * .[1]' "$HOME/.qwen/settings.json" "$REPO/configs/qwen/settings.json" >"$settings_tmp"
  chmod 0600 "$settings_tmp"
  mv "$settings_tmp" "$HOME/.qwen/settings.json"
else
  install -m 0600 "$REPO/configs/qwen/settings.json" "$HOME/.qwen/settings.json"
fi
if [[ -f "$HOME/.qwen/trustedFolders.json" ]]; then
  backup_if_present "$HOME/.qwen/trustedFolders.json" trustedFolders.json
  trust_tmp="$(mktemp "$HOME/.qwen/trustedFolders.json.XXXXXX")"
  jq -s '.[0] * .[1]' "$HOME/.qwen/trustedFolders.json" "$REPO/configs/qwen/trustedFolders.json" >"$trust_tmp"
  chmod 0600 "$trust_tmp"
  mv "$trust_tmp" "$HOME/.qwen/trustedFolders.json"
else
  install -m 0600 "$REPO/configs/qwen/trustedFolders.json" "$HOME/.qwen/trustedFolders.json"
fi
for mapping in "dot-env:.env:0600" "QWEN.md:QWEN.md:0644"; do
  source_name="${mapping%%:*}"
  remainder="${mapping#*:}"
  target_name="${remainder%%:*}"
  mode="${mapping##*:}"
  backup_if_present "$HOME/.qwen/$target_name" "$target_name"
  install -m "$mode" "$REPO/configs/qwen/$source_name" "$HOME/.qwen/$target_name"
done
jq -e . "$HOME/.qwen/settings.json" "$HOME/.qwen/trustedFolders.json" >/dev/null

mkdir -p "$HOME/AI-Workbench"/{projects,static-analysis/ghidra-projects,incoming,quarantine,reports,samples-iso,vm-exports,test-project}
chmod 0750 "$HOME/AI-Workbench" "$HOME/AI-Workbench"/{projects,static-analysis,static-analysis/ghidra-projects,incoming,reports,samples-iso,vm-exports,test-project}
chmod 0700 "$HOME/AI-Workbench/quarantine"
backup_if_present "$HOME/AI-Workbench/QWEN.md" AI-Workbench-QWEN.md
install -m 0644 "$REPO/configs/qwen/project-QWEN.md" "$HOME/AI-Workbench/QWEN.md"
if [[ -d "$REPO/workbench/test-project" ]]; then
  cp -n "$REPO"/workbench/test-project/* "$HOME/AI-Workbench/test-project/"
fi

if [[ -e /opt/ai-stack/bin/qwen || -L /opt/ai-stack/bin/qwen ]]; then
  sudo cp -a /opt/ai-stack/bin/qwen "$backup_dir/opt-ai-stack-bin-qwen"
fi
sudo install -o root -g root -m 0755 "$REPO/configs/bin/qwen" /opt/ai-stack/bin/qwen
test "$(/opt/ai-stack/bin/qwen --version)" = "$VERSION"
echo "Qwen Code v${VERSION} and safe user configuration are installed. Backup: $backup_dir"
