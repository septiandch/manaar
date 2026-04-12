export function formatHHmm(date: Date) {
	const h = String(date.getHours()).padStart(2, '0');
	const m = String(date.getMinutes()).padStart(2, '0');
	return `${h}:${m}`;
}

export function parseHms(date: Date, pad: number = 0) {
	const h = String(date.getHours()).padStart(pad, '0');
	const m = String(date.getMinutes()).padStart(pad, '0');
	const s = String(date.getSeconds()).padStart(pad, '0');

	return { h, m, s };
}

export function msToHms(ms: number): { h: number; m: number; s: number } {
	const totalSeconds = Math.max(0, Math.floor(ms / 1000));

	const h = Math.floor(totalSeconds / 3600);
	const m = Math.floor((totalSeconds % 3600) / 60);
	const s = totalSeconds % 60;

	return { h, m, s };
}
