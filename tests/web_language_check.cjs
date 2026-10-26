// Run with Playwright installed; uses the actual exported game and saved settings.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '..');
const types = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const filename = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
  if (!filename.startsWith(root + path.sep) || !fs.existsSync(filename) || !fs.statSync(filename).isFile()) {
    res.writeHead(404).end(); return;
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(filename)] || 'application/octet-stream' });
  fs.createReadStream(filename).pipe(res);
});

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const browser = await chromium.launch({ channel: process.env.BROWSER_CHANNEL || 'msedge', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 320, height: 568 }, hasTouch: true });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (message.type() === 'error' && /SCRIPT ERROR|Parse Error|Failed to load|Error loading/.test(message.text())) errors.push(message.text());
    });
    const ready = async () => {
      await page.waitForFunction(() => document.getElementById('status').hidden, null, { timeout: 60000 });
      await page.waitForFunction(() => document.getElementById('canvas').width > 0);
    };
    await page.goto(`http://127.0.0.1:${server.address().port}/`);
    await ready();
    // Settings gear, then each language button in the responsive 320px layout.
    await page.touchscreen.tap(282, 38);
    for (const [language, x] of [['ja', 160], ['vi', 247], ['en', 73], ['vi', 247]]) {
      await page.touchscreen.tap(x, 329);
      await page.waitForFunction(language => document.documentElement.lang === language, language);
      assert.equal(await page.evaluate(() => localStorage.getItem('bonk-language')), language);
      await page.screenshot({ path: path.join(root, `artifacts/web_language_${language}.png`) });
    }
    // Godot's file save must win over a deliberately different shell preference.
    // Wait for the browser's asynchronous filesystem persistence before reload.
    await page.waitForTimeout(1500);
    await page.evaluate(() => localStorage.setItem('bonk-language', 'ja'));
    await page.reload();
    await ready();
    await page.waitForFunction(() => document.documentElement.lang === 'vi');
    await page.setViewportSize({ width: 568, height: 320 });
    await page.locator('#rotate').waitFor({ state: 'visible' });
    assert.match(await page.locator('#rotate').innerText(), /Xoay điện thoại/);
    assert.deepEqual(errors, [], 'No script or font loading errors in the exported game');
    console.log('Web language checks passed: live selection, saved reload, and Vietnamese rotation prompt.');
  } finally {
    await browser.close();
    server.close();
  }
})().catch(error => { console.error(error); server.close(); process.exitCode = 1; });
