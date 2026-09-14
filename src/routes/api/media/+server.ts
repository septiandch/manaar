// src/routes/api/media/+server.ts
import { json } from '@sveltejs/kit';
import fs from 'fs/promises';
import path from 'path';
import { isSafeMediaFilename, resolveMediaPath } from '$lib/utils/media-path';
import { _notify } from '../events/+server';

const UPLOAD_DIR = path.resolve('static/uploads');
const ORDER_FILE = path.join(UPLOAD_DIR, 'order.json');

// Allowed file extensions (basic safety)
const ALLOWED_EXT = /\.(jpg|jpeg|png|webp|mp4|webm)$/i;

// Max file size: 200 MB (adjust if needed)
const MAX_FILE_SIZE = 200 * 1024 * 1024;

async function getAvailableFilename(dir: string, originalName: string): Promise<string> {
	const ext = path.extname(originalName);
	const base = path.basename(originalName, ext);

	let candidate = `${base}${ext}`;
	let counter = 1;

	while (true) {
		try {
			await fs.access(path.join(dir, candidate));
			// file exists → try next
			candidate = `${base}_copy_${counter}${ext}`;
			counter++;
		} catch {
			// file does not exist → safe to use
			return candidate;
		}
	}
}

export async function GET() {
	await fs.mkdir(UPLOAD_DIR, { recursive: true });
	const files = await fs.readdir(UPLOAD_DIR);

	let order: string[] = [];

	try {
		order = JSON.parse(await fs.readFile(ORDER_FILE, 'utf-8'));
	} catch {
		order = files.filter(isSafeMediaFilename);
	}

	const media = order
		.filter((f) => isSafeMediaFilename(f) && files.includes(f))
		.map((f) => ({
			name: f,
			url: `/uploads/${f}`,
			type: /\.(mp4|webm)$/i.test(f) ? 'video' : 'image'
		}));

	return json(media);
}

export async function POST({ request }) {
	// Ensure upload directory exists
	await fs.mkdir(UPLOAD_DIR, { recursive: true });

	const form = await request.formData();
	const files = form.getAll('files');

	if (!files.length) {
		return json({ error: 'No files uploaded' }, { status: 400 });
	}

	// Load existing order
	let order: string[] = [];
	try {
		const data = await fs.readFile(ORDER_FILE, 'utf-8');
		order = (JSON.parse(data) as unknown[]).filter(isSafeMediaFilename);
	} catch {
		// order.json does not exist yet
	}

	const savedFiles: string[] = [];

	for (const file of files) {
		if (!(file instanceof File)) continue;

		// Validate extension
		if (!ALLOWED_EXT.test(file.name)) {
			continue;
		}

		// Validate size
		if (file.size > MAX_FILE_SIZE) {
			continue;
		}

		// Sanitize filename
		const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
		const finalName = await getAvailableFilename(UPLOAD_DIR, safeName);
		const filepath = path.join(UPLOAD_DIR, finalName);

		// Write file
		const buffer = Buffer.from(await file.arrayBuffer());
		await fs.writeFile(filepath, buffer);

		// Append to order if new
		if (!order.includes(finalName)) {
			order.push(finalName);
		}

		savedFiles.push(finalName);
	}

	// Save updated order
	await fs.writeFile(ORDER_FILE, JSON.stringify(order, null, 2));

	_notify();

	return json({
		success: true,
		files: savedFiles
	});
}

export async function PATCH({ request }) {
	const order = await request.json();

	if (!Array.isArray(order) || !order.every(isSafeMediaFilename)) {
		return json({ error: 'Invalid order' }, { status: 400 });
	}

	await fs.mkdir(UPLOAD_DIR, { recursive: true });
	await fs.writeFile(ORDER_FILE, JSON.stringify(order, null, 2));
	_notify();

	return json({ success: true });
}

export async function DELETE({ request }) {
	const { filename } = await request.json();

	if (!filename) {
		return json({ error: 'Missing filename' }, { status: 400 });
	}

	const filePath = resolveMediaPath(UPLOAD_DIR, filename);
	if (!filePath) {
		return json({ error: 'Invalid filename' }, { status: 400 });
	}

	// Delete file (ignore if already gone)
	try {
		await fs.unlink(filePath);
	} catch {}

	// Clean order.json
	try {
		const data = await fs.readFile(ORDER_FILE, 'utf-8');
		const order: string[] = (JSON.parse(data) as unknown[]).filter(
			(f): f is string => typeof f === 'string' && f !== filename
		);

		await fs.writeFile(ORDER_FILE, JSON.stringify(order, null, 2));
	} catch {}

	_notify();

	return json({ success: true });
}
