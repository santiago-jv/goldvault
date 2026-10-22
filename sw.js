const CACHE = 'vaultarq-v26';
const SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png',
  './favicon.png',
  'https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => Promise.allSettled(SHELL.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Daily reminder via Periodic Background Sync (installed PWA, Chrome/Android).
// La fuente real de los mensajes es REMINDER_MSGS en index.html, que los copia
// a este cache (clave 'reminder-msgs.json') cada vez que la app carga o el
// usuario activa el recordatorio. Este array es solo el fallback de arranque,
// por si el SW dispara antes de que la app haya llegado a copiarlos.
const REMINDER_MSGS_FALLBACK = [
  'Mantén tu registro al día: añade los movimientos de hoy.',
  'Dos minutos hoy, claridad todo el mes.',
  '¿Quedó algún gasto de hoy sin registrar?'
];
async function pickReminderMsg(){
  try{
    const cache = await caches.open(CACHE);
    const res = await cache.match('./reminder-msgs.json');
    if(res){ const msgs = await res.json(); if(Array.isArray(msgs) && msgs.length) return msgs[Math.floor(Math.random()*msgs.length)]; }
  }catch(e){}
  return REMINDER_MSGS_FALLBACK[Math.floor(Math.random()*REMINDER_MSGS_FALLBACK.length)];
}
self.addEventListener('periodicsync', e => {
  if (e.tag === 'daily-reminder') {
    e.waitUntil(pickReminderMsg().then(body => self.registration.showNotification('VaultARQ', {
      body, icon: 'icon-192.png', badge: 'favicon.png', tag: 'daily-reminder'
    })));
  }
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.matchAll({type:'window', includeUncontrolled:true}).then(cs => {
    for (const c of cs) { if ('focus' in c) return c.focus(); }
    return clients.openWindow('./');
  }));
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Never cache Supabase (auth/data) or the FX API — always hit the network.
  if (url.hostname.endsWith('supabase.co') || url.hostname.endsWith('er-api.com')) return;

  // Navigations: network-first, fall back to cached shell when offline.
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req).catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Everything else (icons, CDN scripts): cache-first, revalidate in background.
  e.respondWith(
    caches.match(req).then(hit => {
      const net = fetch(req).then(res => {
        if (res && res.status === 200) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      }).catch(() => hit);
      return hit || net;
    })
  );
});
