// BONK byte loader v3: embedded by patch_web_export.py.
// Return bytes directly; never construct a Response, Headers, or ReadableStream.
async function getTrackedResponse(response, load_status) {
    if (!response.body || typeof response.body.getReader !== 'function') {
        const buffer = await response.arrayBuffer();
        load_status.loaded = buffer.byteLength;
        load_status.done = true;
        return buffer;
    }
    const reader = response.body.getReader();
    const chunks = [];
    let length = 0;
    try {
        while (true) {
            const { value, done } = await reader.read();
            if (done) break;
            chunks.push(value);
            length += value.byteLength;
            load_status.loaded = length;
        }
    } finally {
        reader.releaseLock();
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (let i = 0; i < chunks.length; i++) {
        bytes.set(chunks[i], offset);
        offset += chunks[i].byteLength;
        chunks[i] = null;
    }
    load_status.done = true;
    return bytes.buffer;
}
