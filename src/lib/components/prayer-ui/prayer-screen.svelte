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
	import type { Snippet } from 'svelte';
	import type { Readable } from 'svelte/store';

	type PropsType = {
		clockStore: Readable<Date>;
		prayerTimes: PrayerTimeType;
		config: PrayerConfig;
	};

	type OverlayMode = 'default' | 'fadeout';
	type TimerContent =
		| { variant: 'notification'; text: string }
		| { variant: 'hadith'; text: string; src: string };

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
	const VISIBLE_STATES: PrayerState[] = [
		'NOTICE',
		'COUNTDOWN',
		'ADHAN',
		'IQAMAH',
		'PRAYER',
		'JUMUAH'
	];
	const overlayMode = $derived(FADEOUT_STATE.includes(eState) ? 'fadeout' : 'default');
	const showOverlay = $derived(VISIBLE_STATES.includes(eState));

	let engine: PrayerEngine;

	function onEventChange(e: PrayerEventState) {
		eventState = e;

		if (e.state === 'ADHAN') {
			playBeep();
		}
	}

	$effect(() => {
		const activeEngine = createPrayerEngine(prayerTimes, config, onEventChange);
		engine = activeEngine;

		const unsub = clockStore.subscribe((clock) => {
			activeEngine.update(clock);
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
			src: 'HR. Abu Daud no.524 dan Ahmad 2:172'
		},
		JUMUAH: {
			text: 'Apabila dibacakan Al-Quran (khutbah),\nmaka dengarkanlah baik-baik,\ndan perhatikanlah dengan tenang\nagar kamu mendapat rahmat.\n',
			src: "QS. Al-A'raf: 204"
		},
		IQAMAH: {
			text: "Sesungguhnya do'a yang tidak tertolak\nadalah do'a antara adzan dan iqomah,\nmaka berdo'alah.",
			src: 'HR. Ahmad 3:155'
		},
		PRAYER: {
			text: 'Luruskanlah shaf-shaf kalian,\nkarena lurusnya shaf termasuk\nbagian dari kesempurnaan shalat.',
			src: 'HR. Bukhari, no.723 dan Muslim, no.433'
		}
	};
</script>

{#snippet OverlayContainer(child: Snippet)}
	{#if showOverlay}
		<div
			class="animate-fadein absolute top-0 left-0 flex h-screen w-screen items-center justify-center bg-black"
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

{#snippet ShowTimer(title: string, count: number, content: TimerContent)}
	{@const seconds = Math.ceil(Math.max(0, count) / 1000)}
	<div class="relative flex h-full w-full items-center overflow-hidden bg-black text-gray-400">
		<div class="relative z-[1] ml-[6%] w-[57%]">
			<p class="text-[clamp(1.15rem,4.1vw,5rem)] leading-[1.3] font-[750] text-pretty">
				{content.text}
			</p>
			{#if content.variant === 'hadith'}
				<p class="mt-[0.65em] text-[clamp(0.85rem,2.9vw,3rem)] leading-[1.4]">{content.src}</p>
			{/if}
		</div>
		<div
			class="pointer-events-none absolute top-1/2 left-[63%] h-[240vh] w-[240vh] -translate-y-1/2 opacity-85"
			aria-hidden="true"
		>
			<svg
				viewBox="0 0 1000 1000"
				class="h-full w-full [transform:rotate(var(--tick-angle))] transition-transform duration-[120ms] ease-out motion-reduce:transform-none motion-reduce:transition-none"
				style:--tick-angle={`${-seconds * 6}deg`}
			>
				{#each Array(120) as _, index}
					<line
						x1="20"
						y1="500"
						x2={index % 5 === 0 ? 50 : 43}
						y2="500"
						transform={`rotate(${index * 3} 500 500)`}
						stroke="currentColor"
						stroke-width="1.5"
						stroke-linecap="round"
					/>
				{/each}
			</svg>
		</div>
		<div
			class="absolute right-[4%] z-1 text-[clamp(1.05rem,6.3vw,8rem)] font-[750] tracking-[0.025em] whitespace-nowrap tabular-nums"
			role="timer"
			aria-label={title}
		>
			<span class="sr-only">{title}: </span>
			<span
				>{String(Math.floor(seconds / 60)).padStart(2, '0')} : {String(seconds % 60).padStart(
					2,
					'0'
				)}</span
			>
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
		<span class="mb-4 text-6xl leading-[1.3]">{text}</span>
		<span class="text-2xl">{subtext}</span>
	</div>
{/snippet}

{#snippet Current()}
	{#if eState === 'NOTICE'}
		{@render ShowContent(`Memasuki waktu ${ePrayer}`, '', '')}
	{:else if eState === 'COUNTDOWN'}
		{@render ShowTimer(`Menuju waktu ${ePrayer}`, remainingMs, {
			variant: 'notification',
			text: `Menuju waktu ${ePrayer}`
		})}
	{:else if eState === 'ADHAN'}
		{@render ShowContent(`Adzan ${ePrayer}`, contents.ADHAN.text, contents.ADHAN.src)}
	{:else if eState === 'IQAMAH'}
		{@render ShowTimer(`Iqamah ${ePrayer}`, remainingMs, {
			variant: 'hadith',
			...contents.IQAMAH
		})}
	{:else if eState === 'PRAYER'}
		{@render ShowContent('', contents.PRAYER.text, contents.PRAYER.src, 'fadeout')}
	{:else if eState === 'JUMUAH'}
		{@render ShowContent('', contents.JUMUAH.text, contents.JUMUAH.src, 'fadeout')}
	{/if}
{/snippet}

{@render OverlayContainer(Current)}
