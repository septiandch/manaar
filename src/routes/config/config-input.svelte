<script lang="ts">
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { cn } from '$lib/utils/cn';
	import { Minus, Plus } from '@lucide/svelte';
	import type { ClassValue } from 'clsx';

	type StringType = {
		type: 'string';
		value: string;
	};

	type NumberType = {
		type: 'number';
		value: number;
		minValue?: number;
		withButton?: boolean;
	};

	type ImageType = {
		type: 'image';
		value?: File;
		src?: string;
	};

	type CommonType = { label: string; placeholder?: string; class?: ClassValue; disabled?: boolean };

	let {
		type = 'string',
		placeholder = '',
		value = $bindable(),
		label,
		class: className,
		disabled = false,
		...props
	}: (StringType | NumberType | ImageType) & CommonType = $props();

	const buttonStyle = cn(
		'flex items-center justify-center',
		'h-full w-16 rounded-md border border-primary bg-transparent text-xl font-bold text-primary hover:bg-primary/10',
		'disabled:hover:bg-transparent disabled:border-gray-300 disabled:text-gray-300'
	);

	function onimginput(e: Event) {
		const input = e.target as HTMLInputElement;

		if (input.files && input.files?.length > 0) {
			value = input.files[0];
		}
	}
</script>

<div class={cn('flex flex-col gap-2', className)}>
	<Label>{label}</Label>

	{#if type === 'image'}
		{@const { src } = props as ImageType}
		<div class="flex gap-2">
			{#if src}
				<img {src} alt="App Logo" class="h-20 w-auto rounded border bg-white p-2" />
			{/if}

			<Input {disabled} type="file" {placeholder} accept="image/*" onchange={onimginput} />
		</div>
	{:else if type === 'number'}
		{@const { withButton, minValue = 0 } = props as NumberType}
		<div class="flex gap-4">
			<Input {disabled} {type} bind:value {placeholder} />

			{#if withButton}
				<div class="flex gap-2">
					<button onclick={() => (value as number)++} class={buttonStyle}>
						<Plus class="h-4 w-4" />
					</button>

					<button
						disabled={(value as number) <= minValue}
						onclick={() => (value as number)--}
						class={buttonStyle}
					>
						<Minus class="h-4 w-4" />
					</button>
				</div>
			{/if}
		</div>
	{:else}
		<Input {disabled} bind:value {placeholder} />
	{/if}
</div>
