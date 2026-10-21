const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../web/tracked_response.js'), 'utf8');

(async () => {
  for (const rejectStreams of [false, true]) {
    const CompatibleResponse = new Proxy(Response, {
      construct(target, args) {
        if (rejectStreams && args[0] instanceof ReadableStream) throw new TypeError('Type error');
        return Reflect.construct(target, args);
      },
    });
    const context = vm.createContext({ Response: CompatibleResponse, ReadableStream, TypeError, Uint8Array });
    vm.runInContext(source, context);
    const status = { loaded: 0, total: 0, done: false };
    const network = new Response(new ReadableStream({
      start(controller) {
        controller.enqueue(new Uint8Array([0, 97, 115, 109]));
        controller.enqueue(new Uint8Array([1, 0, 0, 0]));
        controller.close();
      },
    }), { headers: { 'Content-Type': 'application/wasm' } });
    const result = await context.getTrackedResponse(network, status);
    assert.equal(result.headers.get('content-type'), 'application/wasm');
    const bytes = await result.arrayBuffer();
    assert.deepEqual([...new Uint8Array(bytes)], [0, 97, 115, 109, 1, 0, 0, 0]);
    assert.equal(status.loaded, 8);
    assert.equal(status.done, true);
    await WebAssembly.compile(bytes);

    const failureStatus = { loaded: 0, done: false };
    const failedNetwork = new Response(new ReadableStream({
      pull(controller) { controller.error(new Error('Download disconnected')); },
    }));
    await assert.rejects(async () => {
      const failed = await context.getTrackedResponse(failedNetwork, failureStatus);
      await failed.arrayBuffer();
    }, /Download disconnected/);
    assert.equal(failureStatus.done, false);
    console.log(`${rejectStreams ? 'Buffered fallback' : 'Streaming'}: byte integrity, progress, WASM compilation, and read failures passed.`);
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
