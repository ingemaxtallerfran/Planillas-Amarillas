# CLAUDE.md

Este archivo le da guía a Claude Code (claude.ai/code) al trabajar con código en este repositorio.

- Respondé siempre en español.

## Qué es esto

Ingemax es una PWA interna en español para una empresa que gestiona equipos pesados (combustible, stock, mantenimiento, herramental, órdenes de trabajo). Es un sitio estático, sin build ni framework: archivos planos de HTML/CSS/JS servidos tal cual, respaldados por Google Apps Script (Google Sheets) como API/base de datos. No hay package.json, paso de build, linter ni suite de tests: cada cambio se hace directamente sobre los archivos HTML y se despliega sirviendo esos mismos archivos estáticos.

## Páginas

- [menu.html](menu.html) — hub de entrada que enlaza a las demás apps.
- [index.html](index.html) — "Planillas Amarillas": carga diaria de uso de operario/equipo. Soporta cola offline (`localStorage` con `pam_pending`/`pam_hist`) que sincroniza vía JSONP cuando vuelve la conexión.
- [intervenciones.html](intervenciones.html) — "Gestión de Equipos": la app grande multi-módulo (combustible/`Combustible`, `Stock`, `Planillas` de solo lectura, `Intervenciones`/órdenes de trabajo, `Equipos`, `Herramental Menor`). Las secciones se alternan con `switchPage`/`switchStab` en vez de un ruteo real — todo vive en un solo archivo con divisores `<!-- ══ SECCIÓN ══ -->`.
- [costos.html](costos.html) — informe de costos/inversión por equipo, tipo y año.
- [remitos.html](remitos.html) — registro de remitos propios (entregas) y de terceros/compras, con foto opcional y lectura automática por IA para los de terceros (mismo mecanismo que la lectura de planillas de combustible en `intervenciones.html`: foto → Claude la lee → el usuario revisa/corrige → se guarda). Filtros por tipo, fecha, proveedor/destinatario y obra.
- [consultas.html](consultas.html) — chat de preguntas en lenguaje natural sobre la flota (ubicación, batería, service, consumo de combustible, stock de cisterna). El backend usa *tool calling* de la API de Anthropic: la IA elige qué función/hoja consultar según la pregunta en vez de recibir todas las hojas de una, y las respuestas siempre citan la fecha del dato usado. El historial de la conversación se mantiene solo en el cliente (array JS) y se manda completo en cada pregunta — no hay persistencia de chats en el backend.

Cada página es autocontenida: tiene su propio bloque `<style>` y su `<script>` inline, sin JS/CSS compartido ni bundler. Al arreglar algo en una página, revisá si el mismo patrón está duplicado en las otras (por ejemplo, `jsonp()`, `aplicarTema()`, `toast()`, helpers de campos como `g()`/`fill()` están copiados y pegados por archivo, no importados).

## Integración con el backend

- Cada página llama a una Web App de Google Apps Script vía JSONP (helper `jsonp(url)` — crea un tag `<script>` con un parámetro `callback=`, ya que Apps Script no soporta CORS para este tipo de uso). No hay código de servidor en este repo; el proyecto de Apps Script vive fuera de él.
- **Nunca modificar la URL de deploy de Apps Script (constante `URL_`, el string `https://script.google.com/macros/s/.../exec`) en ningún archivo.** Cambiarla redirige la app a otro backend/spreadsheet. Notar que `index.html` apunta intencionalmente a un deploy distinto al de `intervenciones.html`/`costos.html` (hojas de cálculo diferentes) — no "corregir" esto unificándolas.
- `sw.js` excluye explícitamente del cache cualquier request a `script.google.com` — siempre va a la red, nunca se cachea.

## PWA / offline

- [manifest.json](manifest.json) + [sw.js](sw.js) convierten esto en una PWA. `sw.js` usa cache network-first para las páginas HTML y cache-first para los assets estáticos, con una lista fija de assets (`ASSETS`) y un string de versión (`CACHE`).
- **Subí la constante `CACHE` en [sw.js](sw.js:3) cada vez que cambies cualquier archivo cacheado** (cualquier `.html`, `manifest.json`, el logo) — si no, los usuarios que vuelven siguen viendo páginas cacheadas viejas. Esta es la convención existente (`ingemax-v4`, etc.), no una prolijidad opcional.
- Si agregás una página nueva que deba funcionar offline, sumala también al array `ASSETS` en `sw.js`.
- `index.html` además implementa una cola offline a nivel de app (separada del service worker): los envíos fallidos u offline se guardan en `localStorage` y se reintentan con el evento `online`.

## Convenciones de estilo

- Paleta de marca: el acento naranja es `#E8651A` en modo oscuro y `#D9540A` en modo claro (usado como `--naranja`). No usar otros tonos de naranja.
- Tipografías: `Barlow` para el texto de cuerpo, `Barlow Condensed` para títulos/encabezados/etiquetas (cargadas desde Google Fonts). `index.html` es la única excepción que usa una pila de fuentes del sistema en vez de estas — mantenerlo consistente consigo mismo, no "arreglarlo" en silencio para igualarlo a las demás sin que se pida.
- El tema oscuro/claro se maneja con un atributo `data-theme="light"` en `<html>`, alternado por `toggleTema()`/`aplicarTema()` y persistido en `sessionStorage` (clave `tema`) — no en `localStorage`, ni con `prefers-color-scheme`. Los overrides de CSS viven en bloques `[data-theme="light"] { ... }` que redefinen las mismas custom properties de CSS (`--naranja`, `--negro`, `--gris1`, etc.) declaradas en `:root`. Al agregar UI con color nuevo, definila como variable CSS en `:root` y sobrescribila en el bloque `[data-theme="light"]` en vez de hardcodear colores.
- `menu.html` e `index.html` no implementan cambio de tema (son solo oscuro / solo claro respectivamente) — no asumir que todas las páginas tienen un toggle de tema.

## Flujo de trabajo: cambio → cache → push → publicado

El sitio se publica por GitHub Pages: no hay paso de deploy separado, lo que está en `main` es lo que ven los usuarios. Después de cada cambio en un archivo cacheado por el service worker:

1. Subir la constante `CACHE` en [sw.js](sw.js:3) (ver sección PWA / offline).
2. Commitear el cambio.
3. Pushear a `main`.

Si te salteás el push, el cambio no existe para nadie más allá de tu working directory; si te saltás el bump de `CACHE`, el push no alcanza porque los usuarios que vuelven van a seguir viendo la versión cacheada vieja. Los dos pasos son parte del mismo "deploy" y van juntos.

## Trabajando en intervenciones.html

Este archivo es grande (~180KB, 3180 líneas) y no tiene límites de módulos — es un solo `<script>` con muchas funciones a nivel superior. Antes de agregar una función, buscá helpers existentes (`g()`, `fill()`/`fillSelect()`, `toast()`, `jsonp()`, `fmtFecha*()`, `parseNum()`) en vez de reimplementarlos. Las funciones de estado/renderizado de cada sección están prefijadas por módulo, por ejemplo `comb*` (Combustible), `cg*` (Carga/Stock), `interv*` (Intervenciones), `equipos*` (Equipos).
