# Plan: feedback de usuarios dentro de la app

!!! note "Estado: propuesto, sin implementar (2026-10-11)"
Plan ejecutable de punta a punta. Toca **dos repos**: `lamula-webviewer` (servidor y
bandeja, Fase 0) y este (cliente, Fases 1-7). La Fase 0 es prerrequisito duro: hasta que
no esté desplegada, este repo no tiene a dónde escribir.

## Contexto

`lamula-process` se enseña a meteorólogos del Centro de Radares, profesores y estudiantes. Hoy
no hay forma de que dejen una opinión dentro de la app: lo que se aprende del uso real se
pierde. `lamula-webviewer` ya resolvió exactamente este problema (decisión 39 de ese repo, PR
#11, mergeado): perfil de quien escribe, persistencia en Postgres, hilo con respuestas, pill de
acceso permanente y un popup ocasional no insistente.

Decisión del usuario (2026-10-11): **una sola bandeja de entrada, compartida con el webviewer**,
con un discriminador explícito para saber de qué producto viene cada mensaje.

## Qué existe ya en `lamula-webviewer` (no rehacer)

| Pieza                            | Fichero                                                       |
| -------------------------------- | ------------------------------------------------------------- |
| Schema `viewer.*` (3 tablas)     | `db/viewer_migrations/0001_feedback.sql`                      |
| Migración on-boot (SQL embebido) | `server/plugins/migrate-feedback.ts`                          |
| Contrato Zod                     | `shared/contract/feedback.ts`                                 |
| Interfaz DAL                     | `server/dal/feedback-types.ts`                                |
| DAL Postgres / memoria           | `server/dal/feedback-live.ts`, `feedback-memory.ts`           |
| Endpoints públicos               | `server/api/feedback/{index.post,mine.get,mine/read.post}.ts` |
| Endpoints admin                  | `server/api/admin/feedback/**`, `server/middleware/admin.ts`  |
| Rate-limit, Turnstile, webhook   | `server/utils/{rate-limit,turnstile,webhook}.ts`              |
| UI usuario                       | `components/Feedback{Dialog,Nudge}.vue`                       |
| UI admin                         | `pages/admin/{feedback,login}.vue`                            |
| Tests                            | `tests/unit/feedback-*.spec.ts`, `e2e/feedback.spec.ts`       |

Identidad sin cuentas: el navegador genera un token de 32 bytes en `localStorage`, el servidor
guarda `sha256(token)` y el token viaja en la cabecera `x-feedback-token`.

## Diferencias de arquitectura que obligan a desviarse

| `lamula-webviewer`              | `lamula-process`                                                 |
| ------------------------------- | ---------------------------------------------------------------- |
| Nuxt con servidor + Postgres    | SvelteKit `adapter-static`, SPA pura en Pages, **sin backend**   |
| Solo web                        | Web + Tauri escritorio (hoy despriorizado, no descartado)        |
| Strings ES hardcodeados         | i18n ES+EN, `scripts/check-i18n.mjs` corre dentro de `pnpm lint` |
| Zod en el contrato              | No hay `zod` en `package.json`                                   |
| Playwright e2e                  | Solo vitest, proyecto `server` en entorno node                   |
| XState con 4 regiones paralelas | Solo `observationMachine`; el resto del estado es runes          |
| Rail de pastillas libre         | Menubar (`MenuBar.svelte`) + `StatusBar.svelte`                  |

La meta declarada en `docs/index.md` es "una app que corra tanto en web (cliente puro, sin
backend) como de escritorio". Este plan **no la rompe**: no añade servidor a este repo. Añade un
cliente HTTP opcional que falla suave — si la API no responde, la app abre ficheros, calcula
productos y exporta exactamente igual.

## El discriminador: cómo se sabe cuál es cuál

Cuatro capas, de más fuerte a más informativa.

**1. Columna `app` en `viewer.feedback`.** La que manda: filtrable e indexable, no enterrada en
JSONB.

