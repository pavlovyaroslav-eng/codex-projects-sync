#!/usr/bin/env bash
set -Eeuo pipefail

readonly VERSION="12.1.2"
readonly RELEASE="Ghidra_12.1.2_build"
readonly ASSET="ghidra_12.1.2_PUBLIC_20260605.zip"
readonly URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/${RELEASE}/${ASSET}"
readonly SHA256="b62e81a0390618466c019c60d8c2f796ced2509c4c1aea4a37644a77272cf99d"
readonly ROOT="/opt/ghidra/ghidra_12.1.2_PUBLIC"
readonly REPO="${HOME}/ai-station-bootstrap"
mkdir -p "$REPO/logs"
readonly LOG_FILE="$REPO/logs/70-install-ghidra-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR

if [[ "${1:-}" != "--apply" ]]; then
  printf 'PLAN: install official Ghidra %s release asset at %s\nSource: %s\nSHA-256: %s\n' "$VERSION" "$ROOT" "$URL" "$SHA256"
  exit 0
fi

java -version 2>&1 | grep -q 'version "21\.'
if [[ -x "$ROOT/ghidraRun" ]]; then
  grep -Fqx "application.version=${VERSION}" "$ROOT/Ghidra/application.properties"
  echo "Ghidra ${VERSION} is already installed."
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rc=$?; rm -rf -- "$work_dir"; if (( rc != 0 )); then printf "FAILED rc=%s\n" "$rc"; fi; exit "$rc"' EXIT
archive="$work_dir/$ASSET"
cached_archive="$REPO/.downloads/$ASSET"
if [[ -f "$cached_archive" ]] && printf '%s  %s\n' "$SHA256" "$cached_archive" | sha256sum --check --strict; then
  cp --reflink=auto "$cached_archive" "$archive"
else
  curl --fail --location --retry 5 --continue-at - --output "$archive" "$URL"
fi
printf '%s  %s\n' "$SHA256" "$archive" | sha256sum --check --strict
if unzip -Z1 "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
  echo "Unsafe path found in Ghidra archive" >&2
  exit 1
fi
unzip -q "$archive" -d "$work_dir"
test -x "$work_dir/ghidra_12.1.2_PUBLIC/ghidraRun"
grep -Fqx "application.version=${VERSION}" "$work_dir/ghidra_12.1.2_PUBLIC/Ghidra/application.properties"

sudo install -d -o root -g root -m 0755 /opt/ghidra
sudo cp -a "$work_dir/ghidra_12.1.2_PUBLIC" "$ROOT"
sudo chown -R root:root "$ROOT"
sudo ln -sfn "$ROOT" /opt/ghidra/current
sudo install -o root -g root -m 0755 "$REPO/configs/bin/ghidra" /usr/local/bin/ghidra
sudo install -o root -g root -m 0755 "$REPO/configs/bin/ghidra-headless" /usr/local/bin/ghidra-headless
sudo install -o root -g root -m 0644 "$REPO/configs/ghidra/ghidra.desktop" /usr/share/applications/ghidra.desktop
grep -Fqx "application.version=${VERSION}" /opt/ghidra/current/Ghidra/application.properties
echo "Installed Ghidra ${VERSION}."
