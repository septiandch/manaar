import type { ConfigType } from '$lib/types/config';
import type { CarouselMediaType } from '@/components/ui/carousel';

export async function load({ fetch }) {
	let media: CarouselMediaType[] = [];
	let config: ConfigType;

	let res = await fetch('/api/config');
	config = (await res.json()) as ConfigType;

	res = await fetch('/api/media');
	media = (await res.json()) as CarouselMediaType[];

	return {
		...config,
		media
	};
}
