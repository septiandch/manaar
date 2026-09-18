# Manar

A mosque prayer display built with Svelte 5, SvelteKit, TypeScript, and Tailwind CSS. Designed for a landscape screen or TV, it combines a daily prayer schedule, a clock and Hijri date, announcement media, and prayer countdown overlays.

## Getting started

Use Node.js 22.18 or newer in the Node 22 release line, and pnpm. The repository includes `pnpm-lock.yaml`.

```sh
pnpm install
pnpm dev
```

The development server opens at `http://localhost:5000` and listens on network interfaces for access from another device.

1. Open `/config`, enter the mosque title, subtitle, coordinates, and timing preferences, then save.
2. Open `/upload` to add and arrange announcement images or videos.
3. Open `/` on the display device and enable the browser's fullscreen mode.

Set the display device's date, time, and timezone to the mosque's local timezone. Prayer time formatting currently uses the device timezone.

## Features

- Daily Imsyak, Subuh, Syuruq, Dzuhur, Ashar, Maghrib, and Isya schedule.
- Current and upcoming prayer indicators.
- Gregorian and Hijri date display with a configurable Hijri day adjustment.
- Image and muted video carousel with configurable slide duration.
- Countdown before adhan, adhan content, iqamah countdown, and prayer content.
- Hadith beside the countdown timer, with clock ticks that advance each second and reduced-motion support.
- A Friday Dzuhur sequence for Jumuah.
- Configuration and media updates delivered to the display through server-sent events.

## Configuration

Settings are edited at `/config` and stored on the server in `data/config.json`.

| Setting                     | Purpose                                       | Unit            |
| --------------------------- | --------------------------------------------- | --------------- |
| `title`, `subtitle`, `logo` | Display identity                              | Text / image    |
| `latitude`, `longitude`     | Prayer calculation location                   | Decimal degrees |
| `carouselDuration`          | Time between carousel slides                  | Seconds         |
| `hijriAdj`                  | Manual Hijri calendar adjustment              | Days            |
| `beforeNotice`              | Countdown before Imsyak and Syuruq            | Minutes         |
| `beforeAdhan`               | Countdown before the prayer starts            | Minutes         |
| `adhanDuration`             | Duration of the adhan screen                  | Minutes         |
| `beforeIqamah`              | Iqamah countdown after the adhan screen       | Minutes         |
| `prayerDuration`            | Regular prayer screen duration after iqamah   | Minutes         |
| `jumuahDuration`            | Friday prayer duration after the adhan screen | Minutes         |

For example, with an adhan time of 12:00, `adhanDuration: 7`, and `beforeIqamah: 7`, the iqamah countdown runs from 12:07 to 12:14.

The form also exposes `taraweehFromIsya` and `taraweehDuration`. These are not currently wired into a dedicated Tarawih display sequence; the schedule hides Tarawih.

The default form coordinates are `-6.2474466, 107.1484521`. Change them to the actual display location.

## Media and storage

Use `/upload` to upload, reorder, or delete carousel media.

- Images: JPG, JPEG, PNG, and WebP.
- Videos: MP4 and WebM; playback is muted.
- Media upload limit in the API: 200 MiB per file.
- Logos: JPG, JPEG, PNG, WebP, or SVG, up to 5 MiB.

The server writes these paths relative to its working directory:

| Path                        | Contents                          |
| --------------------------- | --------------------------------- |
| `data/config.json`          | Saved display settings            |
| `static/uploads/`           | Uploaded logos and carousel media |
| `static/uploads/order.json` | Carousel ordering                 |

Keep these directories writable and preserve them when moving or redeploying the application.

## Prayer calculation

`src/lib/utils/prayer-engine.ts` calculates prayer times locally using `adhan`. It starts with the Muslim World League preset, overrides the Subuh angle to 20 degrees and Isya angle to 18 degrees, and defaults to the Shafi madhab. Imsyak is ten minutes before Subuh.

