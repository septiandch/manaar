import { readable } from 'svelte/store';

type ClockOptions = {
	startTime?: Date;
	speed?: number; // 1 = normal, 60 = 1 minute per second
};

function createClock(options: ClockOptions = {}) {
	let { startTime = new Date(), speed = 1 } = options;

	let baseTime = startTime.getTime();
	let realStart = Date.now();

	return readable(new Date(baseTime), (set) => {
		const interval = setInterval(() => {
			const elapsedReal = Date.now() - realStart;
			const simulatedTime = baseTime + elapsedReal * speed;

			set(new Date(simulatedTime));
		}, 1000);

		return () => clearInterval(interval);
	});
}

/* ---------------- PUBLIC CLOCK ---------------- */

export const clock = createClock();

/* ---------------- DEBUG CLOCK ---------------- */

export function createDebugClock(startTime: Date, speed = 1) {
	return createClock({ startTime, speed });
}

export const debugClock = createDebugClock(
	//new Date(),
	new Date('2026-09-19T11:46:52'),
	1 // 1 real second = 1 simulated minute
);