```sql
ALTER TABLE viewer.feedback
  ADD COLUMN IF NOT EXISTS app TEXT NOT NULL DEFAULT 'webviewer'
  CHECK (app IN ('webviewer','process'));

CREATE INDEX IF NOT EXISTS idx_feedback_app ON viewer.feedback (app, status, created_at DESC);
```

`DEFAULT 'webviewer'` deja correctas las filas existentes sin backfill. Es idempotente: si la
columna ya existe, `ADD COLUMN IF NOT EXISTS` salta la cláusula entera y el `CHECK` no se
duplica — crítico, porque `migrate-feedback.ts` corre **en cada arranque** del contenedor.

**2. `app` en el cuerpo del POST**, validado contra enum (`FEEDBACK_APPS`). El webviewer pasa a
mandarlo explícito también; el default de columna queda solo para el histórico.

**3. `context.platform`**: `'web' | 'tauri'`. Process corre en ambos y saber si el bug es del
navegador o del escritorio cambia el triage. El webviewer manda siempre `'web'`.

**4. `context.buildId`**: qué build exacto. Acá se cablea `GIT_SHA` de verdad (ver Fase 4); en el
webviewer quedó en `'dev'` porque el `ARG` del Dockerfile nunca se añadió.

### Límite conocido, no arreglable sin cuentas

`feedback_users` se indexa por `token_hash` y el token vive en `localStorage` **por origen**. La
misma persona en webviewer, en Process web y en Process/Tauri (`tauri://localhost`) son tres
usuarios sin relación entre sí. No afecta al triage (cada mensaje trae su perfil), pero **no se
pueden contar usuarios únicos sumando filas de `feedback_users`**.

Efecto lateral bueno: la clave del rate-limit es `${ip}:${rawToken}`
(`server/api/feedback/index.post.ts:22`), así que los límites de las dos apps no se cruzan.

Los enums existentes sirven tal cual: los roles (`profesor`, `meteorologo`, `investigador`,
`estudiante`, `aficionado`, `otro`) y los tipos (`mejora`, `bug`, `dato`, `otro`) aplican igual a
Process. **No se tocan.**

---

# Fase 0 — `lamula-webviewer` (prerrequisito)

Repo: `/home/node/workspace/lamula-webviewer`. Todo esto es trabajo en el OTRO repo.

## 0.1 Migración

- Crear `db/viewer_migrations/0002_app.sql` con el `ALTER TABLE` + `CREATE INDEX` de arriba.
- Añadir el mismo SQL al final de `MIGRATION_SQL` en `server/plugins/migrate-feedback.ts:5`. El
  SQL está **embebido**, no se lee de disco (el contenedor de producción solo empaqueta
  `.output/`), así que hay que editar los dos ficheros. El comentario de la línea 4 ya lo
  advierte.

## 0.2 Contrato

`shared/contract/feedback.ts`:

```ts
export const FEEDBACK_APPS = ['webviewer', 'process'] as const;
export type FeedbackApp = (typeof FEEDBACK_APPS)[number];
export const zFeedbackApp = z.enum(FEEDBACK_APPS);
```

- `zFeedbackSubmission`: añadir `app: zFeedbackApp.default('webviewer')`. Con `.default()` los
  clientes viejos siguen validando.
- `zFeedbackAdminItem`: añadir `app: zFeedbackApp`.
- `zFeedbackThreadItem`: **no** necesita `app` (un token solo ve su propia app), pero añadirlo
  sale gratis y ahorra una pregunta futura. Opcional.
- Ya se re-exporta desde el barrel (`shared/contract/index.ts:2`, `export * from './feedback'`).

## 0.3 DAL

`server/dal/feedback-types.ts`:

```ts
export interface FeedbackAdminFilters {
	status?: FeedbackStatus;
	role?: string;
	app?: FeedbackApp; // nuevo
}
```

`server/dal/feedback-live.ts`:

- `createFeedback` (`:55-72`): la SQL pasa a
  `INSERT INTO viewer.feedback (token_hash, kind, rating, message, context, app) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id::text`.
