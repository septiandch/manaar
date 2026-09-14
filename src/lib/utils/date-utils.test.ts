import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import { formatHHmm, msToHms, parseHms } from './date-utils.ts';

describe('date utilities', () => {
	test('formats local hours and minutes with two digits', () => {
		assert.equal(formatHHmm(new Date(2026, 0, 1, 4, 5)), '04:05');
	});

	test('parses and pads each time component', () => {
		assert.deepEqual(parseHms(new Date(2026, 0, 1, 4, 5, 6), 2), {
			h: '04',
			m: '05',
			s: '06'
		});
	});

	test('converts milliseconds and clamps negative values', () => {
		assert.deepEqual(msToHms(3_661_999), { h: 1, m: 1, s: 1 });
		assert.deepEqual(msToHms(-1), { h: 0, m: 0, s: 0 });
	});
});
