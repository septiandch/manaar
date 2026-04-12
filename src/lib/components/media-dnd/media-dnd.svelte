<script lang="ts">
	import ImageItem from '@/components/media-dnd/image-item.svelte';
	import type { CarouselMediaType } from '@/components/ui/carousel';
	import { dndzone } from 'svelte-dnd-action';
	import { flip } from 'svelte/animate';
	import { cubicOut } from 'svelte/easing';

	type PropsType = {
		media: CarouselMediaType[];
		onchange: () => void;
		onremove: (name: string) => void;
	};

	let { media = $bindable(), onchange, onremove }: PropsType = $props();
</script>

<div
	use:dndzone={{ items: media, flipDurationMs: 0 }}
	onconsider={(e) => (media = e.detail.items)}
	onfinalize={(e) => {
		media = e.detail.items;
		onchange();
	}}
	class="flex flex-col gap-4"
>
	{#each media as item (item.id)}
		<div animate:flip={{ duration: 100, easing: cubicOut }}>
			<ImageItem {item} {onremove} />
		</div>
	{/each}
</div>