- `listAll` (`:137-226`): el `WHERE` ya se construye dinámicamente empujando a `params` y
  `conditions` (`:138-150`). Añadir el tercer bloque idéntico:
  `if (filters?.app) { params.push(filters.app); conditions.push(\`f.app = $${params.length}\`) }`.
El `SELECT` (`:152-160`) gana `f.app`.
- **Trampa documentada**: `asPg()` en `tests/helpers/pg-sqlite.ts:87-110` traduce `$n → ?`
  **posicional**. Ninguna query nueva puede repetir un placeholder o el orden de parámetros se
  corrompe en silencio y el test pasa con datos mal puestos.

`server/dal/feedback-memory.ts`:

- `FeedbackRecord` (`:25-34`) gana `app`.
- `createFeedback` (`:61-77`) lo guarda; `listAll` (`:115-162`) añade el
  `items = items.filter(f => f.app === filters.app)` equivalente, y lo devuelve en el map.

## 0.4 Endpoints

- `server/api/feedback/index.post.ts`: nada que cambiar en el handler — `app` entra por
  `parseBody(event, zFeedbackSubmission)` (`:9`) y llega al DAL dentro de `submission`.
- `server/api/admin/feedback/index.get.ts:5`: `zAdminFeedbackQuery` gana
  `app: zFeedbackApp.optional()`.

## 0.5 CORS (lo que hoy no existe)

`grep -rin "cors\|access-control" server/ nuxt.config.ts` sale **vacío**. Sin esto el navegador
bloquea cualquier POST desde `lamula-process`: es cross-origin y lleva una cabecera no simple
(`x-feedback-token`), así que dispara preflight `OPTIONS`.

Verificado contra producción (2026-10-11), no inferido:

```
curl -D- -o/dev/null -H 'Origin: https://process.ladetec.com' \
  https://webviewer.ladetec.com/api/health
→ HTTP/2 200, sin ninguna cabecera access-control-*

curl -D- -o/dev/null -X OPTIONS -H 'Origin: …' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: x-feedback-token,content-type' \
  https://webviewer.ladetec.com/api/feedback
→ HTTP/2 404
```

El 404 del preflight es el detalle operativo que importa: la ruta solo tiene `index.post.ts`, no
hay handler de `OPTIONS`. El middleware de Nitro corre **antes** del enrutado, así que terminar
ahí el `OPTIONS` con 204 resuelve las dos cosas (preflight y cabeceras) sin añadir handlers por
ruta.

Crear `server/middleware/cors.ts`, mismo patrón que `server/middleware/admin.ts` (leer
`event.path`, actuar solo sobre el prefijo que le toca, salir temprano):

- Aplica solo a `/api/feedback` y `/api/feedback/**`. **No** a `/api/admin/**`: el admin usa
  cookie de sesión y abrirlo a otros orígenes sería un agujero.
- Allowlist explícita por env (`NUXT_CORS_ORIGINS`, lista separada por comas), **nunca `*`** —
  hay una cabecera de identidad en juego.
- **Origen confirmado por el usuario: `https://process.ladetec.com`, y solo ese.** Nada de
  `*.pages.dev`: los preview deployments por rama quedan FUERA a propósito, así que desde un
  preview el envío de feedback no sale (queda encolado, no se pierde). Para probar el camino
  completo hay que hacerlo desde producción o añadir el origen a mano por un rato.
- Debe incluir el origen de Tauri. En Tauri v2 el origen de la webview es `tauri://localhost`
  (macOS/iOS) o `http://tauri.localhost` (Windows/Android); en Linux/WebKitGTK puede llegar
  `null`. _Asunción a verificar cuando el build de escritorio exista: hoy no hay toolchain Rust
  en este entorno._ Mitigación ya prevista en la Fase 2: si el `fetch` del navegador falla por
  CORS, el envío queda encolado, no se pierde.
- Responder al preflight: `Access-Control-Allow-Origin` (el origen concreto, reflejado desde la
  allowlist), `Access-Control-Allow-Headers: content-type, x-feedback-token`,
  `Access-Control-Allow-Methods: GET, POST, OPTIONS`, `Access-Control-Max-Age`, y terminar el
  `OPTIONS` con 204 sin llegar al handler.
