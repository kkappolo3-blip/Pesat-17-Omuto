// PESTA 17 - Service Worker
// Strategy:
//   - HTML shell (index.html/navigasi) → Network First, so setiap deploy baru
//     LANGSUNG terpakai. (Sebelumnya Cache First membuat pengguna bisa
//     terjebak selamanya di versi index.html lama walau sudah di-deploy ulang
//     — ini akar penyebab "bug yang sudah diperbaiki tapi masih muncul".)
//   - Aset statis (ikon, manifest)  → Cache First (jarang berubah)
//   - Supabase/API                 → Network Only (tidak pernah di-cache)

// PENTING: naikkan versi ini SETIAP kali index.html di-deploy ulang, supaya
// service worker lama dibuang dan tidak ada cache basi yang tersisa.
const CACHE_VERSION = 'v2-2026-07-12';
const CACHE_NAME = `pesta17-${CACHE_VERSION}`;
const OFFLINE_URL = '/offline.html';

// Assets to precache on install
const PRECACHE_ASSETS = [
  '/offline.html',
  '/manifest.webmanifest',
  '/icon-192.png',
  '/icon-512.png',
  '/maskable-icon.png',
  // '/' dan '/index.html' SENGAJA tidak di-precache di sini karena
  // keduanya harus selalu diambil dari jaringan terlebih dahulu (lihat
  // networkFirstForDocument di bawah).
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
// ACTIVATE — clean old caches (semua versi lama dibuang otomatis)
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

  // 3. HTML document / navigation (index.html) → ALWAYS Network First.
  //    This guarantees every new deploy is visible immediately instead of
  //    being masked by a stale cached copy of the app.
  if (request.mode === 'navigate' || request.destination === 'document') {
    event.respondWith(networkFirstForDocument(request));
    return;
  }

  // 4. Other same-origin static assets (icons, manifest) → Cache First
  if (
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
async function networkFirstForDocument(request) {
  try {
    const response = await fetch(request, { cache: 'no-store' });
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch {
    // Offline: fall back to whatever was last cached, then to offline.html
    const cached = await caches.match(request);
    if (cached) return cached;
    const offline = await caches.match(OFFLINE_URL);
    if (offline) return offline;
    return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
  }
}

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
