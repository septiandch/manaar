<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import { msToHms } from '$lib/utils/date-utils';
	import {
		getCurrentPrayer,
		getNextPrayer,
		type PrayerLabel,
		type PrayerTimeType
	} from '$lib/utils/prayer-engine';
	import type { ClassValue } from 'clsx';
	import PrayerTime from './prayer-time.svelte';

	type PropsType = { prayerTimes: PrayerTimeType; class?: ClassValue; now: Date };

	let { prayerTimes, class: className, now }: PropsType = $props();

	const timeLabels = $derived(Object.keys(prayerTimes)) as PrayerLabel[];

	const currPrayer = $derived(getCurrentPrayer(prayerTimes, now));
	const nextPrayer = $derived(getNextPrayer(prayerTimes, now));

	const { h, m } = $derived(msToHms(nextPrayer.countdown));
	const nextPrayerLabel = $derived(Number(h) > 0 ? `${h} jam ${m} menit` : `${m} menit`);
</script>

<div class={cn('flex h-full flex-col items-center justify-between rounded-md p-2', className)}>
	<div class="flex flex-col items-center py-2 text-black/50">
		<span class="text-2xl font-bold">Menuju {nextPrayer.name}</span>
		<span class="text-3xl tv:font-bold">{nextPrayerLabel}</span>
	</div>

	<div class="flex h-full w-full flex-col justify-between rounded-md bg-black/10 p-2">
		{#each timeLabels as label}
			{#if label !== 'Tarawih'}
				<PrayerTime
					active={label === currPrayer?.name}
					incoming={label === nextPrayer.name}
					{label}
					time={prayerTimes[label]}
				/>
			{/if}
		{/each}
	</div>
</div>
