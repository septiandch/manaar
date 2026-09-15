#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID == 0 ]] || { echo 'Run with sudo bash scripts/raspberry-pi/setup.sh' >&2; exit 1; }
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
kiosk_user=${SUDO_USER:-}
[[ -n $kiosk_user && $kiosk_user != root ]] || { echo 'Run through sudo from your desktop user.' >&2; exit 1; }
[[ $(uname -m) == aarch64 ]] || { echo 'Requires 64-bit Raspberry Pi OS.' >&2; exit 1; }
command -v raspi-config >/dev/null
[[ -d /etc/lightdm ]] || { echo 'Requires Raspberry Pi OS Desktop (LightDM).' >&2; exit 1; }
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
export PATH=/usr/local/bin:/usr/bin:/bin
npm install --global pnpm@10
id manaar >/dev/null 2>&1 || useradd --system --create-home --home-dir /opt/manaar --shell /usr/sbin/nologin manaar
install -d -o manaar -g manaar /opt/manaar/releases /opt/manaar/shared/data /opt/manaar/shared/static/uploads
chown manaar:manaar /opt/manaar
chmod 755 /opt/manaar /opt/manaar/shared /opt/manaar/shared/static /opt/manaar/shared/static/uploads
install -m 755 "$source_dir/update.sh" /usr/local/bin/manaar-update
install -m 755 "$source_dir/kiosk.sh" /usr/local/bin/manaar-kiosk
if [[ ! -f /etc/manaar.conf ]]; then
  cat > /etc/manaar.conf <<'EOF'
REPOSITORY=https://github.com/septiandch/manaar.git
# Empty means the default branch recorded when the repository is first cloned.
BRANCH=
EOF
fi
cat > /etc/systemd/system/manaar.service <<'EOF'
[Unit]
Description=Manaar application
After=network.target
[Service]
User=manaar
Group=manaar
WorkingDirectory=/opt/manaar/current
Environment=NODE_ENV=production HOST=127.0.0.1 PORT=3000 ORIGIN=http://localhost:5000 BODY_SIZE_LIMIT=100M
ExecStart=/usr/local/bin/node /opt/manaar/current/build/index.js
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/manaar-update.service <<'EOF'
[Unit]
Description=Build and deploy Manaar updates
Wants=network-online.target
After=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/local/bin/manaar-update
TimeoutStartSec=2h
EOF
cat > /etc/systemd/system/manaar-update.timer <<'EOF'
[Unit]
Description=Check Manaar Git repository daily
[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=15m
Persistent=true
[Install]
WantedBy=timers.target
EOF
cat > /etc/nginx/conf.d/manaar.conf <<'EOF'
server {
    listen 127.0.0.1:5000;
    server_name localhost;
    client_max_body_size 100m;
    location /uploads/ {
        alias /opt/manaar/shared/static/uploads/;
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
/usr/local/bin/manaar-update
systemctl enable manaar.service nginx.service manaar-update.timer
systemctl restart nginx.service
systemctl start manaar-update.timer
# Dedicated labwc session avoids desktop display profiles overriding kiosk output.
install -d /etc/manaar-labwc /usr/share/wayland-sessions /etc/lightdm/lightdm.conf.d
printf '/usr/local/bin/manaar-kiosk &\n' > /etc/manaar-labwc/autostart
cat > /usr/share/wayland-sessions/manaar.desktop <<'EOF'
[Desktop Entry]
Name=Manaar Kiosk
Exec=labwc -C /etc/manaar-labwc
Type=Application
EOF
cat > /etc/lightdm/lightdm.conf.d/99-manaar.conf <<EOF
[Seat:*]
autologin-user=$kiosk_user
autologin-user-timeout=0
autologin-session=manaar
user-session=manaar
EOF
cmdline=/boot/firmware/cmdline.txt
[[ -f $cmdline ]] || cmdline=/boot/cmdline.txt
[[ -f $cmdline ]]
[[ -f $cmdline.manaar-backup ]] || cp "$cmdline" "$cmdline.manaar-backup"
python3 - "$cmdline" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
tokens = [t for t in p.read_text().split() if not t.startswith(('video=HDMI-A-1:', 'video=HDMI-A-2:'))]
tokens += ['video=HDMI-A-1:1920x1080M@60D', 'video=HDMI-A-2:1920x1080M@60D']
p.write_text(' '.join(tokens) + '\n')
PY
echo 'Setup complete. Reboot with: sudo reboot'
