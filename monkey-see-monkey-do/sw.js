// Beta site service worker: keeps these pages fresh.
// GitHub Pages serves this project at /Eddie-G/monkey-see-monkey-do/, next to
// the Off-Grid Survival Kit, whose offline service worker covers the whole
// site (/Eddie-G/) and serves files cache-first. This one covers only
// /Eddie-G/monkey-see-monkey-do/ and has no fetch handler, so the landing,
// privacy and support pages always come straight from the network.
// The game in play/ registers its own offline service worker.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
