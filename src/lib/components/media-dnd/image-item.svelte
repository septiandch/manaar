<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import type { CarouselMediaType } from '@/components/ui/carousel';
	import { GripVertical, X, Download } from '@lucide/svelte';

	type Props = {
		item: CarouselMediaType;
		onremove: (name: string) => void;
	};

	let { item, onremove }: Props = $props();
</script>

<div
	class="flex items-center justify-between rounded-lg border bg-input p-2 ring ring-transparent hover:ring-primary"
>
	<div class="flex flex-1 items-center gap-4">
		<span class="ml-3 cursor-grab text-muted-foreground select-none" data-dnd-handle>
			<GripVertical />
		</span>

		<div class="flex flex-col items-start gap-2 sm:flex-row sm:items-center sm:gap-4">
			{#if item.type === 'image'}
				<img
					src={item.url}
					alt={item.name}
					class="ml-3 h-24 w-24 rounded border object-cover"
					loading="lazy"
				/>
			{:else}
				<video src={item.url} class="ml-3 h-24 w-24 rounded border object-cover" muted playsinline>
				</video>
			{/if}

			<span class="ml-2 max-w-44 truncate">{item.name}</span>
		</div>
	</div>

	<div class="flex flex-col justify-between gap-2">
		<Button size="sm" variant="outline" class="h-8">
			<Download />
			<a href={item.url} download={item.name}> Download </a>
		</Button>

		<Button
			variant="outline"
			class="h-8 border-red-500 text-red-500 hover:bg-red-500/10 hover:text-red-500"
			size="sm"
			onclick={() => onremove(item.name)}
		>
			<X /> Delete
		</Button>
	</div>
</div>
