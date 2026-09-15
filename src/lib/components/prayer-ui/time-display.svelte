<script lang="ts">
	import { DateClock, HijriDate } from '$lib/components/date-clock';
	import { cn } from '@/utils/cn';
	import { onDestroy, onMount } from 'svelte';

	type PropsType = { now: Date; maghribTime?: Date; hijriAdj?: number };

	let { now, maghribTime, hijriAdj }: PropsType = $props();

	let showClock = $state(true);
	let timer: ReturnType<typeof setTimeout>;

	function loop() {
		timer = setTimeout(
			() => {
				showClock = !showClock;
				loop();
			},
			showClock ? 5000 : 5000
		);
	}

	onMount(() => {
		loop();
	});

	onDestroy(() => {
		clearTimeout(timer);
	});
</script>

<div class="relative mt-2 h-full w-100 overflow-hidden text-white">
	<!-- Clock -->
	<div
		class={cn(
			'absolute inset-0 flex flex-col items-end justify-center transition-transform duration-700 ease-in-out',
			showClock ? 'translate-y-0' : '-translate-y-full'
		)}
	>
		<DateClock {now} format="dddd, DD MMMM YYYY" class="text-3xl font-bold" />
		<HijriDate {now} {maghribTime} adjustment={hijriAdj} class="text-3xl font-bold" />
	</div>

	<!-- Date -->
	<div
		class={cn(
			'absolute inset-0 flex items-center justify-end transition-transform duration-700 ease-in-out',
			showClock ? 'translate-y-full' : 'translate-y-0'
		)}
	>
		<DateClock {now} class="mb-2 text-7xl font-bold" />
	</div>
</div>
