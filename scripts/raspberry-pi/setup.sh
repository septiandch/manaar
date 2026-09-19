#!/usr/bin/env bash
set -Eeuo pipefail
# Include administration commands such as useradd, runuser, and nginx.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[[ $EUID == 0 ]] || { echo 'Run with sudo bash scripts/raspberry-pi/setup.sh' >&2; exit 1; }
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
kiosk_user=${SUDO_USER:-}
[[ -n $kiosk_user && $kiosk_user != root ]] || { echo 'Run through sudo from your desktop user.' >&2; exit 1; }
[[ $(uname -m) == aarch64 ]] || { echo 'Requires 64-bit Raspberry Pi OS.' >&2; exit 1; }
command -v raspi-config >/dev/null
[[ -d /etc/lightdm ]] || { echo 'Requires Raspberry Pi OS Desktop (LightDM).' >&2; exit 1; }
# Avoid running old and renamed installations against the same ports.
if [[ -f /etc/nginx/conf.d/manaar.conf || -f /etc/lightdm/lightdm.conf.d/99-manaar.conf ]]; then
  echo 'Existing Manaar installation: follow the migration section in scripts/raspberry-pi/README.md before setup.' >&2
  exit 1
fi
apt-get update
apt-get install -y git curl ca-certificates xz-utils build-essential python3 nginx chromium labwc wlr-randr
# Install the latest Node 22 binary from nodejs.org, verified against its checksum.
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
curl -fsS https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt -o "$temp/SHASUMS256.txt"
archive=$(awk '$2 ~ /^node-v22\.[0-9]+\.[0-9]+-linux-arm64.tar.xz$/ {print $2}' "$temp/SHASUMS256.txt")
[[ -n $archive && $archive != *$'\n'* ]]
curl -fsS "https://nodejs.org/dist/latest-v22.x/$archive" -o "$temp/$archive"
(cd "$temp"; grep " $archive\$" SHASUMS256.txt | sha256sum -c -)
tar -xJf "$temp/$archive" -C /usr/local --strip-components=1
npm install --global pnpm@10
id manar >/dev/null 2>&1 || useradd --system --create-home --home-dir /opt/manar --shell /usr/sbin/nologin manar
install -d -o manar -g manar /opt/manar/releases /opt/manar/shared/data /opt/manar/shared/static/uploads
chown manar:manar /opt/manar
chmod 755 /opt/manar /opt/manar/shared /opt/manar/shared/static /opt/manar/shared/static/uploads
install -m 755 "$source_dir/update.sh" /usr/local/bin/manar-update
install -m 755 "$source_dir/kiosk.sh" /usr/local/bin/manar-kiosk
if [[ ! -f /etc/manar.conf ]]; then
  cat > /etc/manar.conf <<'EOF'
REPOSITORY=https://github.com/septiandch/manar.git
# Empty means the default branch recorded when the repository is first cloned.
BRANCH=
EOF
fi
cat > /etc/systemd/system/manar.service <<'EOF'
[Unit]
Description=Manar application
After=network.target
[Service]
User=manar
Group=manar
WorkingDirectory=/opt/manar/current
Environment=NODE_ENV=production HOST=127.0.0.1 PORT=3000 ORIGIN=http://localhost:5000 BODY_SIZE_LIMIT=100M
ExecStart=/usr/local/bin/node /opt/manar/current/build/index.js
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/manar-update.service <<'EOF'
[Unit]
Description=Build and deploy Manar updates
Wants=network-online.target
After=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/local/bin/manar-update
TimeoutStartSec=2h
EOF
cat > /etc/systemd/system/manar-update.timer <<'EOF'
[Unit]
Description=Check Manar Git repository daily
[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=15m
Persistent=true
[Install]
WantedBy=timers.target
EOF
cat > /etc/nginx/conf.d/manar.conf <<'EOF'
server {
    listen 127.0.0.1:5000;
    server_name localhost;
    client_max_body_size 100m;
    location /uploads/ {
        alias /opt/manar/shared/static/uploads/;
        add_header Cache-Control "no-cache";
    }
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_buffering off;
        proxy_read_timeout 24h;
    }
}
EOF
nginx -t
systemctl daemon-reload
/usr/local/bin/manar-update
systemctl enable manar.service nginx.service manar-update.timer
systemctl restart nginx.service
systemctl start manar-update.timer
# Dedicated labwc session avoids desktop display profiles overriding kiosk output.
install -d /etc/manar-labwc /usr/share/wayland-sessions /etc/lightdm/lightdm.conf.d
printf '/usr/local/bin/manar-kiosk &\n' > /etc/manar-labwc/autostart
cat > /usr/share/wayland-sessions/manar.desktop <<'EOF'
[Desktop Entry]
Name=Manar Kiosk
Exec=labwc -C /etc/manar-labwc
Type=Application
EOF
cat > /etc/lightdm/lightdm.conf.d/99-manar.conf <<EOF
[Seat:*]
autologin-user=$kiosk_user
autologin-user-timeout=0
autologin-session=manar
user-session=manar
EOF
cmdline=/boot/firmware/cmdline.txt
[[ -f $cmdline ]] || cmdline=/boot/cmdline.txt
[[ -f $cmdline ]]
[[ -f $cmdline.manar-backup ]] || cp "$cmdline" "$cmdline.manar-backup"
python3 - "$cmdline" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
tokens = [t for t in p.read_text().split() if not t.startswith(('video=HDMI-A-1:', 'video=HDMI-A-2:'))]
tokens += ['video=HDMI-A-1:1920x1080M@60D', 'video=HDMI-A-2:1920x1080M@60D']
p.write_text(' '.join(tokens) + '\n')
PY
echo 'Setup complete. Reboot with: sudo reboot'
