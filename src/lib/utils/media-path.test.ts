import assert from 'node:assert/strict';
import path from 'node:path';
import { describe, test } from 'node:test';
import { isSafeMediaFilename, resolveMediaPath } from './media-path.ts';

describe('media path validation', () => {
	test('accepts a plain media filename', () => {
		assert.equal(isSafeMediaFilename('slideshow-1.webp'), true);
		assert.equal(resolveMediaPath('uploads', 'slideshow-1.webp'), path.join('uploads', 'slideshow-1.webp'));
	});

	test('rejects traversal, nested paths, reserved metadata, and non-strings', () => {
		for (const value of [
			'../config.json',
			'..\\config.json',
			'folder/image.jpg',
			'order.json',
			'logo.svg',
			'',
			null
		]) {
			assert.equal(isSafeMediaFilename(value), false);
			assert.equal(resolveMediaPath('uploads', value), null);
		}
	});
});