- `Access-Control-Allow-Credentials` **no** se pone: la identidad va en cabecera propia, no en
  cookie, y activarlo prohíbe el origen reflejado comodín y amplía la superficie sin ganar nada.
- Añadir `corsOrigins: ''` a `runtimeConfig` (`nuxt.config.ts:78-99`).

## 0.6 Admin

`pages/admin/feedback.vue`:

- `selectedApp = ref('')` junto a los otros dos filtros (`:15-16`), un `<select>` más en el bloque
  de filtros (`:109-125`), y la clave en el `query` del `$fetch` (`:30`).
- Etiqueta visible por fila en la cabecera de la tarjeta (`:147-151`), al lado del rol y el tipo.
  Sin color nuevo: basta el texto `webviewer` / `process` con las clases de badge que ya se usan
  para `kind`.

## 0.7 Webhook

`server/utils/webhook.ts:18`: añadir `app: submission.app` al cuerpo. Sin esto la notificación de
Telegram/ntfy no dice de qué producto viene, que es justo el problema que este plan resuelve.

## 0.8 Tests (webviewer)

- `tests/unit/feedback-dal.spec.ts` (67 líneas): la suite de paridad ya itera
  `for (const dal of [liveDal, memoryDal])` (`:18-66`). Añadir casos: `createFeedback` persiste
  `app`, `listAll({ app })` filtra, y **`listAll()` sin filtro devuelve ambas apps** (canario
  contra un `WHERE` que se cuele siempre).
- `tests/unit/feedback-schema.spec.ts`: `zFeedbackSubmission` sin `app` cae a `'webviewer'`;
  `app: 'otro'` es rechazado.
- `tests/helpers/pg-sqlite.ts`: verificar que el `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` pasa
  por `sqliteCompatible` (`:23-32`). SQLite soporta `ADD COLUMN` pero **no** `IF NOT EXISTS` en esa
  posición, ni `CHECK` añadido a posteriori sobre una tabla con filas. Lo más limpio es que el
  helper cargue `0001` + `0002` y, si tropieza, traducir `ADD COLUMN IF NOT EXISTS` → `ADD COLUMN`
  en la lista de traducciones, no tocar el `.sql` versionado.
- Un test nuevo de CORS: `OPTIONS` a `/api/feedback` desde un origen permitido devuelve 204 con las
  cabeceras; desde uno no permitido, sin cabecera `Access-Control-Allow-Origin`.

## 0.9 Documentación (webviewer)

- `docs/decisiones.md`: **decisión 50** (la 49 ya la ocupa el satélite/viento/rayos del mosaico; formato `50. **Título.**` con viñetas
  indentadas). Contenido: bandeja compartida en vez de un backend por app; columna `app` en vez de
  solo `context.app`; CORS con allowlist acotado a `/api/feedback`; el límite de identidad por
  origen; descartes (Worker+D1 propio en Process, Pages Functions en Process).
- `CLAUDE.md` y `docs/plan-feedback.md` de ese repo: nota corta de que la bandeja ya no es de un
  solo producto.

---

# Fases 1-7 — `lamula-process` (este repo)

Todo bajo `src/lib/feedback/`, salvo los puntos de montaje.

## Fase 1 — Contrato y cliente HTTP

`src/lib/feedback/contract.ts`

- Tuplas `as const` + tipos derivados, espejo literal de `shared/contract/feedback.ts` del
  webviewer: `FEEDBACK_ROLES`, `FEEDBACK_KINDS`, `FEEDBACK_STATUSES`, `FEEDBACK_APPS`.
- Interfaces `FeedbackProfile`, `FeedbackSubmission`, `FeedbackThreadItem`, `AdminReply`.
- Validación del formulario a mano (`validateSubmission(): string[]` devolviendo **claves i18n**,
  no frases). **Sin añadir `zod`**: el servidor es la autoridad de validación y acá solo se
  valida lo que el usuario escribe. Riesgo asumido: drift entre repos — se ancla con un comentario
  de cabecera que nombre el fichero fuente y la decisión 50.

