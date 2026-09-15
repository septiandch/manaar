<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { clock, debugClock } from '$lib/stores/clock';
	import { createPrayerStore } from '$lib/stores/prayertime';
	import { PrayerSchedule, TimeDisplay } from '@/components/prayer-ui';
	import PrayerScreen from '@/components/prayer-ui/prayer-screen.svelte';
	import Carousel from '@/components/ui/carousel/carousel.svelte';
	import { onMount } from 'svelte';

	let { data } = $props();

	let { title, subtitle, carouselDuration, longitude, latitude, logo, media, hijriAdj, ...config } =
		$derived(data);

	let clockStore = false ? clock : debugClock;

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

<div class="flex h-screen w-screen justify-center gap-4 bg-background p-4">
	<div class="flex h-full min-h-0 w-full flex-col items-stretch gap-2">
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

	<div class="h-full w-94 rounded-md bg-primary/50 ring-primary/50 tv:w-80">
		<PrayerSchedule {now} {prayerTimes} />
	</div>
</div>

<PrayerScreen {config} {clockStore} {prayerTimes} />
