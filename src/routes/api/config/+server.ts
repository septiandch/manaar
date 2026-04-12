import { json } from '@sveltejs/kit';
import fs from 'fs/promises';
import path from 'path';
import { _notify } from '../events/+server';
import type { RequestHandler } from './$types';

const DATA_DIR = path.resolve('data');
const UPLOAD_DIR = path.resolve('static/uploads');
const CONFIG_FILE = path.join(DATA_DIR, 'config.json');

async function ensureDirs() {
	await fs.mkdir(DATA_DIR, { recursive: true });
	await fs.mkdir(UPLOAD_DIR, { recursive: true });
}

function isNumeric(value: any): boolean {
	if (typeof value === 'string') {
		return /^-?\d+(\.\d+)?$/.test(value);
	} else {
		return false;
	}
}

/* ───────────── GET CONFIG ───────────── */
export const GET: RequestHandler = async () => {
	try {
		const data = await fs.readFile(CONFIG_FILE, 'utf-8');
		return json(JSON.parse(data));
	} catch {
		return json(null);
	}
};

/* ───────────── SAVE CONFIG ───────────── */
export const POST: RequestHandler = async ({ request }) => {
	await ensureDirs();

	const form = await request.formData();
	const data: Record<string, any> = {};

	// ───── Load existing config ─────
	let existing: any = {};
	try {
		const raw = await fs.readFile(CONFIG_FILE, 'utf-8');
		existing = JSON.parse(raw);
	} catch {}

	for (const [key, value] of form.entries()) {
		// ───── Handle File ─────
		if (value instanceof File) {
			// If no file uploaded, keep existing value
			if (value.size === 0) {
				data[key] = existing[key] ?? null;
				continue;
			}

			const ext = path.extname(value.name);
			const fileName = `${key}${ext}`; // use field name as file name
			const filePath = path.join(UPLOAD_DIR, fileName);

			const buffer = Buffer.from(await value.arrayBuffer());
			await fs.writeFile(filePath, buffer);

			data[key] = `/uploads/${fileName}`;
		}
		// ───── Handle Text ─────
		else if (typeof value === 'string') {
			data[key] = isNumeric(value) ? Number(value) : value;
		}
	}

	const payload = {
		...existing,
		...data,
		updatedAt: new Date().toISOString()
	};

	await fs.writeFile(CONFIG_FILE, JSON.stringify(payload, null, 2));

	_notify();

	return json({ success: true, data: payload });
};