`src/lib/feedback/client.ts`

- `submitFeedback(body, { signal })`, `listMine()`, `markRepliesRead()`.
- Base URL desde `PUBLIC_FEEDBACK_API` (ver Fase 4). Valor de producción confirmado:
  **`https://webviewer.ladetec.com/api`** (verificado 2026-10-11: `/api/health` y `/api/radars`
  devuelven 200, detrás del proxy de Cloudflare). Si está vacía, **la feature entera se apaga**:
  no se monta el menú, ni el nudge, ni el badge. Es el modo por defecto en desarrollo.
- Cabecera `x-feedback-token`, `content-type: application/json`, timeout de 8 s vía
  `AbortSignal.timeout` (no existe helper HTTP en el repo — `src/lib/aws-explorer/s3ListObjects.ts`
  usa `fetch` pelado; este es el primer sitio que necesita timeout).
- **Nunca lanza hacia la UI en un envío**: todo fallo (red, CORS, 5xx, 429) devuelve un resultado
  tipado y el envío se encola (Fase 2). Los 4xx de validación sí se muestran, no se encolan.

## Fase 2 — Identidad y cola offline

`src/lib/feedback/identity.ts`

- Clave `lamula-process:feedback`, **separada** de `lamula-process:config`
  (`src/lib/platform/config.ts:19`), de `lamula-process:settings` y de
  `lamula-process:palette-book`. Mezclarlas ensucia tres ficheros con esquemas de validación
  propios.
- Forma: `{ v: 1, token: string, profile?: FeedbackProfile, nudge: { shownCount, snoozeUntil, submitted }, queue: QueuedSubmission[] }`.
- Token: 32 bytes de `crypto.getRandomValues` a hex. Igual que
  `composables/useFeedbackIdentity.ts:17-27` del webviewer.
- Patrón de persistencia del repo: funciones `load*`/`save*` async, guarda de `localStorage`
  ausente, `try/catch` silencioso, validación campo a campo con caída a defaults. A diferencia de
  `config.ts`/`settingsStore.ts` (que no versionan), **este sí lleva `v`** porque va a crecer: el
  perfil y la cola cambian de forma antes que las prefs de display.
- **Tauri**: `config.ts:35` hace `if (isTauri()) throw new Error('Tauri config store not implemented yet')`.
  No repetir eso acá — un throw en el arranque del feedback tumbaría la app de escritorio. Usar
  `localStorage` en ambos (la webview de Tauri lo tiene) y dejar anotado que migrar a
  `@tauri-apps/plugin-store` es trabajo del día que exista toolchain Rust.

`src/lib/feedback/queue.ts`

- **Esto es lo nuevo respecto al webviewer**, que es solo web y siempre online. Sin cola, un
  meteorólogo sin internet pierde el feedback en silencio.
- `enqueue(submission)`, `flush(client)`, `pending(): number`.
- Cada entrada lleva `clientId` (uuid) + `attempts` + `lastError`. El `clientId` viaja en
  `context.clientId`: si una respuesta se pierde pero el POST llegó, el reintento se puede
  deduplicar después mirando ese campo en la bandeja. _No se añade restricción `UNIQUE` en la base
  — el duplicado es raro y el coste de una migración más no se justifica; queda como dato de
  triage._
- `flush` se dispara: al arrancar la app, al volver `online` (`window.addEventListener('online')`)
  y al abrir el diálogo. Secuencial, no en paralelo, para no gatillar el rate-limit de 5/h.
- Tope de 20 entradas; al llenarse se descarta la **más vieja** y se avisa en el diálogo.

## Fase 3 — Política del nudge

`src/lib/feedback/nudge.ts` — funciones puras con reloj inyectado, igual que
`utils/feedback/nudge.ts` del webviewer. Dos desviaciones deliberadas:

- **El disparador no es tiempo de sesión.** Allá son 90 s de uso. Acá la app no "da valor" por
  mirar un mapa: lo da cuando se procesa algo. Disparador: **tras cerrar la primera ventana de
  producto generada en la sesión**, y nunca antes de 60 s desde el arranque.
