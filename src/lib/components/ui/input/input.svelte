<script lang="ts">
	import { cn, type WithElementRef } from '$lib/utils/cn.js';
	import type { HTMLInputAttributes, HTMLInputTypeAttribute } from 'svelte/elements';

	type InputType = Exclude<HTMLInputTypeAttribute, 'file'>;

	type Props = WithElementRef<
		Omit<HTMLInputAttributes, 'type'> &
			({ type: 'file'; files?: FileList } | { type?: InputType; files?: undefined })
	>;

	let {
		ref = $bindable(null),
		value = $bindable(),
		type,
		files = $bindable(),
		class: className,
		'data-slot': dataSlot = 'input',
		...restProps
	}: Props = $props();

	function onclick() {
		if (type === 'file') {
			ref?.click();
		}
	}

	function getFileLabel(defaultLabel?: string) {
		if (type === 'file') {
			const refValue = (ref as HTMLInputElement | null)?.value;
			const fileName = files?.[0]?.name || undefined;

			return refValue || fileName || defaultLabel || 'Choose file';
		}
	}
</script>

{#if type === 'file'}
	<input
		bind:this={ref}
		data-slot={dataSlot}
		type="file"
		hidden
		bind:files
		bind:value
		{...restProps}
	/>

	<button
		class={cn(
			'rounded-md border border-border bg-input',
			'flex h-9 w-full min-w-0 px-3 pt-1.5 text-sm text-input-foreground',
			'shadow-xs ring-offset-background transition-[color,box-shadow] outline-none',
			'selection:bg-input selection:text-input-foreground placeholder:text-muted',
			'disabled:cursor-not-allowed disabled:opacity-50',
			'dark:bg-input/30 dark:aria-invalid:ring-destructive/40',
			'focus-visible:ring- focus-visible:border-ring focus-visible:ring-ring/50',
			'aria-invalid:border-destructive aria-invalid:ring-destructive/20',
			className
		)}
		{onclick}
	>
		<span>{getFileLabel()}</span>
	</button>
{:else if type === 'number'}
	<input
		bind:this={ref}
		data-slot={dataSlot}
		class={cn(
			'flex h-9 w-full min-w-0 flex-1 rounded-md border border-border bg-input px-3 py-1 text-base text-input-foreground shadow-xs ring-offset-background transition-[color,box-shadow] outline-none selection:bg-primary selection:text-primary-foreground placeholder:text-muted disabled:cursor-not-allowed disabled:opacity-50 md:text-sm dark:bg-input/30',
			'focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50',
			'aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40',
			className
		)}
		{type}
		bind:value
		{...restProps}
	/>
{:else}
	<input
		bind:this={ref}
		data-slot={dataSlot}
		class={cn(
			'flex h-9 w-full min-w-0 rounded-md border border-border bg-input px-3 py-1 text-base text-input-foreground shadow-xs ring-offset-background transition-[color,box-shadow] outline-none selection:bg-primary selection:text-primary-foreground placeholder:text-muted disabled:cursor-not-allowed disabled:opacity-50 md:text-sm dark:bg-input/30',
			'focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50',
			'aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40',
			className
		)}
		{type}
		bind:value
		{...restProps}
	/>
{/if}
