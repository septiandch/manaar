<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import { msToHms } from '@/utils/date-utils';
	import type { ClassValue } from 'clsx';
	import FlipDigit from './flip-digit.svelte';

	type PropsType = {
		countMs: number;
		class?: string;
		nonFlipClass?: ClassValue;
		containerClass?: ClassValue;
		digitClass?: ClassValue;
	};

	let { countMs, class: className, nonFlipClass, digitClass, containerClass }: PropsType = $props();

	let remainingHms = $derived(msToHms(countMs));
	let num = $derived(
		`${String(remainingHms.m).padStart(2, '0')}:${String(remainingHms.s).padStart(2, '0')}`
	);
</script>

<div
	class={cn(
		'm-auto flex w-max items-center justify-between gap-2 rounded-lg bg-gray-50 p-4 shadow-md',
		className
	)}
>
	{#each num.split('') as digit, idx (idx)}
		{#if digit !== ':'}
			<FlipDigit {digit} {containerClass} {digitClass} />
		{:else}
			<div
				class={cn(
					'perspective-500 relative h-max w-12 text-4xl font-bold text-gray-100',
					nonFlipClass
				)}
			>
				<span
					class="absolute inset-0 flex items-center justify-center rounded-md text-9xl text-shadow-sm"
				>
					{digit}
				</span>
			</div>
		{/if}
	{/each}
</div>