The implementation inherits the preset's adjustments and rounding. It does not fetch the Kemenag timetable or explicitly apply elevation corrections and local ikhtiyat adjustments. Compare results with the intended local timetable before choosing any additional offsets.

## Development commands

| Command            | Action                                    |
| ------------------ | ----------------------------------------- |
| `pnpm dev`         | Start development server on port 5000     |
| `pnpm build`       | Build the Node server                     |
| `pnpm preview`     | Preview the production build on port 5000 |
| `pnpm check`       | Run Svelte and TypeScript diagnostics     |
| `pnpm check:watch` | Watch for diagnostic changes              |
| `pnpm test`        | Run the Node test suite                   |
| `pnpm lint`        | Check formatting with Prettier            |
| `pnpm format`      | Format the project with Prettier          |

The test command uses Node's TypeScript stripping support.

For countdown development, `src/lib/stores/clock.ts` provides `createDebugClock(startTime, speed)`. Open `/?debug` to select `debugClock` and simulate prayer transitions. Open `/` without the `debug` parameter to use the real clock.
Set a custom debug starting date and time with `/?debug&datetime=2026-09-19T11:45:52`.
Without a timezone suffix, the value uses the device's local timezone. Use `Z` for
UTC, or encode an explicit positive offset, for example
`/?debug&datetime=2026-09-19T11:45:52%2B07:00`. The custom clock advances at normal
speed. Missing or invalid datetime values fall back to the default `debugClock`;
`datetime` is ignored unless `debug` is present.

## Raspberry Pi deployment

Follow these steps to install the app and open it fullscreen automatically at startup. The installer requires **64-bit Raspberry Pi OS Desktop with LightDM**; Lite is not supported. Installation paths and services use `manar`, the repository's deployment name.

