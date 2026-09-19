# Raspberry Pi: PM2 server and fullscreen desktop browser

Manar runs under PM2 and is available on the Pi and other devices on the same
local network. Chromium starts as an ordinary fullscreen window on the normal
Raspberry Pi desktop. There is no dedicated kiosk session or forced display mode.

## 1. Prepare the Pi

Use **64-bit Raspberry Pi OS Desktop with LightDM**, an HDMI display, internet
access, and a normal desktop user with sudo permission. Lite is unsupported.
Install the OS with [Raspberry Pi Imager](https://www.raspberrypi.com/software/),
setting a username/password, Wi-Fi, timezone, and SSH access. Imaging erases the
selected storage. Follow the [official OS guide](https://www.raspberrypi.com/documentation/computers/getting-started.html).

Run on the Pi, in Terminal or over SSH:

```sh
uname -m
sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get install -y git
sudo timedatectl set-timezone Asia/Jakarta
sudo timedatectl set-ntp true
sudo reboot
```

`uname -m` must report `aarch64`. Use the mosque's actual timezone. Reconnect after
reboot and verify `timedatectl`. If apt reports a lock held by another process,
let that package operation finish and retry; do not delete the lock.

## 2. Download and install

```sh
cd ~
git clone https://github.com/septiandch/manar.git
cd ~/manar
sudo bash scripts/raspberry-pi/setup.sh
```

For an existing checkout, enter it and run `git pull --ff-only` instead of cloning
again. Run setup through sudo from the desktop user, not a root login. The
installer deploys the remote repository's branch, so push intended app changes
before installing. Private repositories need noninteractive read credentials for
the `manar` service account, independently of your desktop user's Git credentials.

Setup installs Node 22, pnpm 10, PM2 6, nginx, and Chromium. It uses a separate
`manar` service account for PM2, builds the app under `/opt/manar/releases`, and
configures nginx on IPv4 port 5000. The Node backend listens only on loopback port
3000. nginx serves writable uploads and supplies the host/protocol headers so
forms work from both localhost and the Pi's LAN address.

PM2's startup service restores the saved app at boot. The normal Raspberry Pi
desktop session logs in automatically and uses an XDG autostart entry to run
`manar-browser`. This waits for the server, then opens Chromium fullscreen.

## 3. Migrate an existing installation

The same setup command replaces the previous Manar systemd/kiosk deployment.
Before running it, back up settings and media and allow any running update to
finish. Setup briefly interrupts hosting while changing process managers.

```sh
sudo systemctl stop manar-update.timer
sudo systemctl stop manaar-update.timer
```

A missing unit for one spelling is normal. Check the corresponding update service
is inactive before backing up. For an existing `/opt/manar` installation:

```sh
sudo systemctl stop manar.service
sudo tar -czf "$HOME/manar-before-pm2.tar.gz" -C /opt/manar/shared data static/uploads
```

For the older `/opt/manaar` spelling, use its service name and shared directory.
Setup preserves `/opt/manar/shared`. If only `/opt/manaar/shared` exists, it copies
that data into the new location and leaves the old copy intact. If both exist,
it uses `/opt/manar/shared`; reconcile your data before setup if necessary.

From the updated checkout, run:

```sh
sudo bash scripts/raspberry-pi/setup.sh
```

The installer disables old `manar`/`manaar` app services and update timers, retires
the old LightDM kiosk configuration, and configures the normal desktop session.
It removes only the HDMI overrides the previous installer inserted. The new
updater uses PM2 and the daily `manar-update.timer` is enabled again.

If you have an unrelated older app in your desktop user's PM2 list, inspect
`pm2 list` and stop/delete only that app if it occupies ports 3000 or 5000. Save
that user's process list with `pm2 save` (use `--force` for an empty list).
Disable any old browser autostart you previously configured separately; setup
only manages Manar's own files. Other PM2 applications are left in place.

## 4. Verify local and Wi-Fi access

```sh
sudo -u manar -H /usr/local/bin/pm2 list
curl --fail http://localhost:5000/ -o /dev/null
hostname -I
```

PM2 should show `manar` online. Use `http://localhost:5000/` on the Pi. On another
device on the same Wi-Fi, replace localhost with the Pi's IPv4 address, for example:

- `http://192.168.1.50:5000/` for the display.
- `http://192.168.1.50:5000/config` for mosque details and prayer timings.
- `http://192.168.1.50:5000/upload` for images/videos.

Use HTTP and include port 5000. No SSH tunnel is needed. Settings and uploads have
no authentication, so use this on a trusted LAN. nginx and Node allow 210 MiB
requests to accommodate the API's 200 MiB file limit plus multipart overhead.

If local access works but another device cannot connect, check:

```sh
sudo ss -ltnp | grep ':5000'
```

It should show `0.0.0.0:5000`. Confirm the IP, that both devices share a LAN, and
that guest Wi-Fi/client isolation is disabled. If you use a firewall, allow TCP
5000 from your LAN subnet. A router DHCP reservation helps keep the address stable.

## 5. Reboot and use the display

After setup reports `Setup complete`:

```sh
sudo reboot
```

The normal desktop starts and Chromium opens fullscreen. Press **F11** to leave
fullscreen or **Alt+F4** to close it. PM2 keeps serving the app even if the browser
is closed. Reopen with `manar-browser` in a graphical desktop terminal; do not run
the browser with sudo or directly from an SSH/text-console session.

Configure resolution and orientation using the normal desktop display settings.
Keep `?debug` out of the display URL to use the real clock.

## 6. PM2 management and updates

Manar's PM2 daemon belongs to the `manar` service account. A plain `pm2 list`
under your desktop user shows a different process list. Use:

```sh
sudo -u manar -H /usr/local/bin/pm2 list
sudo -u manar -H /usr/local/bin/pm2 logs manar --lines 50 --nostream
sudo -u manar -H /usr/local/bin/pm2 restart manar
systemctl status pm2-manar.service nginx.service
```

Updates check Git at 03:00 local time, with up to 15 minutes of random delay.
The updater builds and smoke-tests a separate release, switches the current
symlink, and restarts the PM2 app. Failed activation rolls back to the previous
release. Persistent data is not rolled back. Refresh the browser after a code
update to load the new frontend; the browser is not forcibly restarted.

```sh
sudo systemctl start manar-update.service
journalctl -u manar-update.service -n 100 --no-pager
systemctl list-timers manar-update.timer
```

Edit `/etc/manar.conf` to set the Git `REPOSITORY` and `BRANCH`. An empty branch
uses the default recorded at the initial clone. Daily updates do not update OS
packages or deployment scripts; pull your checkout and rerun setup for those
script changes. Setup reenables the daily timer. Disable it if desired with:

```sh
sudo systemctl disable --now manar-update.timer
```

## 7. Storage and backups

| Path | Purpose |
| --- | --- |
| `/opt/manar/shared/data` | Mosque settings |
| `/opt/manar/shared/static/uploads` | Media, logos, and ordering |
| `/opt/manar/releases` | Built releases |
| `/opt/manar/current` | Active release symlink |
| `/opt/manar/.pm2` | PM2 state and server logs |
| `/opt/manar/ecosystem.config.cjs` | PM2 application definition |
| `/etc/manar.conf` | Update repository and branch |
| `~/.config/autostart/manar.desktop` | Desktop user's browser startup |

To back up, stop the update timer, wait for any active update to finish, then:

```sh
sudo -u manar -H /usr/local/bin/pm2 stop manar
sudo tar -czf "$HOME/manar-data-$(date +%Y%m%d-%H%M%S).tar.gz" -C /opt/manar/shared data static/uploads
sudo -u manar -H /usr/local/bin/pm2 restart manar
```

Copy the archive off the Pi and restart the timer if previously enabled. Monitor
space with `df -h /opt/manar`; old releases are retained. Keep the active and
previous working release when cleaning up.

## Troubleshooting

### Restore pages prompt after startup

The launcher includes `--hide-crash-restore-bubble` to suppress Chromium's
"Restore pages?" prompt after an unclean shutdown. Once the updated files are on
the Pi, run from the project checkout:

```sh
sudo install -m 755 scripts/raspberry-pi/browser.sh /usr/local/bin/manar-browser
sudo reboot
```

This applies to Manar's browser launcher; other Chromium startup entries need
their own flag. It hides the recovery prompt without deleting the browser profile.


### Small browser window or keyring prompt

The launcher requests both maximized and fullscreen startup and uses
`--password-store=basic` for its dedicated Manar browser profile. This avoids
Chromium requesting the desktop keyring; do not store passwords in this profile,
as basic storage does not provide keyring protection. Other browser profiles
are unchanged. See [Chromium password storage](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux/password_storage.md).

After downloading the updated scripts, install only the browser launcher:

```sh
sudo install -m 755 scripts/raspberry-pi/browser.sh /usr/local/bin/manar-browser
```

Close the existing Manar Chromium window with Alt+F4, then run `manar-browser`
from a graphical desktop terminal, or reboot. An already running browser profile
may reuse its existing window and ignore startup flags. If the window is still
small, focus Chromium and press F11 to enter fullscreen. This does not require
reinstalling PM2 or changing the display resolution.


For browser errors, as the desktop user:

```sh
tail -n 50 "${XDG_STATE_HOME:-$HOME/.local/state}/manar/browser.log"
cat ~/.config/autostart/manar.desktop
pgrep -af 'labwc|lxsession|manar-browser|chromium'
```

If the desktop has no panel, verify that `/etc/lightdm/lightdm.conf.d/99-manar-desktop.conf`
selects an installed normal desktop session, not `manar` or `manaar`. Custom user
labwc autostart files may override the desktop's default panel startup; inspect
those if you had customised your previous fullscreen setup. Inspect login errors:

```sh
sudo journalctl --unit=lightdm.service --boot=0 --lines=50 --no-pager
```

If hosting fails, inspect PM2 logs and `sudo nginx -t`. To identify port conflicts,
use `sudo ss -ltnp`. Actual desktop login, fullscreen startup, and access from a
second Wi-Fi device must be verified on the Pi; they cannot be verified on Windows.

References: [PM2 boot startup](https://pm2.keymetrics.io/docs/usage/startup/),
[SvelteKit proxy headers](https://svelte.dev/docs/kit/adapter-node), and
[Raspberry Pi desktop autostart](https://github.com/raspberrypi-ui/raspberrypi-ui-mods/blob/master/etc/xdg/labwc/autostart).
