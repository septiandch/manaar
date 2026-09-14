<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import { formatHHmm } from '$lib/utils/date-utils';
	import type { PrayerLabel } from '$lib/utils/prayer-engine';
	import { CloudMoon, CloudSun, Haze, Moon, Sun, Sunrise, Sunset } from '@lucide/svelte';

	let {
		label,
		time,
		active = false,
		incoming = false
	}: { label: PrayerLabel; time: Date; active?: boolean; incoming?: boolean } = $props();

	const prayerTime = $derived(formatHHmm(time));

	const iconMap: { [key: string]: any } = {
		Imsyak: CloudMoon,
		Subuh: Haze,
		Syuruq: Sunrise,
		Dzuhur: Sun,
		Ashar: CloudSun,
		Maghrib: Sunset,
		Isya: Moon
	} as const;

	const Icon = $derived(iconMap[label] ?? Sun);
</script>

<div
	class={cn(
		'flex h-max w-full justify-between gap-2 rounded-md pl-6 tv:my-2 tv:h-full',
		active && 'bg-white text-primary',
		incoming && 'bg-black/20'
	)}
>
	<div class="h-12 w-12 self-center justify-self-end tv:col-span-1 tv:h-10 tv:w-10">
		<Icon class="h-full w-full" />
	</div>

	<div
		class="flex w-full flex-1 flex-col items-center justify-center gap-2 self-center p-2 tv:col-span-5 tv:flex-row tv:justify-between"
	>
		<span class="text-3xl">
			{label}
		</span>

		<span class="text-3xl font-bold">
			{prayerTime}
		</span>
	</div>
</div>
