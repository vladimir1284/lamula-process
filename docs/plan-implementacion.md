# Plan de implementación

Estado: en discusión — se llena por fases a medida que arrancamos cada una.
Ver [Alcance y prioridades](alcance.md) para el detalle de cada feature.

```mermaid
flowchart TD
  subgraph F0[Fase 0 - hoy]
    A[Scaffold SvelteKit + Tauri + pnpm]
    B[docs/ mkdocs + CI docs -> Cloudflare Pages]
  end
  subgraph F1[Fase 1 - P0]
    C[Parser Rainbow5 .vol]
    D[Parser NEXRAD Level II .ar2.bz2]
    E[Modelo Observation/Movement/Channel/Scan]
    F[Paletas .pal + escalas]
    G[Filtro speckler + supresion clutter]
  end
  subgraph F2[Fase 2 - P1]
    H[PPI]
    I[RHI]
    J[CAPPI]
    K[Overlays geo OpenLayers]
    L[Editor de escala]
  end
  subgraph F3[Fase 3 - P2]
    M[Topes/Maxs/VIL/Viento/Acumulados]
    N[Cortes EstWst/NthSth, perfil]
    O[Estadisticas + reportes + export NetCDF]
  end
  F0 --> F1 --> F2 --> F3
```

## Fase 0 — hoy

- [ ] Scaffold SvelteKit + Tauri 2 + pnpm (versiones fijadas en [stack.md](stack.md)).
- [x] `docs/` + `mkdocs.yml` + workflow de CI de docs → Cloudflare Pages.
- [ ] `.github/workflows/ci.yml` de la app — se agrega junto con el scaffold (ver [ci-cd.md](ci-cd.md), referenciar scripts que aún no existen rompería CI en cada push).

## Fase 1 — P0 (fundación)

Pendiente de detallar tareas concretas cuando arranque.

## Fase 2 — P1 (visor core)

Pendiente.

## Fase 3 — P2 (productos derivados)

Pendiente.
