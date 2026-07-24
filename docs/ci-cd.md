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

## `ci.yml` — activo ya

Calcado de `lamula-webviewer` con dos diferencias: sin paso de "contract
drift" (específico del pipeline L3, no aplica acá) y sin Playwright (no
hay e2e todavía — se agrega cuando exista UI real que valga la pena probar
end-to-end; en ese punto, aplicar la misma regla de abajo).

Pasos: install → lint (prettier+eslint) → typecheck (`pnpm check`) → unit
tests (vitest) → build (`adapter-static` → `build/`) → deploy a Cloudflare
Pages, proyecto `lamula-process`.

Regla fija para cuando se agregue e2e/Playwright: tests visuales/goldens
**excluidos del run por defecto** (ver [pruebas.md](pruebas.md)) — mismo
patrón que `playwright.config.ts` del webviewer (`testIgnore` + project
separado detrás de una env var).

El build de escritorio (Tauri, Windows/Linux) **no pasa por Cloudflare
Pages** — es un workflow de release aparte, todavía no diseñado. Requiere
runners con toolchain Rust (`dtolnay/rust-toolchain` o similar), ausente en
este sandbox de desarrollo — no se puede probar `cargo build`/`tauri dev`
localmente acá, solo se verificó que `tauri init` generó `src-tauri/`
correctamente.

**Setup manual pendiente (fuera de este código, una vez):**

1. `wrangler pages project create lamula-process --production-branch main`
2. Confirmar que los secrets `CLOUDFLARE_API_TOKEN`/`CLOUDFLARE_ACCOUNT_ID`
   del repo apuntan a un token scoped a Cloudflare Pages, no uno de admin
   total de la cuenta.

`wrangler.toml` en la raíz del repo pertenece a la app (`lamula-process`,
`pages_build_output_dir = "build"`) porque el scaffold de SvelteKit vive en
la raíz junto a `legacy/` y `docs/`. El deploy de docs no necesita su propio
`wrangler.toml` — `docs.yml` pasa `--project-name` explícito al invocar
wrangler, igual que en `lamula-webviewer`.

## Proyectos de Cloudflare Pages (dos, separados)

| Proyecto              | Contenido                          | Workflow             |
| --------------------- | ---------------------------------- | -------------------- |
| `lamula-process`      | app web (SvelteKit build estático) | `ci.yml`             |
| `lamula-process-docs` | sitio mkdocs                       | `docs.yml`           |
