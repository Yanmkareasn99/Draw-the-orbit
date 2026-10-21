const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../web/tracked_response.js'), 'utf8');

(async () => {
  for (const rejectAll of [false, true]) {
    const CompatibleResponse = new Proxy(Response, {
      construct(target, args) {
        if (rejectAll) throw new TypeError('Type error');
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
    const bytes = await context.getTrackedResponse(network, status);
    assert.deepEqual([...new Uint8Array(bytes)], [0, 97, 115, 109, 1, 0, 0, 0]);
    assert.equal(status.loaded, 8);
    assert.equal(status.done, true);
    await WebAssembly.compile(bytes);

    const failureStatus = { loaded: 0, done: false };
    const failedNetwork = new Response(new ReadableStream({
      pull(controller) { controller.error(new Error('Download disconnected')); },
    }));
    await assert.rejects(async () => {
      await context.getTrackedResponse(failedNetwork, failureStatus);
    }, /Download disconnected/);
    assert.equal(failureStatus.done, false);
    const noStreamStatus = { loaded: 0, done: false };
    const noStream = await context.getTrackedResponse({ body: null, arrayBuffer: async () => bytes }, noStreamStatus);
    assert.equal(noStream.byteLength, 8);
    assert.equal(noStreamStatus.done, true);
    console.log(`${rejectAll ? 'Response constructor disabled' : 'Normal browser'}: byte integrity, progress, WASM compilation, and read failures passed.`);
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
