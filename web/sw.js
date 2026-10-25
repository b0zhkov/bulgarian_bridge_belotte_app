// Белот service worker: fast loads and offline play, updates that roll out.
// The build step (tool/make_sw.py) fills in VERSION (a hash of the build)
// and PRECACHE (the app shell); every release therefore installs a new
// worker with a fresh cache, and old caches are deleted when it activates.
const VERSION = '__VERSION__';
const PRECACHE = __PRECACHE__;
const CACHE = 'belot-' + VERSION;
// Cross-origin files the engine and SDKs load (CanvasKit, fonts, Firebase
// JS). Realtime Database / auth traffic is never cached.
const CDN = /^https:\/\/(www|fonts)\.gstatic\.com\//;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      // Bypass the HTTP cache so a release never mixes old files in.
      cache.addAll(PRECACHE.map((u) => new Request(u, { cache: 'reload' }))),
    ),
  );
  // Not skipWaiting(): the page decides (update banner, or next launch).
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((k) => k.startsWith('belot-') && k !== CACHE)
            .map((k) => caches.delete(k)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'SKIP_WAITING') self.skipWaiting();
  if (data.type === 'CACHE_URLS' && Array.isArray(data.urls)) {
    // Files the page loaded before this worker controlled it.
    event.waitUntil(
      caches.open(CACHE).then((cache) =>
        Promise.all(
          data.urls
            .filter(cacheable)
            .map((u) =>
              cache.match(u).then((hit) => hit || cache.add(u).catch(() => {})),
            ),
        ),
      ),
    );
  }
});

function cacheable(url) {
  const u = new URL(url, self.location.href);
  if (u.origin === self.location.origin) {
    return u.pathname.startsWith(new URL('./', self.location.href).pathname) &&
      !u.pathname.endsWith('/sw.js');
  }
  return CDN.test(u.href);
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET' || !cacheable(req.url)) return;
  if (req.mode === 'navigate') {
    // The app shell (index.html) from this version's cache; network only
    // if it is somehow missing. New versions arrive as a new worker.
    event.respondWith(
      caches
        .open(CACHE)
        .then((cache) => cache.match('./', { ignoreSearch: true }))
        .then((hit) => hit || fetch(req)),
    );
    return;
  }
  event.respondWith(
    caches.open(CACHE).then((cache) =>
      cache.match(req, { ignoreSearch: true }).then(
        (hit) =>
          hit ||
          fetch(req).then((res) => {
            if (res.ok || res.type === 'opaque') cache.put(req, res.clone());
            return res;
          }),
      ),
    ),
  );
});