- **"No, gracias" es permanente.** En el webviewer `calcSnoozeUntil('never')` devuelve 7 días, lo
  que contradice el botón. Acá: `submitted`-equivalente (`dismissedForever: true`), no vuelve nunca.
- Se mantiene: máximo 3 apariciones en la vida del navegador, "más tarde" pospone 3 días, tras
  enviar no vuelve a aparecer.

## Fase 4 — Contexto automático y `buildId`

`src/lib/feedback/context.ts` — `buildContext(): FeedbackContext`:

```
app: 'process', platform: 'web'|'tauri', buildId, locale, viewport, userAgent,
format, siteCode, elevationDeg, productsOpen: string[], paletteName, filtersActive: string[],
clientId
```

**Redacción obligatoria.** Nunca el nombre ni la ruta del fichero abierto, nunca muestras de
datos. Son ficheros operativos del INSMET y del IDEAM. El nombre de fichero vive hoy en
`Picked.fileName` (`src/lib/pipeline/observationMachine.ts:25-30`) y en `RecentFileEntry.label`
(`src/lib/platform/config.ts:7-11`); **ninguno de los dos entra al payload**. Formato + código de
sitio + elevación bastan para reproducir cualquier bug.

`buildId`:

- `vite.config.ts`: `define: { __BUILD_ID__: JSON.stringify(process.env.GIT_SHA ?? 'dev') }`.
- `src/app.d.ts`: `declare const __BUILD_ID__: string`.
- `.github/workflows/ci.yml`: `env: { GIT_SHA: ${{ github.sha }} }` en el paso
  `Build (cloudflare-pages)` (línea 48).
- Hoy el repo **no usa** `import.meta.env`, `$env/` ni `define` en ninguna parte: esta es la
  primera constante de build. Hacerlo en el mismo commit que el campo, o no poner el campo. En el
  webviewer `buildId` lleva meses en `'dev'` por haber separado las dos cosas.

`PUBLIC_FEEDBACK_API`: misma mecánica (`define` + declaración), **no** `$env/static/public` — con
`adapter-static` y sin `+page.server.ts` el repo no usa la maquinaria de env de SvelteKit y
meterla por un solo valor no se justifica. Valor en `ci.yml` como variable del repo, no secreto
(es una URL pública).

## Fase 5 — UI

Todo con `$_()` de `svelte-i18n`. `scripts/check-i18n.mjs` detecta castellano por acentos y `¿¡`
en `src/**/*.{svelte,ts}` y falla el `pnpm lint`; nota: **una cadena española sin acentos no la
detecta**, así que la disciplina no es opcional.

- **Menú `Ayuda`** en `src/routes/+page.svelte:556-644` (`const menus = $derived<MenuDef[]>`),
  tercer menú tras `menu.file` y `menu.window`. Items: `Enviar comentario` (icono `feedback`),
  `Mis mensajes` (icono `forum`, con `disabled` si no hay hilo). `MenuItem` ya soporta `icon`,
  `disabled`, `separator`, `submenu`, `checked` (`src/lib/nav/MenuBar.svelte:2-12`).
- **Badge** en `src/lib/windows/StatusBar.svelte`: un elemento a la derecha del `<div>` de tabs
  (hoy la barra solo lista ventanas abiertas), con punto `bg-error` cuando hay respuestas con
  `readAt === null`. Aprovechar para pasar por `$_()` las dos cadenas hardcodeadas que quedan ahí
  (`Restaurar ${w.title}` en `:36` y `sin ventanas abiertas` en `:43`) — están sin acentos y por eso
  el lint nunca las vio.
- **`FeedbackDialog.svelte`** sobre `src/lib/viewer/Modal.svelte` (ya trae Escape, backdrop,
  `role="dialog"`, `aria-modal`, `glass-panel`). Dos pestañas: _Enviar_ y _Mis mensajes_. Campos:
  ocupación (**obligatoria**, `<select>` + texto si `otro`), tipo, valoración 1-5 opcional, mensaje
  (obligatorio), y plegado opcional con nombre/email/institución/país. El perfil se precarga de
  `localStorage`: del segundo envío en adelante solo se escribe el mensaje. Estado con `$state`,
  un booleano por modal como ya hace `+page.svelte:107-109`.
  De paso, `Modal.svelte:26` y `:49` tienen `aria-label="Cerrar"` hardcodeado — una línea, mismo
  commit.
