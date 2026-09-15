# Sonora

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

For countdown development, `src/lib/stores/clock.ts` provides `createDebugClock(startTime, speed)`. Select `debugClock` instead of `clock` in `src/routes/+page.svelte` to simulate prayer transitions, and restore the real clock before using the display.

## Raspberry Pi deployment

See [Raspberry Pi setup](scripts/raspberry-pi/README.md) for kiosk autostart, forced 1080p, and daily Git updates with build checks and rollback.

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
