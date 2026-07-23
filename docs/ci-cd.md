# CI/CD

Patrón calcado de `lamula-webviewer` (ya funciona en producción ahí):
dos workflows separados por `paths`, cada uno despliega a su propio
proyecto de Cloudflare Pages.

## `docs.yml` — activo ya

Dispara solo con cambios en `docs/**` o `mkdocs.yml`. Build con
`mkdocs-material` vía `uv`, deploy a Cloudflare Pages, proyecto
`lamula-process-docs`.

**Setup manual pendiente (fuera de este código, una vez):**

1. `wrangler pages project create lamula-process-docs --production-branch main`
2. Secrets del repo: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`.

## `ci.yml` — pendiente hasta que exista el scaffold de la app

No se agrega el archivo todavía: referenciaría scripts (`pnpm lint`,
`pnpm typecheck`, `pnpm test`, `pnpm build`) que no existen aún, y quedaría
rojo en cada push sin motivo. Se agrega junto con el scaffold de
SvelteKit+Tauri. Diseño ya acordado, calcado de `lamula-webviewer` con dos
cambios: sin paso de "contract drift" (eso es específico del pipeline L3,
no aplica acá), y sin instalación de Nuxt/Playwright hasta decidir si
usamos Playwright acá también.

Reglas fijas para cuando se escriba:

- Tests visuales/goldens **excluidos del run por defecto** (ver
  [pruebas.md](pruebas.md)) — mismo patrón que `playwright.config.ts` del
  webviewer (`testIgnore` + project separado detrás de una env var).
- Deploy de la app a Cloudflare Pages, proyecto `lamula-process` (build
  estático vía `adapter-static`, salida a `build/`).
- El build de escritorio (Tauri, Windows/Linux) **no pasa por Cloudflare
  Pages** — es un workflow de release aparte, todavía no diseñado.

## Proyectos de Cloudflare Pages (dos, separados)

| Proyecto | Contenido | Workflow |
|---|---|---|
| `lamula-process` | app web (SvelteKit build estático) | `ci.yml` (pendiente) |
| `lamula-process-docs` | sitio mkdocs | `docs.yml` |
