<script lang="ts">
	import * as Carousel from '$lib/components/ui/carousel';
	import { cn } from '$lib/utils/cn';
	import type { ClassValue } from 'clsx';
	import Autoplay from 'embla-carousel-autoplay';

	type PropsType = { media: Carousel.CarouselMediaType[]; delay?: number; class?: ClassValue };

	let { media, class: className, delay = 5000 }: PropsType = $props();
</script>

<Carousel.Root
	class={cn('h-full w-full', className)}
	opts={{ loop: true }}
	plugins={[Autoplay({ delay })]}
>
	<Carousel.Content>
		{#each media as item, index}
			<Carousel.Item class="p-0">
				{#if item.type === 'image'}
					<img alt={'slideshow_' + index} src={item.url} class="h-full w-full object-cover" />
				{:else}
					<video src={item.url} autoplay muted playsinline class="max-h-full max-w-full"></video>
				{/if}
			</Carousel.Item>
		{/each}
	</Carousel.Content>
</Carousel.Root>
