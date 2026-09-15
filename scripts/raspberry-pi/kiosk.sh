#!/usr/bin/env bash
set -Eeuo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin
exec 9>"$XDG_RUNTIME_DIR/manaar-kiosk.lock"
flock -n 9 || exit 0
browser=
display_loop=
cleanup() {
  [[ -z $browser ]] || kill "$browser" 2>/dev/null || true
  [[ -z $display_loop ]] || kill "$display_loop" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT
# Reapply on hotplug and override modes advertised by the monitor.
(
  while true; do
    for output in $(wlr-randr | awk '/^[^ ]/ {print $1}'); do
      wlr-randr --output "$output" --on --custom-mode 1920x1080@60Hz --scale 1 --transform normal || true
    done
    sleep 10
  done
) &
display_loop=$!
while true; do
  until curl --fail --silent --max-time 2 http://localhost:5000/ >/dev/null; do sleep 2; done
  version=$(cat /opt/manaar/shared/version 2>/dev/null || true)
  chromium --ozone-platform=wayland --kiosk --noerrdialogs --no-first-run \
    --disable-session-crashed-bubble --autoplay-policy=no-user-gesture-required \
    --force-device-scale-factor=1 --window-size=1920,1080 \
    --user-data-dir="$HOME/.config/manaar-chromium" http://localhost:5000/ &
  browser=$!
  while kill -0 "$browser" 2>/dev/null; do
    sleep 5
    if [[ $(cat /opt/manaar/shared/version 2>/dev/null || true) != "$version" ]]; then
      kill "$browser" 2>/dev/null || true
      break
    fi
  done
  wait "$browser" || true
  browser=
  sleep 2
done
