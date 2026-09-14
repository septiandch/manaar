import path from 'node:path';

const MEDIA_EXTENSION = /\.(jpg|jpeg|png|webp|mp4|webm)$/i;

export function isSafeMediaFilename(filename: unknown): filename is string {
	return (
		typeof filename === 'string' &&
		filename.length > 0 &&
		filename !== 'order.json' &&
		path.basename(filename) === filename &&
		MEDIA_EXTENSION.test(filename)
	);
}

export function resolveMediaPath(uploadDir: string, filename: unknown): string | null {
	if (!isSafeMediaFilename(filename)) return null;
	return path.join(uploadDir, filename);
}