- **`FeedbackNudge.svelte`**: tarjeta abajo-derecha, por encima de la `StatusBar`. Tres acciones:
  _Dejar feedback_ / _Más tarde_ / _No, gracias_.
- **Sin Turnstile** (decisión del usuario, D51 del webviewer). Process no monta el widget y no
  carga nada de `challenges.cloudflare.com`: sería su única dependencia de red externa y en un
  puesto sin salida a internet general el captcha no resolvería nunca. El servidor exime del
  captcha a `app: 'process'` (`server/utils/feedback-policy.ts`) y a cambio aplica un cubo de
  rate-limit por IP (`noCaptcha:${ip}`, 30/h) además del de `${ip}:${token}`. El cliente de acá no
  manda `turnstileToken` y no hay nada que dar de alta en Cloudflare.
  Riesgo asumido y registrado en D51: cualquiera puede mandar `app: 'process'` y entrar sin
  captcha. El daño techo es spam en una bandeja interna.
- **i18n**: grupo nuevo `feedback.*` en `src/lib/i18n/locales/{es,en}.json` (341 líneas cada uno
  hoy, misma estructura en ambos). Subgrupos: `feedback.menu`, `feedback.dialog`, `feedback.form`,
  `feedback.roles`, `feedback.kinds`, `feedback.nudge`, `feedback.thread`, `feedback.errors`,
  `feedback.queue`.
- **Errores del servidor crudos no se traducen** (mismo criterio ya establecido en el repo): se
  muestra una frase traducida genérica y el `statusMessage` tal cual entre paréntesis.

## Fase 6 — Tests (vitest)

El proyecto `server` de `vite.config.ts` corre `src/**/*.{test,spec}.{js,ts}` en entorno node y
**excluye** `*.svelte.spec.ts`: toda la lógica tiene que vivir en módulos `.ts` puros, lo cual es
justo lo que este plan hace. No hay Playwright en este repo; no se añade.

- `nudge.spec.ts` — reloj inyectado: no antes del primer producto, no antes de 60 s, tope de 3,
  posponer 3 días, "no gracias" permanente.
- `identity.spec.ts` — JSON corrupto, `localStorage` ausente, `v` desconocida, token estable entre
  cargas.
- `queue.spec.ts` — fallo encola; `flush` vacía; reintento no duplica (`clientId`); tope de 20
  descarta la más vieja; 4xx de validación **no** encola.
- `context.spec.ts` — **afirma que el payload serializado no contiene ningún nombre de fichero**
  (sembrar un `fileName` reconocible y comprobar que no aparece en `JSON.stringify`). Es el test
  que impide la regresión de privacidad.
- `client.spec.ts` — `fetch` mockeado con `vi.fn()`: cabecera `x-feedback-token` presente, timeout
  aborta, base URL vacía apaga la feature.
- `contract.spec.ts` — `validateSubmission` devuelve claves i18n existentes en `es.json`.

## Fase 7 — Documentación

- `docs/feedback.md` (nuevo): qué se recoge, **qué NO se recoge** (la política de redacción), env
  vars, cómo se apaga, y el runbook de la bandeja compartida con enlace a la decisión 50 del
  webviewer. Un fichero, corto. En el webviewer se planeó el equivalente y nunca se escribió.
- `mkdocs.yml`: entrada en `nav` (hoy 8 entradas, línea 39-47).
- `docs/index.md`: línea en el mapa de documentación.
- `README.md`: una línea sobre las dos variables de build.

---

## Orden de ejecución y puertas

