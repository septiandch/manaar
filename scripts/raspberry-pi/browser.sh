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
# Apply resolution in the desktop session before the browser opens.
if [[ -x /usr/local/bin/manar-display ]]; then
  /usr/local/bin/manar-display || echo 'Display setup failed; opening Chromium with the current resolution.'
fi
# Use the compositor's current output size/scale instead of an XWayland screen.
platform_args=()
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  platform_args+=(--ozone-platform=wayland)
fi
# This dedicated display profile uses no system keyring. Do not save passwords in it.
# Maximize as a fallback if the desktop does not honor the fullscreen request.
# F11 exits fullscreen; Alt+F4 closes the browser.
exec chromium "${platform_args[@]}" --window-size=1920,1080 --disable-background-mode --new-window --start-maximized --start-fullscreen --no-first-run \
  --password-store=basic \
  --hide-crash-restore-bubble \
  --autoplay-policy=no-user-gesture-required \
  --user-data-dir="$HOME/.config/manar-browser" http://localhost:5000/
