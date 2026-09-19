#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
  echo 'Manar display: no Wayland session; keeping the desktop resolution.' >&2
  exit 0
fi
command -v wlr-randr >/dev/null || {
  echo 'Manar display: install wlr-randr to configure HDMI.' >&2
  exit 1
}

# Desktop outputs may not be ready when login autostart begins.
outputs=
for ((attempt=0; attempt<10; attempt++)); do
  if state=$(timeout 5 wlr-randr); then
    outputs=$(awk '
      /^[^[:space:]]/ { output=$1 }
      /^[[:space:]]+Enabled: yes/ && output ~ /^HDMI-/ { print output }
    ' <<< "$state")
    [[ -z $outputs ]] || break
  fi
  sleep 1
done
if [[ -z $outputs ]]; then
  echo 'Manar display: no enabled HDMI output found; keeping the desktop resolution.' >&2
  exit 1
fi

failed=0
while IFS= read -r output; do
  echo "Manar display: setting $output to 1920x1080, scale 1, landscape."
  # Prefer an advertised mode; request a custom 60 Hz mode if none is available.
  if timeout 5 wlr-randr --output "$output" --mode 1920x1080 --scale 1 --transform normal; then
    continue
  fi
  if ! timeout 5 wlr-randr --output "$output" --custom-mode 1920x1080@60Hz --scale 1 --transform normal; then
    echo "Manar display: $output rejected 1920x1080." >&2
    failed=1
  fi
done <<< "$outputs"
exit "$failed"
