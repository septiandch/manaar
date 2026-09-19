#!/usr/bin/env bash
set -Eeuo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
log_dir=${XDG_STATE_HOME:-$HOME/.local/state}/manar
mkdir -p "$log_dir"
exec >>"$log_dir/browser.log" 2>&1
printf '\nStarting Manar browser: %s\n' "$(date -Is)"
: "${XDG_RUNTIME_DIR:?Run inside the desktop session}"
exec 9>"$XDG_RUNTIME_DIR/manar-browser.lock"
flock -n 9 || exit 0
until curl --fail --silent --max-time 2 http://localhost:5000/ >/dev/null; do
  sleep 2
done
# Ordinary fullscreen window: F11 exits fullscreen, Alt+F4 closes the browser.
exec chromium --start-fullscreen --no-first-run \
  --autoplay-policy=no-user-gesture-required \
  --user-data-dir="$HOME/.config/manar-browser" http://localhost:5000/
