# Alcance y prioridades

Fuera de alcance por ahora (decisión 2026-07-23): **P3, P4, P5** — automatización
tipo "piloto automático"/OLE, tracking NMEA de avión (siembra de nubes),
calculadoras auxiliares, export MATLAB, ayuda WinHelp. Se retoman más adelante
si se necesitan.

Export **RTF** eliminado del alcance permanentemente (no aporta).

## P0 — Fundación (bloqueante)

- Sistema de parsers plugin, detección dinámica por formato de archivo.
- Modelo de datos: Observation → Movements (PPI/RHI) → Channels → Scans → Cells.
- Sistema de escalas/paletas (import `.pal`, valor→color).
- Filtro radial speckler + supresión de clutter vía template.
- Shell app: abrir archivo, config persistente.

## P1 — Visor interactivo core

- PPI (plan position indicator).
- RHI / corte vertical.
- CAPPI.
- Anillos de distancia, azimut/rango al mover mouse, lectura de valor por celda.
- Capas geo (costas/ríos/fronteras políticas) sobre OpenLayers.
- Editor de escala de color.

## P2 — Productos derivados

- Topes (echo tops).
- Máximos (column max reflectivity).
- VIL.
- Viento/Doppler.
- Acumulados de precipitación.
- Cortes Este-Oeste / Norte-Sur, perfil vertical.
- Estadísticas + reportes TXT/CSV (no RTF), regiones de análisis.
- Export NetCDF.

## Fuera de alcance (referencia, no borrar el contexto)

- **P3** — TimeSpan, animación/playback + export GIF, autopilot (watch-folder), ensemble multi-radar.
- **P4** — Tracking NMEA/GPS de avión (formato ATTEX Rusia), radio ayudas aeronáuticas, calculadoras de ecuación radar, topografía/bloqueo de haz.
- **P5** — Export MATLAB, automatización OLE/COM, ayuda WinHelp.

```mermaid
flowchart LR
  P0[P0 Fundación] --> P1[P1 Visor core]
  P1 --> P2[P2 Productos derivados]
  P2 -.fuera de alcance.-> P3[P3 Tiempo/automatización]
  P3 -.-> P4[P4 Específico de misión]
  P4 -.-> P5[P5 Evaluar/drop]
```
