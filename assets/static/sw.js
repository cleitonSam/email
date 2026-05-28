// Fluxo Email MKT - Service Worker
// Cache-first for static assets, network-first for navigation. Skips LiveView/socket/auth/api.
const CACHE = 'fluxo-email-v1';
const STATIC_PREFIXES = ['/css/', '/js/', '/images/', '/fonts/', '/social-icons/', '/vendor/'];
const STATIC_FILES = ['/manifest.json', '/favicon.ico', '/robots.txt'];
const NEVER_CACHE = ['/live/', '/socket/', '/auth/', '/api/'];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

function isStatic(url) {
  if (STATIC_FILES.includes(url.pathname)) return true;
  return STATIC_PREFIXES.some((p) => url.pathname.startsWith(p));
}

function isNeverCache(url) {
  return NEVER_CACHE.some((p) => url.pathname.startsWith(p));
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (isNeverCache(url)) return;
  if (req.headers.get('upgrade') === 'websocket') return;

  if (isStatic(url)) {
    event.respondWith(
      caches.open(CACHE).then((cache) =>
        cache.match(req).then((hit) => {
          if (hit) return hit;
          return fetch(req).then((res) => {
            if (res && res.ok) cache.put(req, res.clone());
            return res;
          });
        })
      )
    );
    return;
  }

  if (req.mode === 'navigate' || (req.headers.get('accept') || '').includes('text/html')) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          if (res && res.ok) {
            const copy = res.clone();
            caches.open(CACHE).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => caches.match(req).then((hit) => hit || caches.match('/')))
    );
  }
});
