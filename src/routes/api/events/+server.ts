const clients = new Set<ReadableStreamDefaultController>();

export function GET() {
	let controllerRef: ReadableStreamDefaultController;

	const stream = new ReadableStream({
		start(controller) {
			controllerRef = controller;
			clients.add(controller);

			controller.enqueue(new TextEncoder().encode(': connected\n\n'));
		},
		cancel() {
			clients.delete(controllerRef);
		}
	});

	return new Response(stream, {
		headers: {
			'Content-Type': 'text/event-stream',
			'Cache-Control': 'no-cache',
			Connection: 'keep-alive'
		}
	});
}

const encoder = new TextEncoder();

export function _notify() {
	for (const client of clients) {
		try {
			client.enqueue(encoder.encode(`event: update\ndata: reload\n\n`));
		} catch {
			clients.delete(client);
		}
	}
}
