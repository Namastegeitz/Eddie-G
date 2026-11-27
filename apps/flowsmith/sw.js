// FLOWSMITH offline cache (standalone app only; Claude artifacts don't run service workers).
// App files and data are precached; same-origin GETs are served cache-first and refreshed in the background.
const CACHE = "flowsmith-v1.0.0";
const SHELL = [
  "./", "index.html", "manifest.webmanifest",
  "assets/css/app.css", "assets/js/app.js", "assets/js/engine.js", "assets/js/ai.js", "assets/js/store.js",
  "assets/icons/icon.svg", "assets/icons/icon-180.png", "assets/icons/icon-192.png", "assets/icons/icon-512.png", "assets/icons/icon-maskable-512.png",
  "data/chips-sound.json", "data/chips-instruments.json", "data/chips-voice-mix.json",
  "data/beats.json", "data/recipes.json", "data/learn.json", "data/flow-guide.json",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => Promise.all(SHELL.map((u) => c.add(u).catch(() => null)))).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k.startsWith("flowsmith-") && k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return; // Claude API, fonts and Flow links go straight to the network
  e.respondWith(caches.open(CACHE).then(async (c) => {
    const hit = await c.match(req, { ignoreSearch: true });
    const net = fetch(req).then((res) => { if (res.ok) c.put(req, res.clone()); return res; }).catch(() => null);
    if (hit) { e.waitUntil(net); return hit; }
    const res = await net;
    return res || (req.mode === "navigate" ? c.match("index.html") : new Response("Offline", { status: 503 }));
  }));
});
