// Subí el número de versión cada vez que actualices archivos.
// Eso fuerza a los navegadores a descartar el cache viejo.
const CACHE = "ingemax-v2";

// Recursos que sí conviene cachear de entrada (los estáticos)
const ASSETS = [
  "./",
  "./menu.html",
  "./index.html",
  "./intervenciones.html",
  "./costos.html",
  "./logo-ingemax.jpg",
  "./manifest.json"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS).catch(() => {}))
  );
  self.skipWaiting();
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", e => {
  const req = e.request;

  // Apps Script: siempre red, nunca cache
  if (req.url.includes("script.google.com")) return;

  // Solo manejamos GET
  if (req.method !== "GET") return;

  const url = new URL(req.url);
  const esPagina = req.mode === "navigate" ||
                   url.pathname.endsWith(".html") ||
                   url.pathname.endsWith("/");

  if (esPagina) {
    // ── NETWORK FIRST para páginas HTML ──
    // Busca la versión nueva primero; si no hay internet, usa el cache.
    e.respondWith(
      fetch(req).then(res => {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(req, clone));
        return res;
      }).catch(() =>
        caches.match(req).then(cached => cached || caches.match("./menu.html"))
      )
    );
  } else {
    // ── CACHE FIRST para estáticos (fuentes, imágenes, etc.) ──
    e.respondWith(
      caches.match(req).then(cached =>
        cached || fetch(req).then(res => {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(req, clone));
          return res;
        })
      ).catch(() => caches.match(req))
    );
  }
});
