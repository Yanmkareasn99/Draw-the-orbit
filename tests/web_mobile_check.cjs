// Requires Playwright; run after exporting the Web preset.
const { chromium } = require('playwright');
const { PNG } = require('pngjs');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const entry = fs.readdirSync(root).find(name => name.endsWith('.html'));
const types = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.pck': 'application/octet-stream' };
const server = http.createServer((req, res) => {
  const filename = path.resolve(root, '.' + decodeURIComponent(new URL(req.url, 'http://localhost').pathname));
  if (!filename.startsWith(root + path.sep) || !fs.existsSync(filename) || !fs.statSync(filename).isFile()) {
    res.writeHead(404).end(); return;
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(filename)] || 'application/octet-stream' });
  fs.createReadStream(filename).pipe(res);
});

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const browser = await chromium.launch({ channel: process.env.BROWSER_CHANNEL || 'msedge', headless: true, args: ['--enable-unsafe-swiftshader'] });
  const errors = [];
  try {
    const context = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    await page.goto(`http://127.0.0.1:${server.address().port}/${encodeURIComponent(entry)}`);
    await page.waitForFunction(() => document.getElementById('status').hidden, null, { timeout: 45000 });
    async function snapshot(name) {
      const data = await page.screenshot({ path: path.join(root, 'artifacts', `web_${name}.png`), scale: 'css' });
      const png = PNG.sync.read(data);
      const pixel = (x, y) => [...png.data.subarray((y * png.width + x) * 4, (y * png.width + x) * 4 + 3)];
      for (const [x, y] of [[1, 1], [png.width - 2, 1], [1, png.height - 2], [png.width - 2, png.height - 2]]) {
        assert.ok(Math.max(...pixel(x, y)) > 10, `${name}: canvas must fill screen without black letterboxing`);
      }
      if (name.endsWith('playing') || name === 'portrait_barrier') {
        assert.deepEqual(pixel(1, 1), [19, 27, 51], `${name}: game resumed`);
      }
      if (name === 'portrait_barrier') {
        let mintPixels = 0;
        for (let y = 265; y <= 282; y++) for (let x = 75; x <= 215; x++) {
          const [r, g, b] = pixel(x, y);
          if (g > 190 && r > 90 && b > 150 && g > r + 15) mintPixels++;
        }
        assert.ok(mintPixels > 80, 'Touch stroke appears under the finger in the exported game');
      }
    }
    async function checkCanvas(width, height) {
      await page.waitForFunction(([w, h]) => {
        const c = document.getElementById('canvas');
        return c.clientWidth === w && c.clientHeight === h && c.width === w * 2 && c.height === h * 2;
      }, [width, height]);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth || document.documentElement.scrollHeight > innerHeight), false);
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    }
    await checkCanvas(390, 844);
    await snapshot('portrait_menu');
    await page.touchscreen.tap(195, 744);
    const cdp = await context.newCDPSession(page);
    const finger = (x, y) => ({ x, y, id: 0, radiusX: 4, radiusY: 4, force: 1 });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [finger(80, 280)] });
    for (let x = 90; x <= 210; x += 20) {
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [finger(x, 270)] });
    }
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await snapshot('portrait_barrier');
    await page.touchscreen.tap(350, 36);
    await snapshot('portrait_paused');
    await page.setViewportSize({ width: 844, height: 390 });
    await checkCanvas(844, 390);
    await snapshot('landscape_paused');
    await page.touchscreen.tap(422, 300);
    await snapshot('landscape_playing');
    // Browser toolbar / viewport height changes must not crop controls.
    await page.setViewportSize({ width: 390, height: 700 });
    await checkCanvas(390, 700);
    await snapshot('short_portrait_playing');
    // Simulate notch/home-indicator insets; input must follow the canvas offset.
    await page.addStyleTag({ content: '#game { padding: 32px 16px 24px; }' });
    await checkCanvas(358, 644);
    await page.touchscreen.tap(334, 68);
    await snapshot('safe_area_paused');
    await page.touchscreen.tap(195, 576);
    await snapshot('safe_area_resumed');
    console.log('Mobile web smoke passed: DPR 3, touch drag, pause, rotate, resume, viewport resize, safe-area insets, no scrolling.');
    assert.deepEqual(errors, [], 'Browser/runtime errors');
    await context.close();
  } finally {
    await browser.close();
    server.close();
  }
})().catch(error => { console.error(error); server.close(); process.exitCode = 1; });
