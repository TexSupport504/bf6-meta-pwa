// sw.js — BF6 Meta service worker
// Bump CACHE_VERSION when shipping breaking changes to force clients to refresh.

const CACHE_VERSION = 'bf6meta-v6';
const SHELL = [
  './',
  './index.html',
  './weapons.json',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './favicon.png',
];

// Install — cache the app shell
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(SHELL))
  );
  self.skipWaiting();
});

// Activate — wipe old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// Fetch — network-first for weapons.json (always try fresh data),
// cache-first for everything else (fast, offline-capable).
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Only handle GETs from same origin
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) {
    return;
  }

  // weapons.json: try network, fall back to cache
  if (url.pathname.endsWith('/weapons.json')) {
    event.respondWith(
      fetch(event.request)
        .then((res) => {
          // Update cache with fresh copy
          const copy = res.clone();
          caches.open(CACHE_VERSION).then((c) => c.put(event.request, copy));
          return res;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Everything else: cache first, network fallback
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return (
        cached ||
        fetch(event.request).then((res) => {
          // Cache successful GETs
          if (res.ok) {
            const copy = res.clone();
            caches.open(CACHE_VERSION).then((c) => c.put(event.request, copy));
          }
          return res;
        })
      );
    })
  );
});
