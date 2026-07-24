# Estrategia de pruebas

## Principio: nada de tests visuales fijos en CI por defecto

Patrón heredado de `lamula-webviewer` (funciona bien ahí, se replica igual
acá): mientras la UI está en flujo constante, los goldens visuales (captura
de pixel exacto) se **excluyen del run por defecto** — cualquier cambio de
layout los invalida y el costo de mantenerlos alineados supera lo que
protegen a este ritmo de cambio.

- Tests funcionales (unit + e2e no-visuales) sí corren siempre en CI.
- Goldens visuales viven en su propio archivo/proyecto de test, excluido por
  defecto (`testIgnore` / project separado en Playwright), y se activan a
  demanda con una env var explícita (ej. `GOLDENS=1`).
- Reactivar goldens en CI por defecto solo cuando el layout se estabilice —
  decisión explícita futura, no automática.

## Fixtures de datos crudos

Ver [Formatos soportados](formatos.md#necesidades-de-fixtures) para la lista
de observaciones necesarias por formato. Ubicación: `test-fixtures/observations/<formato>/`.

**Recibido y verificado (2026-07-23):** `test-fixtures/observations/insmet/`
— 4 observaciones reales del radar Camagüey en formato interno `.obs`
(`c01y0815.obs`, `c02y1830.obs`, `c27a0815VCP31.obs`, `c27a2100VCP11.obs`) +
`Obs_Parser.py` (parser de referencia). Decodificados los 4 con un port a
Python 3, 0 fallos — ver [formatos.md](formatos.md#formato-interno-obs-vesta)
para el layout de bytes confirmado. Cubren VCP_11/VCP_31 (con y sin
`_Merged`), 3 momentos (dBZ/velocidad/spectrum width) — sirven de oráculo
para probar el modelo Observation/Channel/PPI y el render de PPI sin
depender de tener listos los parsers de Rainbow5/Level II crudo.

**Pendiente:** muestras crudas pre-conversión (`.vol` Rainbow5, `.ar2`/
`.ar2.bz2` NEXRAD Level II) — los `.obs` ya están post-traducidos, no
prueban el parser de formato crudo en sí.

## Capturas de referencia del original

Una carpeta por feature en `docs/reference/screenshots/<slug>/`, mínimo 1
captura mostrando el resultado esperado corriendo el original (o su
instalador legado). Si una feature no se puede correr, se marca pendiente en
vez de improvisar el resultado esperado.

P0/P1: `ppi`, `rhi`, `cappi`, `scale-editor`, `borders-overlay`, `distance-rings`

P2: `tops`, `maxs`, `vil`, `wind`, `accumulate`, `estwst-nthsth`, `profile`,
`statistics-report`, `netcdf-export`
