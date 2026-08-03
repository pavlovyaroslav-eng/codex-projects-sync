#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; printf "test-ghidra-gui: error line=%s rc=%s command=%q\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit "$rc"' ERR
log_file="${HOME}/ai-station-bootstrap/logs/70-ghidra-gui-smoke.log"
if timeout --signal=TERM 20s xvfb-run -a /opt/ghidra/current/support/launch.sh \
  fg jdk Ghidra 4G '' ghidra.GhidraRun >"$log_file" 2>&1; then
  rc=0
else
  rc=$?
fi
printf 'gui_timeout_rc=%s\n' "$rc"
if [[ "$rc" -ne 124 && "$rc" -ne 143 ]]; then
  tail -80 "$log_file"
  exit 1
fi
if grep -Eqi 'exception|fatal|error' "$log_file"; then
  tail -80 "$log_file"
  exit 1
fi
echo "Ghidra GUI remained active for the 20-second Xvfb smoke window."