| #   | Qué                                            | Puerta                                                                                                                                                                                                                      |
| --- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Fase 0 completa en `lamula-webviewer`          | `pnpm lint && pnpm typecheck && pnpm test` verdes. `bash scripts/check-contract-drift.sh` pasa **sin cambios** (prueba de que el contrato del pipeline no se tocó). `tests/unit/dal.spec.ts` intacto.                       |
| 2   | Desplegar el webviewer al Swarm                | `OPTIONS https://webviewer.ladetec.com/api/feedback` con `Origin` permitido devuelve 204 con `access-control-allow-*` (hoy da 404); el `POST` con `app:'process'` devuelve 201; la fila sale en `psql` con `app='process'`. |
| 3   | Fases 1-2 (contrato, cliente, identidad, cola) | `pnpm test` verde, sin UI todavía.                                                                                                                                                                                          |
| 4   | Fases 3-4 (nudge, contexto, `buildId`)         | `context.spec.ts` verde — la puerta de privacidad.                                                                                                                                                                          |
| 5   | Fase 5 (UI + i18n)                             | `pnpm lint` (incluye `check-i18n`), `pnpm check`, prueba manual en navegador.                                                                                                                                               |
| 6   | Fase 6-7 (tests restantes + docs)              | `pnpm test && pnpm build`.                                                                                                                                                                                                  |

### Verificación manual final

1. Modo avión: enviar → queda encolado con aviso visible → reconectar → se envía solo, **una sola
   vez**.
2. `psql` en el Swarm: la fila llega con `app='process'`, `context.platform`, `context.buildId` con
   el SHA real, y **sin** nombre de fichero.
3. Responder desde `/admin/feedback` → recargar Process en el mismo navegador → punto rojo en la
   `StatusBar` → abrir el hilo → el punto desaparece.
4. Filtrar el admin por `app=webviewer` y por `app=process`: cada lista trae solo lo suyo; sin
   filtro trae ambas.
5. `PUBLIC_FEEDBACK_API` apuntando a un host muerto: la app abre ficheros, calcula productos y
   exporta igual. Degradación total, cero bloqueo.
6. `PUBLIC_FEEDBACK_API` vacía: ni menú `Ayuda`, ni nudge, ni badge. Es el estado de desarrollo.

## Acciones manuales fuera del código (del usuario)

1. **Env en el Swarm**: `NUXT_CORS_ORIGINS=https://process.ladetec.com` (solo producción, decidido
   por el usuario; los previews de Pages quedan fuera).
2. **Dominio propio de Process**: `process.ladetec.com` no está configurado en ningún sitio de
   este repo — `wrangler.toml` solo declara `name = "lamula-process"`, así que hoy la app sale en
   `lamula-process.pages.dev`. Hay que darlo de alta como _custom domain_ del proyecto Pages
   (panel de Cloudflare) **antes** de que el CORS del Swarm sirva de algo: si la app no se sirve
   desde ese host, el `Origin` no coincide con la allowlist.
3. Desplegar el webviewer antes de que lo de acá sirva de algo.

(Turnstile ya no hace falta: ver D51. No hay hostname que dar de alta ni site key que pasar.)

## Riesgos abiertos

- **Origen de Tauri en la allowlist de CORS**: no verificable hoy (sin toolchain Rust en el
  entorno). Si falla, el envío queda encolado — no se pierde, pero tampoco llega hasta que se
  arregle la allowlist.
- **Drift del contrato entre repos**: dos copias a mano de los mismos enums. No hay paquete
  compartido ni monorepo. Mitigación: comentario de cabecera que nombre el fichero fuente, y los
  enums son estables (no han cambiado desde la decisión 39).
- **Camino sin captcha abierto a cualquiera (D51)**: el `app: 'process'` lo declara el cliente, así
  que un script puede usarlo para saltarse Turnstile. Única barrera: el cubo por IP de 30/h. Si
  aparece spam real, lo siguiente es bajar ese límite o exigir un encabezado firmado emitido por el
  propio Swarm. Depende de que el contenedor solo sea alcanzable a través del proxy.
- **Acoplamiento de uptime**: el feedback de Process depende del Swarm del webviewer. Aceptado a
  cambio de una sola bandeja; el fallo es suave por diseño.
