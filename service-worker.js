// PESTA 17 - Service Worker
// Strategy:
//   - Static assets  → Cache First
//   - Supabase/API   → Network First (never cached)

const CACHE_NAME = 'pesta17-v1';
const OFFLINE_URL = '/offline.html';

// Assets to precache on install
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/offline.html',
  '/manifest.webmanifest',
  '/icon-192.png',
  '/icon-512.png',
  '/maskable-icon.png',
  // External fonts & libs are handled by runtime caching
];

// ------------------------------------------------------------------
// INSTALL — precache static shell
// ------------------------------------------------------------------
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS.map(url => new Request(url, { cache: 'reload' })))
        .catch((err) => {
          // Non-fatal: offline.html might not exist in dev
          console.warn('[SW] Precache partial failure:', err);
        });
    })
  );
  self.skipWaiting();
});

// ------------------------------------------------------------------
// ACTIVATE — clean old caches
// ------------------------------------------------------------------
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// ------------------------------------------------------------------
// FETCH — routing logic
// ------------------------------------------------------------------
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // 1. Never intercept Supabase or any external API → pass through
  if (
    url.hostname.includes('supabase.co') ||
    url.hostname.includes('supabase.io') ||
    url.hostname.includes('googleapis.com') ||
    url.hostname.includes('gstatic.com') ||
    url.hostname.includes('unpkg.com') ||
    url.hostname.includes('cdn.jsdelivr.net')
  ) {
    // Network First for CDN libs (fonts, lucide, chart.js)
    // but ALWAYS network-only for Supabase
    if (url.hostname.includes('supabase')) {
      event.respondWith(fetch(request));
      return;
    }
    // CDN: Cache First with network fallback
    event.respondWith(cacheFirstWithNetworkFallback(request));
    return;
  }

  // 2. Non-GET → always network
  if (request.method !== 'GET') return;

  // 3. Static local assets → Cache First
  if (
    request.destination === 'document' ||
    request.destination === 'script'   ||
    request.destination === 'style'    ||
    request.destination === 'image'    ||
    request.destination === 'font'     ||
    request.destination === 'manifest' ||
    url.origin === self.location.origin
  ) {
    event.respondWith(cacheFirstWithOfflineFallback(request));
    return;
  }
});

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------
async function cacheFirstWithOfflineFallback(request) {
  const cached = await caches.match(request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch {
    // Offline fallback for navigation requests
    if (request.mode === 'navigate') {
      const offline = await caches.match(OFFLINE_URL);
      if (offline) return offline;
    }
    return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
  }
}

async function cacheFirstWithNetworkFallback(request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch {
    return new Response('', { status: 503 });
  }
}
