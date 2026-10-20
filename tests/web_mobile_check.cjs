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
    // Exercise the unsupported/denied-lock fallback deterministically.
    await page.addInitScript(() => {
      window.orientationLockCalls = [];
      Element.prototype.requestFullscreen = () => Promise.reject(new Error('Test fullscreen denial'));
      Object.defineProperty(screen.orientation, 'lock', { configurable: true, value: mode => {
        window.orientationLockCalls.push(mode);
        return Promise.reject(new Error('Test orientation-lock denial'));
      } });
    });
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
      if (name.endsWith('playing') || name.endsWith('resumed') || name === 'landscape_barrier') {
        if (!name.startsWith('safe_area')) {
          assert.deepEqual(pixel(1, 1), [25, 33, 62], `${name}: playfield reaches the screen edge`);
          assert.deepEqual(pixel(1, png.height - 2), [16, 23, 46], `${name}: separate bottom toolbar fills the width`);
        }
      }
      if (name === 'landscape_barrier') {
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
    await page.locator('#rotate').waitFor({ state: 'visible' });
    assert.equal(await page.locator('#canvas').evaluate(c => c.inert), true);
    await page.locator('#landscape').click();
    assert.deepEqual(await page.evaluate(() => window.orientationLockCalls), ['landscape']);
    assert.equal(await page.locator('#rotate').isVisible(), true, 'Rejected lock keeps the rotate prompt');
    await snapshot('portrait_rotate');
    await page.setViewportSize({ width: 844, height: 390 });
    await checkCanvas(844, 390);
    await page.locator('#rotate').waitFor({ state: 'hidden' });
    await snapshot('landscape_menu');
    async function tapGameButton(color, centered = false) {
      const bounds = await page.locator('#canvas').boundingBox();
      const png = PNG.sync.read(await page.locator('#canvas').screenshot({ scale: 'css' }));
      const y = centered ? Math.floor(png.height / 2 + 25) : png.height - 32;
      let rightmost = -1;
      for (let x = 0; x < png.width; x++) {
        const offset = (y * png.width + x) * 4;
        if (color.every((v, i) => Math.abs(v - png.data[offset + i]) < 8)) rightmost = x;
      }
      assert.ok(rightmost > 10, centered ? 'Centered overlay button is visible' : 'Bottom toolbar button is visible');
      await page.touchscreen.tap(bounds.x + rightmost - 10, bounds.y + y);
    }
    // Centered title screen: Play sits below the large hero planet.
    const menuBounds = await page.locator('#canvas').boundingBox();
    const menuScale = Math.min(menuBounds.width / 440, menuBounds.height / 680);
    const playHeight = Math.max(44, Math.min(68, 56 * menuScale));
    await page.touchscreen.tap(menuBounds.x + menuBounds.width / 2,
      menuBounds.y + menuBounds.height / 2 + 198 * menuScale + playHeight / 2);
    const cdp = await context.newCDPSession(page);
    const finger = (x, y) => ({ x, y, id: 0, radiusX: 4, radiusY: 4, force: 1 });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [finger(80, 280)] });
    for (let x = 90; x <= 210; x += 20) {
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [finger(x, 270)] });
    }
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await snapshot('landscape_barrier');
    await tapGameButton([185, 172, 245]);
    await snapshot('landscape_paused');
    await tapGameButton([143, 240, 206], true);
    await snapshot('landscape_playing');
    // Turning upright during a run must block input and pause until resumed.
    await page.setViewportSize({ width: 390, height: 700 });
    await checkCanvas(390, 700);
    await page.locator('#rotate').waitFor({ state: 'visible' });
    await page.keyboard.press('r');
    await page.keyboard.press('Enter');
    await snapshot('portrait_blocked_run');
    const frozen = await page.locator('#canvas').screenshot({ scale: 'css' });
    await page.waitForTimeout(300);
    assert.deepEqual(await page.locator('#canvas').screenshot({ scale: 'css' }), frozen, 'Portrait game view remains frozen');
    await page.setViewportSize({ width: 844, height: 430 });
    await checkCanvas(844, 430);
    await page.locator('#rotate').waitFor({ state: 'hidden' });
    await snapshot('landscape_return_paused');
    await tapGameButton([143, 240, 206], true);
    await snapshot('landscape_return_resumed');
    // Simulate notch/home-indicator insets; input must follow the canvas offset.
    await page.addStyleTag({ content: '#game { padding: 32px 16px 24px; }' });
    await checkCanvas(812, 374);
    await tapGameButton([185, 172, 245]);
    await snapshot('safe_area_paused');
    await tapGameButton([143, 240, 206], true);
    await snapshot('safe_area_resumed');
    console.log('Mobile landscape smoke passed: portrait gate, rejected lock fallback, rotation pause, touch drag, resume, safe-area insets, no scrolling.');
    assert.deepEqual(errors, [], 'Browser/runtime errors');
    await context.close();
  } finally {
    await browser.close();
    server.close();
  }
})().catch(error => { console.error(error); server.close(); process.exitCode = 1; });
