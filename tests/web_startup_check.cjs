// Run with Playwright installed. BROWSER_ENGINE=webkit exercises real WebKit.
const { chromium, webkit } = require('playwright');
const { PNG } = require('pngjs');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const exported = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const config = JSON.parse(exported.match(/config = (\{[^\n]+\});/)[1]);
const engineURL = exported.match(/<script src="([^"]+)"/)[1];
const template = fs.readFileSync(path.join(root, 'web/mobile_shell.html'), 'utf8')
  .replace('$GODOT_HEAD_INCLUDE', '')
  .replace('$GODOT_CONFIG', JSON.stringify(config))
  .replace('$GODOT_URL', engineURL)
  .replace('$GODOT_THREADS_ENABLED', 'false');
const types = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const filename = path.resolve(root, '.' + (url === '/' ? '/index.html' : url));
  if (!filename.startsWith(root + path.sep) || !fs.existsSync(filename) || !fs.statSync(filename).isFile()) {
    res.writeHead(404).end(); return;
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(filename)] || 'application/octet-stream' });
  fs.createReadStream(filename).pipe(res);
});
const mockEngine = `class Engine {
  static getMissingFeatures() { return []; }
  startGame(options) {
    window.testOptions = options;
    return new Promise((resolve, reject) => {
      window.finishStartup = resolve;
      window.failStartup = reject;
    });
  }
}`;
const opaqueError = () => window.dispatchEvent(new ErrorEvent('error', { message: 'Script error.' }));
const walletError = () => {
  const error = new TypeError("undefined is not an object (evaluating 'window.ethereum.selectedAddress = undefined')");
  error.stack = `global code@${location.href}:1:16`;
  window.dispatchEvent(new ErrorEvent('error', {
    message: error.message, error, filename: location.href, lineno: 1, colno: 16,
  }));
};

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  const browser = process.env.BROWSER_ENGINE === 'webkit'
    ? await webkit.launch({ headless: true })
    : await chromium.launch({ channel: process.env.BROWSER_CHANNEL || 'msedge', headless: true, args: ['--enable-unsafe-swiftshader'] });
  try {
    for (const [name, html] of [['export', exported], ['template', template]]) {
      const page = await browser.newPage({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
      await page.clock.install();
      await page.route(origin + '/', route => route.fulfill({ contentType: 'text/html', body: html }));
      await page.route('**/*.js', route => route.fulfill({ contentType: 'application/javascript', body: mockEngine }));
      async function reload() {
        await page.goto(origin);
        await page.waitForFunction(() => typeof window.finishStartup === 'function');
      }
      await reload();
      await page.evaluate(opaqueError);
      await page.evaluate(walletError);
      assert.equal(await page.locator('#copy-debug').isVisible(), false, `${name}: anonymous error is not a failure`);
      await page.evaluate(() => window.finishStartup());
      await page.locator('#status').waitFor({ state: 'hidden' });
      await page.evaluate(opaqueError);
      await page.evaluate(walletError);
      assert.equal(await page.locator('#status').isVisible(), false, `${name}: late browser errors cannot cover the game`);
      await page.clock.fastForward(120001);
      assert.equal(await page.locator('#status').isVisible(), false, `${name}: success cancels the watchdog`);

      await reload();
      await page.evaluate(opaqueError);
      await page.evaluate(walletError);
      await page.evaluate(() => window.dispatchEvent(new PromiseRejectionEvent('unhandledrejection', {
        promise: Promise.resolve(),
        reason: new TypeError("undefined is not an object (evaluating 'window.ethereum.selectedAddress = undefined')"),
      })));
      assert.equal(await page.locator('#copy-debug').isVisible(), false, `${name}: injected wallet errors do not block startup`);
      await page.evaluate(() => {
        window.testOptions.onPrintError('Engine diagnostic: could not initialize');
        window.failStartup(new Error('Actual WASM startup failure'));
      });
      await page.locator('#copy-debug').waitFor({ state: 'visible' });
      const failure = await page.locator('#notice').innerText();
      assert.match(failure, /Message: Actual WASM startup failure/);
      assert.match(failure, /Engine diagnostic: could not initialize/);
      assert.match(failure, /Unattributed browser errors:\nScript error\./);
      assert.match(failure, /window\.ethereum\.selectedAddress/, 'Wallet errors remain available in diagnostics');

      await reload();
      await page.evaluate(() => window.dispatchEvent(new ErrorEvent('error', {
        message: 'Engine runtime failure', filename: location.href, lineno: 10,
        error: new Error('Engine runtime failure'),
      })));
      await page.evaluate(() => window.finishStartup());
      await page.setViewportSize({ width: 400, height: 850 });
      assert.equal(await page.locator('#copy-debug').isVisible(), true, `${name}: real errors remain visible`);
      assert.equal(await page.locator('#rotate').isVisible(), false, `${name}: rotation cannot hide the diagnostic`);

      await reload();
      await page.evaluate(opaqueError);
      await page.clock.fastForward(119000);
      await page.evaluate(() => window.testOptions.onProgress(10, 100));
      await page.clock.fastForward(119000);
      assert.equal(await page.locator('#copy-debug').isVisible(), false, `${name}: download progress extends the watchdog`);
      await page.clock.fastForward(1001);
      assert.match(await page.locator('#notice').innerText(), /startup stopped responding/);

      await reload();
      await page.evaluate(() => window.failStartup('Script error.'));
      await page.locator('#copy-debug').waitFor({ state: 'visible' });
      assert.match(await page.locator('#notice').innerText(), /Message: Script error\./,
        `${name}: an explicit engine rejection is always reported`);

      await reload();
      await page.evaluate(() => window.failStartup(new TypeError(
        "undefined is not an object (evaluating 'window.ethereum.selectedAddress = undefined')")));
      await page.locator('#copy-debug').waitFor({ state: 'visible' });
      assert.match(await page.locator('#notice').innerText(), /Message:.*window\.ethereum/,
        `${name}: engine rejections bypass the browser-only wallet filter`);
      await page.close();
      console.log(`${name}: startup error classification, engine diagnostics, and watchdog checks passed.`);
    }

    // Use the actual exported engine and pack, with no mocks or clock overrides.
    const page = await browser.newPage({ viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
    if (process.env.REJECT_STREAM_RESPONSE === '1' || process.env.REJECT_ALL_RESPONSES === '1') {
      const rejectAll = process.env.REJECT_ALL_RESPONSES === '1';
      await page.addInitScript(rejectAll => {
        const NativeResponse = window.Response;
        window.rejectedStreamResponses = 0;
        window.Response = new Proxy(NativeResponse, {
          construct(target, args) {
            if (rejectAll || (args[0] && typeof args[0].getReader === 'function')) {
              window.rejectedStreamResponses++;
              throw new TypeError('Type error');
            }
            return Reflect.construct(target, args);
          },
        });
      }, rejectAll);
    }
    const errors = [];
    const graphicsMessages = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (message.type() !== 'error') return;
      if (message.text().startsWith('WebGL:')) graphicsMessages.push(message.text());
      else errors.push(message.text());
    });
    await page.goto(origin);
    await page.waitForFunction(() => document.getElementById('status').hidden ||
      document.getElementById('copy-debug').classList.contains('visible'), null, { timeout: 45000 });
    assert.equal(await page.locator('#status').isVisible(), false, await page.locator('#notice').innerText());
    if (process.env.REJECT_STREAM_RESPONSE === '1' || process.env.REJECT_ALL_RESPONSES === '1') {
      assert.equal(await page.evaluate(() => window.rejectedStreamResponses), 0, 'The loader never constructs a Response');
    }
    await page.evaluate(opaqueError);
    await page.evaluate(walletError);
    assert.equal(await page.locator('#status').isVisible(), false);
    const bounds = await page.locator('#canvas').boundingBox();
    const scale = Math.min(bounds.width / 440, bounds.height / 680);
    const playHeight = Math.max(44, Math.min(68, 56 * scale));
    await page.touchscreen.tap(bounds.x + bounds.width / 2,
      bounds.y + bounds.height / 2 + 198 * scale + playHeight / 2);
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    const png = PNG.sync.read(await page.locator('#canvas').screenshot({ scale: 'css' }));
    const pixel = (x, y) => [...png.data.subarray((y * png.width + x) * 4, (y * png.width + x) * 4 + 3)];
    assert.deepEqual(pixel(1, 1), [25, 33, 62], 'Touch Play renders the gameplay arena');
    assert.deepEqual(pixel(1, png.height - 2), [16, 23, 46], 'Touch Play renders the game toolbar');
    for (const size of [{ width: 390, height: 700 }, { width: 844, height: 300 }]) {
      await page.setViewportSize(size);
      await page.waitForFunction(({ width, height }) => {
        const canvas = document.getElementById('canvas');
        return canvas.width === width * 2 && canvas.height === height * 2;
      }, size);
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      const frame = PNG.sync.read(await page.locator('#canvas').screenshot({ scale: 'css' }));
      const rgb = (x, y) => [...frame.data.subarray((y * frame.width + x) * 4, (y * frame.width + x) * 4 + 3)];
      assert.deepEqual(rgb(1, 1), [25, 33, 62], 'Rotated arena reaches top edge without black bars');
      assert.deepEqual(rgb(1, frame.height - 2), [16, 23, 46], 'Rotated toolbar reaches bottom edge');
      assert.equal(await page.locator('#canvas').evaluate(c => c.inert), false, 'Portrait never blocks game input');
    }
    assert.deepEqual(errors, [], `Actual exported game starts without runtime errors: ${errors.join(' | ')}`);
    for (const message of new Set(graphicsMessages)) console.log('Browser graphics diagnostic:', message);
    await page.close();
    console.log(`${process.env.BROWSER_ENGINE || 'chromium'}: actual game startup passed, including a late anonymous browser error.`);
  } finally {
    await browser.close();
    server.close();
  }
})().catch(error => { console.error(error); server.close(); process.exitCode = 1; });