Already installed under the old `manaar` name? Follow the [migration steps](scripts/raspberry-pi/README.md#migrate-an-existing-manaar-installation) before running the renamed installer.

### 1. Install Raspberry Pi OS

Prepare a Raspberry Pi capable of running the 64-bit desktop OS, suitable power supply, microSD card or SSD, internet connection, keyboard/mouse, and HDMI display. Connect the display to HDMI0. The installer forces **1920x1080 at 60 Hz**, so your screen must support that mode.

On your laptop/PC:

1. Open [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Select your Pi and **Raspberry Pi OS (64-bit) with Desktop**.
3. Select the card/SSD; writing the image erases that selected storage.
4. Set a hostname such as `manar-pi`, your username/password, Wi-Fi if needed, and your timezone. Enable SSH for maintenance after kiosk startup.
5. Write the image, insert the storage into the Pi, and power it on.

See the official [OS installation guide](https://www.raspberrypi.com/documentation/computers/getting-started.html) for the imaging and first-boot steps.

### 2. Connect and prepare the Pi

Open Terminal on the Pi, or connect from your laptop/PC. Replace `piuser` with the username you created:

```sh
ssh piuser@manar-pi.local
```

If the hostname does not resolve, use the Pi's IP address from your router. Run the following **on the Pi**:

```sh
uname -m
sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get install -y git
sudo timedatectl set-timezone Asia/Jakarta
sudo timedatectl set-ntp true
sudo reboot
```

`uname -m` must print `aarch64`. Replace `Asia/Jakarta` with your mosque's timezone if different. Reconnect after reboot and run `timedatectl` to confirm the local time and clock synchronisation.

### 3. Download and install the app

Run on the Pi from your normal desktop user account:

```sh
cd ~
git clone https://github.com/septiandch/manar.git
cd ~/manar
sudo bash scripts/raspberry-pi/setup.sh
```

If `~/manar` already exists, use `cd ~/manar` and `git pull --ff-only` instead of cloning again. Run setup through `sudo` as shown, not from a root login.

The script installs Node 22, pnpm 10, Chromium, nginx, and build tools, builds the app, and configures services, desktop autologin, and the fullscreen kiosk. Wait until it prints `Setup complete`.

The installer deploys the **remote repository's default branch**, not local uncommitted files. Commit and push any intended app changes from your development computer first. For a private repository, the separate `manar` service account also needs Git read access; see the [detailed setup guide](scripts/raspberry-pi/README.md#5-download-and-install-the-kiosk).

### 4. Verify the server

Before rebooting, run on the Pi:

```sh
systemctl is-active manar.service nginx.service manar-update.timer
curl --fail http://localhost:5000/ -o /dev/null
```

Expect three `active` lines and a successful curl command. If a check fails, inspect the installer output and `journalctl -u manar.service -n 100 --no-pager` before continuing.

### 5. Configure the mosque and media

In the Pi's browser, open:

- `http://localhost:5000/config` to save mosque details, coordinates, and prayer timing preferences.
- `http://localhost:5000/upload` to upload and arrange images/videos.
- `http://localhost:5000/` to check the display and current time. Keep `?debug` out of the kiosk URL.

To configure it from your laptop/PC instead, run this **on that computer** and keep the terminal open:

```sh
ssh -N -L 5000:127.0.0.1:5000 piuser@manar-pi.local
```

Then visit the same `http://localhost:5000` URLs in your laptop's browser. Stop any local development server using port 5000 first. The Pi's app listens only on loopback, so direct access through `http://PI-IP:5000` will not work.

The installer sets a 100 MiB request limit in nginx and the Node service. Keep uploaded files below that size to allow for multipart overhead, even though the app API allows 200 MiB per media file.

### 6. Start the fullscreen display

Run on the Pi:

```sh
sudo reboot
```

After boot, the Pi should log in automatically and open Chromium at `http://localhost:5000/`. Check the clock, prayer schedule, saved settings, and media. To edit settings later, reconnect the SSH tunnel from step 5.

### 7. Updates and maintenance

Daily Git update checks run at **03:00 local time**, with up to 15 minutes of random delay. To check manually, run on the Pi:

```sh
sudo systemctl start manar-update.service
journalctl -u manar-update.service -n 100 --no-pager
systemctl list-timers manar-update.timer
```

Updates build and check a new release before activation and restore the previous release if activation fails. Settings and uploads are kept in `/opt/manar/shared/data/` and `/opt/manar/shared/static/uploads/`; back these up. Existing checkout data is not imported automatically.

See the [detailed Raspberry Pi guide](scripts/raspberry-pi/README.md) for backups, changing the update branch/time, private repository access, troubleshooting, and restoring normal desktop boot if the display stays blank. Actual boot and HDMI behaviour still require verification on your Pi.

## Production

The project uses `@sveltejs/adapter-node` and requires a Node server for its configuration, upload, and event endpoints.

```sh
pnpm build
node build
```

Run from the project directory so the storage paths resolve consistently. Configure the production server or reverse proxy to serve `/uploads/` from the writable `static/uploads/` directory; uploads added after a build must remain accessible independently of the built static assets. Set request body limits to accommodate the uploads you intend to allow.

## Project layout

```text
src/routes/+page.svelte               Main display
src/routes/config/                   Configuration form
src/routes/upload/                   Media management
src/routes/api/                      Configuration, media, and event endpoints
src/routes/layout.css                Theme variables and global styles
src/lib/components/prayer-ui/        Prayer schedule and overlays
src/lib/components/date-clock/       Clock and Hijri date components
src/lib/stores/clock.ts              Real and simulated clocks
src/lib/stores/prayertime.ts         Daily prayer schedule store
src/lib/utils/prayer-engine.ts       Prayer calculation and event transitions
```

Change `--background` and the other theme variables in `src/routes/layout.css` to customize the display colors. Hadith content and countdown styling live in `src/lib/components/prayer-ui/prayer-screen.svelte`.
