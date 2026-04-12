import { getPrayerTimes } from '$lib/utils/prayer-engine';
import { readable, type Readable } from 'svelte/store';

export function createPrayerStore(clock: Readable<Date>, latitude: number, longitude: number) {
	return readable(getPrayerTimes(new Date(), latitude, longitude), (set) => {
		let currentDay: number | null = null;

		const unsubscribe = clock.subscribe((now) => {
			const today = now.getDate();

			if (currentDay === null) {
				currentDay = today;
				set(getPrayerTimes(now, latitude, longitude));
				return;
			}

			if (today !== currentDay) {
				currentDay = today;
				set(getPrayerTimes(now, latitude, longitude));
			}
		});

		return unsubscribe;
	});
}
