<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import type { ClassValue } from 'clsx';
	import { toHijri } from './toHijri';

	type PropsType = {
		now: Date;
		adjustment?: number;
		maghribTime?: Date;
		class?: ClassValue;
	};

	let { now, adjustment = 0, maghribTime, class: className }: PropsType = $props();

	const hijri = $derived(toHijri(now, adjustment, maghribTime));
</script>

<span class={cn(className)}>
	{hijri.day}
	{hijri.monthName}
	{hijri.year} H
</span>
