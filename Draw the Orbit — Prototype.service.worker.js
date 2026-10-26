// Retirement worker for BONK!'s former offline PWA export.
//
// Older mobile installations used a cache-first Godot worker, which could pin
// an obsolete HTML page and game pack indefinitely. The current web build does
// not register a service worker. When a browser checks this existing
// registration for updates, this replacement activates immediately, removes
// the old BONK! caches, releases the scope, and reloads open game windows from
// the network.
const CACHE_PREFIX = 'BONK!-sw-cache-';

self.addEventListener('install', event => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames
      .filter(name => name.startsWith(CACHE_PREFIX))
      .map(name => caches.delete(name)));
    await self.clients.claim();
    const windows = await self.clients.matchAll({ type: 'window' });
    await self.registration.unregister();
    await Promise.all(windows.map(client => client.navigate(client.url)));
  })());
});
