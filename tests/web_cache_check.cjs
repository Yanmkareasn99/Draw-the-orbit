const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const exported = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const loader = fs.readFileSync(path.join(root, 'index.js'), 'utf8');
const worker = fs.readFileSync(path.join(root, 'Draw the Orbit — Prototype.service.worker.js'), 'utf8');
const hosting = JSON.parse(fs.readFileSync(path.join(root, 'vercel.json'), 'utf8'));
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'bonk.webmanifest'), 'utf8'));

function pngSize(filename) {
  const data = fs.readFileSync(path.join(root, filename));
  assert.equal(data.toString('ascii', 1, 4), 'PNG', `${filename} is a PNG`);
  return [data.readUInt32BE(16), data.readUInt32BE(20)];
}

assert.match(exported, /await legacyCacheCleanup;/, 'Startup waits for old cache cleanup');
assert.match(exported, /name\.startsWith\('BONK!-sw-cache-'\)/, 'Startup deletes old BONK! caches');
assert.match(loader, /fetch\(file, \{ cache: 'no-store' \}\)/, 'Pack fetch bypasses browser cache');
assert.match(exported, /rel="manifest" href="bonk\.webmanifest\?v=orbit-v2"/, 'Export links the revised app manifest');
assert.match(exported, /href="assets\/icons\/bonk-icon-64\.png\?v=orbit-v2"/, 'Export links the revised browser favicon');
assert.match(exported, /href="index\.icon\.png\?v=orbit-v2"/, 'Godot favicon has the new icon revision');
assert.match(exported, /href="index\.apple-touch-icon\.png\?v=orbit-v2"/, 'Apple home-screen icon has the new icon revision');
assert.match(exported, /background: url\("index\.png\?v=orbit-v2"\)/, 'Loading screen displays the revised icon');
assert.deepEqual(pngSize('index.png'), [512, 512], 'Godot loading icon uses the custom 512px image');
assert.deepEqual(pngSize('index.apple-touch-icon.png'), [180, 180], 'Apple home-screen icon is 180px');
assert.deepEqual(pngSize('assets/icons/bonk-icon-64.png'), [64, 64], 'Browser favicon is 64px');
assert.deepEqual(manifest.icons.map(icon => icon.sizes), ['192x192', '512x512', '512x512'], 'Manifest contains regular and maskable app icon sizes');
assert.deepEqual(manifest.icons.map(icon => icon.purpose), ['any', 'any', 'maskable'], 'Maskable artwork is separate from standard app artwork');
for (const icon of manifest.icons) {
  const iconUrl = new URL(icon.src, 'https://bonk.invalid');
  const filename = iconUrl.pathname.replace(/^\//, '');
  assert.equal(iconUrl.searchParams.get('v'), 'orbit-v2', `${icon.src} has the current revision`);
  assert.ok(fs.existsSync(path.join(root, filename)), `${icon.src} exists`);
  assert.deepEqual(pngSize(filename), icon.sizes.split('x').map(Number), `${icon.src} matches its declared size`);
}
assert.match(manifest.icons[2].src, /\/bonk-icon-maskable-512\.png\?v=orbit-v2$/, 'Maskable entry uses the padded app icon');
assert.match(worker, /skipWaiting\(\)/, 'Retirement worker activates immediately');
assert.match(worker, /registration\.unregister\(\)/, 'Retirement worker releases its scope');
assert.doesNotThrow(() => new Function(worker), 'Retirement worker syntax is valid');

for (const route of ['/', '/index.html', '/index.pck']) {
  const rule = hosting.headers.find(candidate => candidate.source === route);
  assert.ok(rule, `${route} has an explicit cache rule`);
  const cacheControl = rule.headers.find(header => header.key.toLowerCase() === 'cache-control');
  assert.match(cacheControl?.value || '', /no-store/, `${route} cannot pin an old release`);
}

for (const route of ['/bonk.webmanifest', '/assets/icons/:path*', '/index.icon.png', '/index.apple-touch-icon.png', '/index.png']) {
  const rule = hosting.headers.find(candidate => candidate.source === route);
  assert.ok(rule, `${route} has an explicit icon cache rule`);
  const cacheControl = rule.headers.find(header => header.key.toLowerCase() === 'cache-control');
  assert.match(cacheControl?.value || '', /no-cache/, `${route} revalidates cached icons`);
  assert.match(cacheControl?.value || '', /must-revalidate/, `${route} cannot reuse stale icons`);
}

console.log('Web release cache checks passed.');
