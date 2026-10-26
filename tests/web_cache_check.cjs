const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const exported = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const loader = fs.readFileSync(path.join(root, 'index.js'), 'utf8');
const worker = fs.readFileSync(path.join(root, 'Draw the Orbit — Prototype.service.worker.js'), 'utf8');
const hosting = JSON.parse(fs.readFileSync(path.join(root, 'vercel.json'), 'utf8'));

assert.match(exported, /await legacyCacheCleanup;/, 'Startup waits for old cache cleanup');
assert.match(exported, /name\.startsWith\('BONK!-sw-cache-'\)/, 'Startup deletes old BONK! caches');
assert.match(loader, /fetch\(file, \{ cache: 'no-store' \}\)/, 'Pack fetch bypasses browser cache');
assert.match(worker, /skipWaiting\(\)/, 'Retirement worker activates immediately');
assert.match(worker, /registration\.unregister\(\)/, 'Retirement worker releases its scope');
assert.doesNotThrow(() => new Function(worker), 'Retirement worker syntax is valid');

for (const route of ['/', '/index.html', '/index.pck']) {
  const rule = hosting.headers.find(candidate => candidate.source === route);
  assert.ok(rule, `${route} has an explicit cache rule`);
  const cacheControl = rule.headers.find(header => header.key.toLowerCase() === 'cache-control');
  assert.match(cacheControl?.value || '', /no-store/, `${route} cannot pin an old release`);
}

console.log('Web release cache checks passed.');
