import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import { toHijri } from './toHijri.ts';

describe('Hijri date boundaries', () => {
	test('uses the same Hijri day throughout one local civil day', () => {
		const early = toHijri(new Date(2026, 7, 28, 1));
		const noon = toHijri(new Date(2026, 7, 28, 12));
		assert.deepEqual(early, noon);
	});

	test('advances at Maghrib when a Maghrib time is supplied', () => {
		const maghrib = new Date(2026, 7, 28, 18);
		const before = toHijri(new Date(2026, 7, 28, 17, 59), 0, maghrib);
		const after = toHijri(maghrib, 0, maghrib);
		const tomorrow = toHijri(new Date(2026, 7, 29, 12));
		assert.notDeepEqual(before, after);
		assert.deepEqual(after, tomorrow);
	});

	test('applies manual day adjustment', () => {
		const date = new Date(2026, 7, 28, 12);
		assert.deepEqual(toHijri(date, 1), toHijri(new Date(2026, 7, 29, 12)));
	});
});
