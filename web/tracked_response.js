// BONK buffered Response fallback: embedded by patch_web_export.py.
async function getTrackedResponse(response, load_status) {
	const reader = response.body.getReader();
	const stream = new ReadableStream({
		async pull(controller) {
			try {
				const result = await reader.read();
				if (result.done) {
					load_status.done = true;
					reader.releaseLock();
					controller.close();
				} else {
					load_status.loaded += result.value.byteLength;
					controller.enqueue(result.value);
				}
			} catch (error) {
				controller.error(error);
			}
		},
		cancel(reason) { return reader.cancel(reason); },
	});
	// Plain header pairs also avoid passing a browser-specific Headers wrapper.
	const options = { headers: Array.from(response.headers.entries()) };
	try {
		return new Response(stream, options);
	} catch (error) {
		if (!(error instanceof TypeError)) throw error;
		// Some iPhone browser contexts reject a constructed stream as BodyInit.
		// Consume the same stream, preserving progress and network read failures.
		const chunks = [];
		const bufferedReader = stream.getReader();
		let length = 0;
		try {
			while (true) {
				const { value, done } = await bufferedReader.read();
				if (done) break;
				chunks.push(value);
				length += value.byteLength;
			}
		} finally {
			bufferedReader.releaseLock();
		}
		const bytes = new Uint8Array(length);
		let offset = 0;
		for (const chunk of chunks) {
			bytes.set(chunk, offset);
			offset += chunk.byteLength;
		}
		return new Response(bytes, options);
	}
}
