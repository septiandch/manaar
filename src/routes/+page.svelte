<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { clock } from '$lib/stores/clock';
	import { createPrayerStore } from '$lib/stores/prayertime';
	import { PrayerSchedule, TimeDisplay } from '@/components/prayer-ui';
	import PrayerScreen from '@/components/prayer-ui/prayer-screen.svelte';
	import Carousel from '@/components/ui/carousel/carousel.svelte';
	import { onMount } from 'svelte';

	let { data } = $props();

	let { title, subtitle, carouselDuration, longitude, latitude, logo, media, hijriAdj, ...config } =
		$derived(data);

	let clockStore = clock;
	// let clockStore = debugClock;

	let now = $derived($clockStore);

	let prayerStore = $derived(createPrayerStore(clockStore, latitude, longitude));
	let prayerTimes = $derived($prayerStore);

	onMount(() => {
		const event = new EventSource('/api/events');
		event.addEventListener('update', invalidateAll);

		return () => {
			event.close();
		};
	});
</script>

<div
	class="grid h-screen w-screen grid-cols-10 justify-center gap-4 bg-background p-4 tv:grid-cols-12"
>
	<div class="col-span-8 flex h-full min-h-0 flex-col items-stretch gap-2 tv:col-span-9">
		<div class="flex h-24 w-full items-center justify-between">
			<div class="flex items-center gap-4">
				<div class="h-16 w-16">
					<img src={logo as string} alt="logo" class="object-contain" />
				</div>

				<div class="flex w-max flex-col items-start justify-center">
					<h1 class="text-4xl font-bold">{title}</h1>
					<h3 class="text-xl font-semibold">{subtitle}</h3>
				</div>
			</div>

			<TimeDisplay {now} maghribTime={prayerTimes.Maghrib} {hijriAdj} />
		</div>

		<div class="mx-auto w-full flex-1 overflow-hidden rounded-md bg-primary/50 p-2">
			<div class="h-full w-full overflow-hidden rounded-md">
				<Carousel {media} delay={carouselDuration * 1000} />
			</div>
		</div>
	</div>

	<div class="col-span-2 h-full rounded-md bg-primary/50 ring-primary/50 tv:col-span-3">
		<PrayerSchedule {now} {prayerTimes} />
	</div>
</div>

<PrayerScreen {config} {clockStore} {prayerTimes} />
