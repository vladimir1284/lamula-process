# Stack tecnológico

Versiones fijadas 2026-07-23 (revisar contra registro antes de cada
instalación mayor — esto es un snapshot, no una garantía a futuro).

| Paquete                  | Versión | Nota                                                                                                                                          |
| ------------------------ | ------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Node.js                  | 24.x    | LTS activo                                                                                                                                    |
| pnpm                     | 11.17.0 |                                                                                                                                               |
| @sveltejs/kit            | 2.70.1  |                                                                                                                                               |
| svelte                   | 5.56.7  | Svelte 5 (runes)                                                                                                                              |
| vite                     | 8.1.5   | dentro del peer range de kit                                                                                                                  |
| @sveltejs/adapter-static | 3.0.10  | build SPA/SSG para Cloudflare Pages y Tauri                                                                                                   |
| typescript               | 6.0.3   | **no 7.0.2**: SvelteKit/svelte-check declaran peer `^5.3.3\|\|^6.0.0`, no `^7` todavía                                                        |
| @tauri-apps/cli          | 2.11.4  | Tauri v2 estable                                                                                                                              |
| @tauri-apps/api          | 2.11.1  |                                                                                                                                               |
| tailwindcss              | 4.3.3   |                                                                                                                                               |
| shadcn-svelte            | 1.4.2   | ya estable, no `next`                                                                                                                         |
| xstate                   | 5.32.5  | flujos de procesamiento                                                                                                                       |
| ol (OpenLayers)          | 10.9.0  | mapa principal                                                                                                                                |
| svelte-i18n              | 4.0.1   |                                                                                                                                               |
| mkdocs                   | 1.6.1   |                                                                                                                                               |
| mkdocs-material          | 9.7.7   | mermaid vía `pymdownx.superfences`, sin plugin extra                                                                                          |
| happy-dom                | 20.11.1 | entorno DOM para specs que tocan `window`/`localStorage` (`// @vitest-environment happy-dom` por archivo, no cambia el project vitest global) |

## Decisiones pendientes de validar

- TypeScript 6.0.3 vs 7.x: revisar cuando SvelteKit amplíe el peer range.
- Leaflet como fallback de mapas si OpenLayers resulta pesado para overlay
  polar (PPI) — evaluar una vez que exista un prototipo de render de PPI.
