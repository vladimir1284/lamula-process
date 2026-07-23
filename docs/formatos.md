# Formatos soportados

## Gap de código fuente

`legacy/` **no contiene** el código real de los traductores/parsers. Unidades
referenciadas por `Observation.pas` y `Shell_Process.pas` pero ausentes del
repo clonado: `Translator.pas`, `Translators.pas`, `Nexrad_Translator.pas`,
`Nexrad_File.pas`, `tsqBZip2.pas`, `Movement.pas`, `Plane.pas`,
`Description.pas`, `Measure.pas`, `Angle.pas`. Confirmado con `find` +
`git log --all` (un solo commit squash, nunca estuvieron). No existe repo
hermano en el org LADETEC-CU con estas unidades.

**Consecuencia:** no hay lógica original que portar para los parsers.
Implementación contra especificación pública de cada formato.

## Formato 1 — Rainbow 5.0 (Gematronik)

- Extensión `.vol`, XML propietario.
- Confirmado en `Leeme_Process.txt` ccronología 5.3.4.7, 5.3.13.1, 5.3.16.1,
  5.3.17.1-5.3.17.3 ("Rainbow5 Translator", "gematronik").
- Doc: especificación ICD de Leonardo/Selex-Gematronik (por conseguir).
- Sensible a locale (separador decimal) — bug documentado en el original,
  no reintroducirlo.

## Formato 2 — NEXRAD Level II (Archive II / ORPG)

- Extensión `.ar2` / `.ar2.bz2` (bzip2).
- **Ya presente en el original**, no es feature nueva: `Shell_Process.pas`
  importa `Nexrad_File`/`tsqBZip2`, comentario `Nexrad .ar2.bz2 -> vcp 11`,
  instancia `TNexradMessage.Create(Obs, MS)`, nombres de sitio reales
  (`KMLB`, `CCMW`/Camagüey, `CCSB`).
- Doc: ICD público NOAA/ROC "Interface Control Document for the Archive
  II/User".
- Desconocido si el original soporta también Level III/NIDS — sin
  evidencia ninguna forma.

## Fuera de alcance de parsing (por ahora)

- NMEA/ATTEX (Rusia) — tracking de avión, es P4.
- NetCDF — solo **export**, no formato de entrada.

## Necesidades de fixtures

Ubicación: `test-fixtures/observations/<formato>/`.

**rainbow5/**

- Volumen reflectividad simple (single channel, PPI 360°).
- Volumen multicanal (reflectividad + velocidad Doppler + ancho espectral).
- Caso `anglestep < 1°` (bug histórico de sectores, changelog 5.3.17.1-3).
- Caso con sectores ≠ 360 (valida fix de orden de sectores).
- Volumen con RHI (corte vertical), no solo PPI.

**nexrad-l2/**

- `.ar2.bz2` VCP 11 completo, sitio real.
- Con velocidad Doppler + spectrum width (canales múltiples).
- Volumen parcial/corrupto (validar manejo de error, no solo caso feliz).
