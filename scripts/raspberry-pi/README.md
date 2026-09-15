# Raspberry Pi kiosk: step-by-step setup

This guide targets **64-bit Raspberry Pi OS Desktop with LightDM** (Bookworm/Trixie).
The installer configures automatic login, fullscreen Chromium, forced 1920x1080
output, a Node server, and daily Git updates that build before restarting the app.

## 1. Prepare the hardware

Have your Raspberry Pi, suitable power supply, microSD card or SSD, HDMI display,
keyboard, mouse, and internet connection ready. A Pi 4 or 5 is a practical starting
point for building and running this app. Allow space for multiple release builds.
Connect one display to HDMI0 for the initial setup.

## 2. Install Raspberry Pi OS

On your laptop/PC:

1. Install [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Select your Pi model and **Raspberry Pi OS (64-bit) with Desktop**. Do not select Lite.
3. Select the target SD card/SSD. Writing the image erases that selected device.
4. In OS customisation, set hostname `manaar-pi`, a username and password, Wi-Fi
   if needed, and your locale/timezone. Enable SSH and configure authentication.
5. Write the image, safely eject the storage, insert it into the Pi, and power on.

Follow the official [OS installation guide](https://www.raspberrypi.com/documentation/computers/getting-started.html)
for the Imager screens. The examples below use username `piuser`; replace it with yours.

## 3. Connect and prepare the Pi

Open Terminal on the Pi, or run this from your laptop/PC:

```sh
ssh piuser@manaar-pi.local
```

If the hostname does not resolve, use the Pi's IP address from your router or
`hostname -I` in the Pi's terminal. See the official
[SSH instructions](https://www.raspberrypi.com/documentation/computers/remote-access.html).
Keep SSH available for maintenance after the desktop becomes a fullscreen kiosk.

Run these commands **on the Pi**:

```sh
uname -m
sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get install -y git
sudo timedatectl set-timezone Asia/Jakarta
sudo timedatectl set-ntp true
timedatectl
sudo reboot
```

`uname -m` must print `aarch64`. Select your actual timezone if it differs from
Asia/Jakarta. After reboot, reconnect with SSH or open Terminal again. Confirm
`timedatectl` shows the correct local time and a synchronised clock.

## 4. Prepare the application for deployment

On your development computer, before pushing the version to deploy:

1. In `src/routes/+page.svelte`, select the real clock:

   ```ts
   let clockStore = clock;
   ```

   At the time this guide was written, the file used `false ? clock : debugClock`,
   which selects simulated time. Remove the unused `debugClock` import when switching.
2. Run `pnpm check` and `pnpm build`.
3. Commit and push the desired app changes and `scripts/raspberry-pi/` to GitHub.

The installer deploys the **remote repository**, not uncommitted files in the Pi's
checkout. By default it uses the repository's default branch recorded on first clone.

## 5. Download and install the kiosk

On the Pi, from your normal user account:

```sh
cd ~
git clone https://github.com/septiandch/manaar.git
cd ~/manaar
sudo bash scripts/raspberry-pi/setup.sh
```

If `~/manaar` already exists, use that checkout and update it with
`git pull --ff-only` instead of cloning again. Run the setup through `sudo` from
the user who should log into the kiosk; do not use a root login or `sudo su`.

The script installs Node 22, pnpm 10, Chromium, labwc, nginx and build tools. It
creates the separate `manaar` service account, builds the initial release, installs
systemd services, and configures kiosk login and HDMI output. Leave it running
until it reports `Setup complete`. Internet access is required.

For a private repository, the deployment service account also needs read access;
credentials used by your normal user are not automatically shared. Configure a
read-only Git credential for `manaar` before the initial clone performed by the
updater. If setup fails at authentication, configure that account and rerun setup.
Updates cannot answer interactive authentication prompts.

## 6. Verify the server before rebooting

On the Pi:

```sh
systemctl is-active manaar.service nginx.service manaar-update.timer
curl --fail http://localhost:5000/ -o /dev/null
systemctl list-timers manaar-update.timer
cat /opt/manaar/current/.release-commit
```

Expect three `active` lines, a successful curl exit, a scheduled update, and the
installed commit hash. If setup or these checks fail, inspect the errors before
rebooting. The first setup build runs directly in the terminal; later scheduled
update logs are available through the journal commands below.

## 7. Configure mosque settings and upload media

Before rebooting, open these URLs in the Pi's desktop browser:

- `http://localhost:5000/config`: set mosque details, coordinates and prayer timings, then save.
- `http://localhost:5000/upload`: upload and arrange your images/videos.
- `http://localhost:5000/`: check the display and current time.

You can also configure the app from your laptop, including after kiosk startup.
Run this **on your laptop/PC**, replacing the username and host as needed:

```sh
ssh -N -L 5000:127.0.0.1:5000 piuser@manaar-pi.local
```

Keep that terminal open and visit `http://localhost:5000/config` or `/upload` in
your laptop browser. Stop any local development server using port 5000 first.
The tunnel uses the same origin expected by the app and requires no server changes.
The Pi's app listeners are loopback-only, so `http://PI-IP:5000` is not accessible directly.

Configuration and media are stored under `/opt/manaar/shared/`. Existing checkout
files are not imported automatically. If migrating an existing installation, stop
the app and copy its `data/` and `static/uploads/` contents into the matching shared
locations, then set ownership to `manaar:manaar` before restarting.

## 8. Reboot into the display

On the Pi:

```sh
sudo reboot
```

After boot, expect automatic login to the dedicated labwc session and Chromium
opening `http://localhost:5000/` in kiosk mode. Check:

- The prayer display fills the screen and uses the correct current time.
- Saved settings and uploaded media are present.
- The cursor hides after 60 seconds without mouse/keyboard activity and returns on activity.
- A second reboot starts the app automatically again.

The browser profile is persistent. The kiosk launcher restarts Chromium if it exits.

## 9. Verify daily updates

Updates run at **03:00 local time**, with up to 15 minutes of random delay. A missed
run is caught up after boot. Trigger a check manually on the Pi:

```sh
sudo systemctl start manaar-update.service
journalctl -u manaar-update.service -n 100 --no-pager
systemctl list-timers manaar-update.timer
```

An unchanged commit reports `Already running`. For a changed commit, the updater:

1. Fetches Git and creates a separate release directory.
2. Installs dependencies with the frozen pnpm lockfile and runs `pnpm build`.
3. Checks an isolated Node server on port 3001; keep this port reserved.
4. Switches the current release and restarts production only after those checks pass.
5. Restores the previous release if activation fails.
6. Restarts Chromium after successful activation so the new app loads.

Failed installs/builds leave the running server untouched. Activation has a brief
interruption. Rollback restores code, not changes to persistent data.

To follow another branch, edit `BRANCH=` in `/etc/manaar.conf`, for example
`BRANCH=main`, then trigger a manual update. Leave it empty for the initially
recorded default branch. Daily Git updates do not install OS updates or replace
the installed deployment scripts.

To change the update time:

```sh
sudo systemctl edit manaar-update.timer
```

Add this override (example: 02:00):

```ini
[Timer]
OnCalendar=
OnCalendar=*-*-* 02:00:00
```

Then run:

```sh
sudo systemctl daemon-reload
sudo systemctl restart manaar-update.timer
systemctl list-timers manaar-update.timer
```

Disable or re-enable daily checks:

```sh
sudo systemctl disable --now manaar-update.timer
sudo systemctl enable --now manaar-update.timer
```

## 10. Back up and maintain the installation

Persistent paths:

| Path | Contents |
| --- | --- |
| `/opt/manaar/shared/data` | Mosque configuration |
| `/opt/manaar/shared/static/uploads` | Logos, media and ordering |
| `/opt/manaar/releases` | Built releases, including failed candidates |
| `/opt/manaar/current` | Symlink to the active release |
| `/etc/manaar.conf` | Git repository/branch configuration |

For a consistent backup, wait for any update to finish, avoid configuration writes,
and run on the Pi (the app is briefly stopped):

```sh
sudo systemctl stop manaar-update.timer
sudo systemctl stop manaar.service
sudo tar -czf "$HOME/manaar-data-$(date +%Y%m%d-%H%M%S).tar.gz" -C /opt/manaar/shared data static/uploads
sudo systemctl start manaar.service
sudo systemctl start manaar-update.timer
```

Copy the archive off the Pi. If you previously disabled automatic updates, leave
the timer stopped instead of starting it again.

Monitor storage with `df -h /opt/manaar` and `sudo du -sh /opt/manaar/releases/*`.
Old releases are retained; remove unused ones manually after identifying the active
release with `readlink -f /opt/manaar/current`. Keep the previous working release too.

To install future changes to the setup scripts:

```sh
cd ~/manaar
git pull --ff-only
sudo bash scripts/raspberry-pi/setup.sh
sudo reboot
```

Rerunning setup rewrites its generated service and nginx files; retain copies of
any manual customisations. `/etc/manaar.conf` and shared app data are preserved.

## Forced 1080p: behavior and recovery

Setup adds `video=HDMI-A-1:1920x1080M@60D` and the equivalent for HDMI-A-2 to the
kernel command line, backing up the original as `.manaar-backup`. The kiosk
reapplies a custom 1920x1080 at 60 Hz mode, scale 1, every ten seconds, including
on hotplug. Its dedicated session does not launch desktop display-profile managers
or idle blanking programs. See the official
[display documentation](https://www.raspberrypi.com/documentation/computers/configuration.html).

This requests 1080p even when the monitor does not advertise it. A monitor or
converter that cannot physically accept the signal may show a blank screen.

To restore ordinary desktop boot and the original display settings, connect by SSH
or use a text console (Ctrl+Alt+F2), then run:

```sh
sudo rm /etc/lightdm/lightdm.conf.d/99-manaar.conf
sudo cp /boot/firmware/cmdline.txt.manaar-backup /boot/firmware/cmdline.txt
sudo reboot
```

For systems using `/boot/cmdline.txt`, use that path and its backup instead.
Choose your normal desktop session at the login screen if needed. Both disabling
the kiosk session and restoring the boot file are necessary because the kiosk
also enforces the resolution while running. This leaves the app server installed.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Installer rejects architecture | `uname -m` must be `aarch64`; install the 64-bit desktop OS. |
| Installer requires LightDM | Use Raspberry Pi OS Desktop with LightDM; Lite is unsupported. |
| Initial build fails | Read setup terminal output, check internet and `df -h`, then rerun setup. |
| Scheduled update fails | `journalctl -u manaar-update.service -n 100 --no-pager` |
| Browser shows an error | `curl --fail http://localhost:5000/` and `journalctl -u manaar.service -n 100 --no-pager` |
| Server works but kiosk does not launch | `systemctl status lightdm` and `journalctl -u lightdm -b --no-pager`; confirm the desktop user used for setup. |
| Uploaded media is missing | Check shared upload files, their read permissions, and `sudo nginx -t`. |
| Prayer clock runs at simulated speed | Select `clock` rather than `debugClock`, push the fix, and run a manual update. |
| Display is blank after reboot | Use SSH and the desktop/display recovery procedure above. |

## Validation limits

The shell scripts have been syntax-checked. Actual boot, HDMI mode acceptance,
browser startup, and systemd activation still require verification on the Pi.
