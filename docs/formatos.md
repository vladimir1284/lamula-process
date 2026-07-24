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

## Formato interno — `.obs` (Vesta)

No es un formato de radar de entrada, es el **contenedor propio de Vesta**
al que el original convierte cualquier observación tras ciertas operaciones
(`Observation.pas`: "esta es convertida automáticamente a este formato").
Recibido en `test-fixtures/observations/insmet/` (4 observaciones reales del
radar Camagüey/`rdCamaguey1` + `Obs_Parser.py`, script propio del usuario de
2013 que lo decodifica).

**Gap resuelto:** el script es Python 2 (`print` statement, `xrange`,
`file()`) y usa `struct` en modo *nativo* (sin prefijo `<`/`>`/`=`), que
inserta padding de alineación distinto según la plataforma. Corrí un port
mínimo a Python 3 sin dependencias (`zlib`+`struct` de la stdlib, sin
`pylab`/`numpy`) contra los 4 archivos reales: en modo nativo de 64-bit
decodifica basura (`channel_count` de 220, campos con valores absurdos). En
modo empacado (`<`, sin alineación automática) + 1 byte de padding real
explícito en 2 structs, decodifica los 4 archivos limpio, zlib incluido,
0 fallos de descompresión. El padding es real (bytes que existen en el
archivo, alineación del record Delphi original a 4 bytes para el `double`),
no un artefacto de lectura — confirmado porque sin él los offsets de PPIs
subsiguientes se corrompen en cascada.

Layout confirmado (little-endian, empacado, sin padding automático de
`struct`; `x` = byte de padding real presente en el archivo):

| Bloque | Tamaño | Formato `struct` | Notas |
|---|---|---|---|
| Header parte 1 | 64 B | `<20s4H36s` | firma `"Vesta Observation\x1a\x00\x00"`, versión, `design` (string, ej. `VCP_31`, `VCP_11_Merged`) |
| Header parte 2 | 20 B (offset 64) | `<B2?Bd2I` | radar (código→`dRadar`), daylight, variance, dummy, `time` (OLE date, double), `ppi_count`, `channel_count` |
| Tabla de ubicaciones | `4×ppi_count` B | `<{n}I` | offset absoluto de cada bloque PPI |
| Channel desc (×`channel_count`) | 32 B c/u | `<2Bh3I3fI` | wave_length, pulse, dummy, number_of_cells, cell_length_m, num_of_sectors, beam_width_deg, met_potential, delta_potential, index |
| PPI Desc (×`ppi_count`) | 28 B | `<3BxdI2B3hI` | radar, speed, dummy, **pad**, time, channel, kind (H/V), measure (código→`dMeasure`), angle/start_az/finish_az (código 16-bit→grados, `code*360/4096`), sectorCount |
| PPI Header | 12 B (tras el Desc) | `<BxH2I` | pack_method (0/1/2, 2=zlib), **pad**, dummy, packed_size, unpacked_size |
| PPI data | `packed_size` B | zlib | descomprime a `unpacked_size` bytes → array `(sectors, gates)` de `uint8`; `dBZ = byte-80`, `m/s (MS/SW) = (byte-128)/2` |

Confirmado en los 4 fixtures reales (`c01y0815.obs`, `c02y1830.obs`,
`c27a0815VCP31.obs`, `c27a2100VCP11.obs`): radar único `rdCamaguey1`,
canal 0 = reflectividad (1800 celdas × 250 m = 450 km, S-band/10cm, pulso
largo — coincide con spec WSR-88D), canal 1 = velocidad/ancho espectral
(pulso corto, menos celdas). `design` usa nomenclatura VCP de NEXRAD
(`VCP_11`, `VCP_31`, y variantes `_Merged`) — confirma que el radar cubano
opera con convenciones WSR-88D aunque el contenedor sea propio de Vesta.
`met_potential` trae la constante de calibración real (`-36.99` dBZ en el
canal de reflectividad de estos 4 archivos) usada en `dB2dBZ()` para pasar
de dB crudo a dBZ calibrado.

**Qué NO resuelve esto:** cómo se llega de Rainbow5/NEXRAD Level II crudo
a este `.obs` — esa lógica sigue en las unidades `Translator*` que faltan
en el repo. Pero sí nos da, con datos reales y verificados, el contrato
completo del modelo interno (Observation/Channel/PPI) que tanto el parser
de Rainbow5 como el de Level II deben producir — y fixtures reales para
probarlo end-to-end sin depender de tener los parsers de formato crudo
listos primero.

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
