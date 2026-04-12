<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import {
		createPrayerEngine,
		type PrayerConfig,
		type PrayerEngine,
		type PrayerEventState,
		type PrayerState,
		type PrayerTimeType
	} from '$lib/utils/prayer-engine';
	import { onMount, type Snippet } from 'svelte';
	import type { Readable } from 'svelte/store';
	import { FlipDisplay } from '../flip-display';

	type PropsType = {
		clockStore: Readable<Date>;
		prayerTimes: PrayerTimeType;
		config: PrayerConfig;
	};

	type OverlayMode = 'default' | 'fadeout';

	let { config, clockStore, prayerTimes }: PropsType = $props();

	let eventState: PrayerEventState | undefined = $state();

	let remainingMs = $derived(
		eventState?.nextTransition
			? Math.max(0, eventState.nextTransition.getTime() - $clockStore.getTime())
			: 0
	);

	const ePrayer = $derived(eventState?.prayer || 'Imsyak');
	const eState = $derived(eventState?.state || 'IDLE');

	// Control overlay mode here
	const FADEOUT_STATE: PrayerState[] = ['JUMUAH', 'PRAYER'];
	const overlayMode = $derived(FADEOUT_STATE.includes(eState) ? 'fadeout' : 'default');

	let engine: PrayerEngine;

	function onEventChange(e: PrayerEventState) {
		eventState = e;

		if (e.state === 'ADHAN') {
			playBeep();
		}
	}

	onMount(() => {
		engine = createPrayerEngine(prayerTimes, config, onEventChange);

		const unsub = clockStore.subscribe((clock) => {
			engine.update(clock);
		});

		return () => unsub();
	});

	function playBeep() {
		const audio = new Audio('/beep.mp3');
		audio.play();
	}

	const contents = {
		ADHAN: {
			text: 'Ucapkanlah sebagaimana yang disebutkan\noleh muadzin. Lalu jika azan selesai berdoalah,\nmaka Allah akan kabulkan.',
			src: 'HR. Abu Daud no. 524 dan Ahmad 2: 172'
		},
		JUMUAH: {
			text: 'Apabila dibacakan Al-Quran (khutbah),\nmaka dengarkanlah baik-baik,\ndan perhatikanlah dengan tenang\nagar kamu mendapat rahmat.\n',
			src: "QS. Al-A'raf: 204"
		},
		IQAMAH: {
			text: "Sesungguhnya do'a yang tidak tertolak\nadalah do'a antara adzan dan iqomah,\nmaka berdo'alah.",
			src: 'HR. Ahmad 3/155'
		},
		PRAYER: {
			text: 'Luruskanlah shaf-shaf kalian,\nkarena lurusnya shaf termasuk\nbagian dari kesempurnaan shalat.',
			src: 'HR. Bukhari, no. 723 dan Muslim, no. 433'
		}
	};
</script>

{#snippet OverlayContainer(child: Snippet)}
	{#if eState !== 'IDLE'}
		<div
			class="animate-fadein absolute top-0 left-0 flex h-screen w-screen items-center justify-center bg-background"
		>
			<div
				class={cn(
					'flex h-full w-full items-center justify-center transition-all duration-5000',
					overlayMode === 'fadeout' ? 'bg-black' : 'bg-transparent'
				)}
			>
				{@render child()}
			</div>
		</div>
	{/if}
{/snippet}

{#snippet ShowTimer(title: string, count: number, text?: string, subtext?: string)}
	<div class="flex h-full w-full flex-col items-center justify-center">
		<div class="flex h-max w-max flex-col justify-center gap-4 text-center text-5xl font-bold">
			<span class="text-6xl font-bold uppercase">{title}</span>

			<FlipDisplay
				countMs={count}
				class={cn('mt-8 bg-emerald-800/80 shadow-lg')}
				containerClass="w-36 h-56 text-emerald-700"
				digitClass="ring-2 ring-primary"
				nonFlipClass="text-gray-100"
			/>

			{#if text && subtext}
				<div
					class="mt-4 flex h-full w-full flex-col justify-center gap-2 text-center whitespace-pre-wrap text-black/30 tv:gap-4"
				>
					<span class="text-4xl font-bold">{text}</span>
					<span class="text-2xl">{subtext}</span>
				</div>
			{/if}
		</div>
	</div>
{/snippet}

{#snippet ShowContent(title: string, text: string, subtext: string, mode: OverlayMode = 'default')}
	<div
		class={cn(
			'animate-fadein flex h-full w-full flex-col justify-center gap-4 text-center font-bold whitespace-pre-wrap',
			mode === 'fadeout' && 'animate-fadeout'
		)}
	>
		<span class="mb-6 text-7xl uppercase">{title}</span>
		<span class="mb-4 text-5xl">{text}</span>
		<span class="text-2xl">{subtext}</span>
	</div>
{/snippet}

{#snippet Current()}
	{#if eState === 'NOTICE'}
		{@render ShowContent(`Memasuki waktu ${ePrayer}`, '', '')}
	{:else if eState === 'COUNTDOWN'}
		{@render ShowTimer(`Menuju waktu ${ePrayer}`, remainingMs)}
	{:else if eState === 'ADHAN'}
		{@render ShowContent(`Adzan ${ePrayer}`, contents.ADHAN.text, contents.ADHAN.src)}
	{:else if eState === 'IQAMAH'}
		{@render ShowTimer(`Iqamah ${ePrayer}`, remainingMs, contents.IQAMAH.text, contents.IQAMAH.src)}
	{:else if eState === 'PRAYER'}
		{@render ShowContent('', contents.PRAYER.text, contents.PRAYER.src, 'fadeout')}
	{:else if eState === 'JUMUAH'}
		{@render ShowContent('', contents.JUMUAH.text, contents.JUMUAH.src, 'fadeout')}
	{/if}
{/snippet}

{@render OverlayContainer(Current)}
