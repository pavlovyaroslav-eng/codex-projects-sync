#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO="${HOME}/ai-station-bootstrap"
readonly VENV="/opt/ai-stack/venvs/analysis-tools"
mkdir -p "$REPO/logs"
readonly LOG_FILE="$REPO/logs/80-install-analysis-tools-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rc=$?; printf "ERROR line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND"; exit "$rc"' ERR

apt_packages=(file binutils xxd hexedit gdb strace ltrace ripgrep jq p7zip-full unzip cabextract libimage-exiftool-perl yara clamav binwalk libguestfs-tools xorriso podman uidmap slirp4netns fuse-overlayfs python3-venv dotnet-sdk-10.0 xvfb shellcheck)
if [[ "${1:-}" != "--apply" ]]; then
  echo "PLAN: apt simulation for host analysis tools, rootless Podman, .NET LTS, then pinned official release assets."
  apt-get --simulate install "${apt_packages[@]}"
  exit 0
fi

sudo apt-get update
sudo apt-get install -y "${apt_packages[@]}"

if [[ ! -x "$VENV/bin/python" ]]; then
  sudo python3 -m venv "$VENV"
fi
sudo "$VENV/bin/python" -m pip install --disable-pip-version-check --upgrade 'pip==26.0.1'
sudo "$VENV/bin/python" -m pip install --disable-pip-version-check \
  'pefile==2024.8.26' 'lief==1.0.0' 'capstone==5.0.9' 'unicorn==2.1.4' \
  'yara-python==4.5.4' 'python-magic==0.4.27' 'ghidrecomp==0.5.9'
sudo "$VENV/bin/python" -m pip freeze | sudo tee "$VENV/requirements.lock" >/dev/null
sudo chown -R root:root "$VENV"

work_dir="$(mktemp -d)"
trap 'rc=$?; rm -rf -- "$work_dir"; if (( rc != 0 )); then printf "FAILED rc=%s\n" "$rc"; fi; exit "$rc"' EXIT
install_zip_release() {
  local name="$1" url="$2" sha="$3" archive="$4" root="$5"
  if [[ -e "$root" ]]; then
    echo "$name already present at $root"
    return
  fi
  curl --fail --location --retry 5 --output "$work_dir/$archive" "$url"
  printf '%s  %s\n' "$sha" "$work_dir/$archive" | sha256sum --check --strict
  mkdir "$work_dir/$name"
  unzip -q "$work_dir/$archive" -d "$work_dir/$name"
  sudo install -d -o root -g root -m 0755 "$(dirname "$root")"
  sudo cp -a "$work_dir/$name" "$root"
  sudo chown -R root:root "$root"
}

install_zip_release capa \
  https://github.com/mandiant/capa/releases/download/v9.4.0/capa-v9.4.0-linux.zip \
  07800a1d20a21eb18fc98716e2ae81b668e0c9a04defd588c8aa17ea3d3281e4 \
  capa-v9.4.0-linux.zip /opt/ai-stack/releases/capa-v9.4.0
sudo ln -sfn /opt/ai-stack/releases/capa-v9.4.0/capa /opt/ai-stack/bin/capa

if [[ ! -e /opt/ai-stack/releases/rizin-v0.9.1 ]]; then
  curl --fail --location --retry 5 --output "$work_dir/rizin.tar.xz" \
    https://github.com/rizinorg/rizin/releases/download/v0.9.1/rizin-v0.9.1-static-x86_64.tar.xz
  printf '%s  %s\n' 9102249a9f0b6319c5334a2e5cf8d9cc3f2035e1d3def027c41f6a90f647e8cf "$work_dir/rizin.tar.xz" | sha256sum --check --strict
  mkdir "$work_dir/rizin"
  tar -xJf "$work_dir/rizin.tar.xz" -C "$work_dir/rizin"
  sudo cp -a "$work_dir/rizin" /opt/ai-stack/releases/rizin-v0.9.1
  sudo chown -R root:root /opt/ai-stack/releases/rizin-v0.9.1
fi
rizin_bin="$(find /opt/ai-stack/releases/rizin-v0.9.1 -type f -name rizin -perm -u+x -print -quit)"
test -n "$rizin_bin"
sudo ln -sfn "$rizin_bin" /opt/ai-stack/bin/rizin

install_zip_release jadx \
  https://github.com/skylot/jadx/releases/download/v1.5.6/jadx-1.5.6.zip \
  545ea2be9c242511bc145755cf4bda2485ade42966e096f8b4d3da2a230e8974 \
  jadx-1.5.6.zip /opt/ai-stack/releases/jadx-v1.5.6
sudo ln -sfn /opt/ai-stack/releases/jadx-v1.5.6/bin/jadx /opt/ai-stack/bin/jadx
sudo ln -sfn /opt/ai-stack/releases/jadx-v1.5.6/bin/jadx-gui /opt/ai-stack/bin/jadx-gui

sudo install -d -o root -g root -m 0755 /opt/ai-stack/releases/apktool-v3.0.3
if [[ ! -f /opt/ai-stack/releases/apktool-v3.0.3/apktool_3.0.3.jar ]]; then
  curl --fail --location --retry 5 --output "$work_dir/apktool.jar" \
    https://github.com/iBotPeaches/Apktool/releases/download/v3.0.3/apktool_3.0.3.jar
  printf '%s  %s\n' dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423 "$work_dir/apktool.jar" | sha256sum --check --strict
  sudo install -o root -g root -m 0644 "$work_dir/apktool.jar" /opt/ai-stack/releases/apktool-v3.0.3/apktool_3.0.3.jar
fi

sudo install -o root -g root -m 0755 "$REPO/configs/bin/apktool" /opt/ai-stack/bin/apktool
sudo install -o root -g root -m 0755 "$REPO"/configs/bin/ai-ingest-file "$REPO"/configs/bin/ai-static-scan "$REPO"/configs/bin/ai-software-* /usr/local/bin/

sudo install -d -o root -g root -m 0755 /opt/ai-stack/releases/ilspycmd-v10.1.1.8388
if [[ ! -x /opt/ai-stack/releases/ilspycmd-v10.1.1.8388/ilspycmd ]]; then
  DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 sudo -E dotnet tool install ilspycmd \
    --tool-path /opt/ai-stack/releases/ilspycmd-v10.1.1.8388 --version 10.1.1.8388
fi
sudo ln -sfn /opt/ai-stack/releases/ilspycmd-v10.1.1.8388/ilspycmd /opt/ai-stack/bin/ilspycmd

podman build --pull=always --tag localhost/ai-static-tools:1.0 "$REPO/containers/ai-static-tools"

command -v podman
podman info --format '{{.Host.Security.Rootless}}'
/opt/ai-stack/bin/capa --version
/opt/ai-stack/bin/rizin -v
/opt/ai-stack/bin/jadx --version
/opt/ai-stack/bin/apktool --version
dotnet --info
/opt/ai-stack/bin/ilspycmd --version
echo "Host analysis tools installed."
