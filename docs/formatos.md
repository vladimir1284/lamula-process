# Formatos soportados

## Estructura de `test-fixtures/`

```
test-fixtures/
├── observations/        # SOLO datos crudos reales (lo que un parser real recibe)
│   ├── insmet/           # .obs (Camagüey)
│   └── nexrad-l2/        # .gz (KMLB, Archive II)
└── reference/            # specs, decoders/simuladores de referencia, no son observaciones
    ├── insmet/           # Obs_Parser.py original + nuestro port verificado
    └── nexrad-l2/        # ICD, simulador RDA 2013, referencia libL2 de NOAA, nuestro decoder verificado
```

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

## Formato 2 — NEXRAD Level II (Archive II)

- **Ya presente en el original**, no es feature nueva: `Shell_Process.pas`
  importa `Nexrad_File`/`tsqBZip2`, comentario `Nexrad .ar2.bz2 -> vcp 11`,
  instancia `TNexradMessage.Create(Obs, MS)`, nombres de sitio reales
  (`KMLB`, `CCMW`/Camagüey, `CCSB`).
- Desconocido si el original soporta también Level III/NIDS — sin
  evidencia ninguna forma.

**Material recibido**, organizado en:

- `test-fixtures/observations/nexrad-l2/` — 3 archivos reales de Level II
  del radar KMLB (Melbourne, FL), `.gz` (envoltorio NCDC, no LDM
  tiempo-real). Esto es lo único que un parser real recibe como input.
- `test-fixtures/reference/nexrad-l2/RDA_RPG_2620002P.pdf` — ICD oficial
  NOAA/ROC ("Interface Control Document for the RDA/RPG").
- `test-fixtures/reference/nexrad-l2/libl2_reference/` — subset del decoder
  de referencia en C de NOAA ROC (`libl2.c`, `parse_ldm_file.c`,
  `testlibl2.c`, man page); depende de headers del SDK ORPG no incluidos,
  no compila standalone, sirve solo de referencia de structs/lógica. Se
  descartaron los scripts/makefiles internos de ROC del zip original — ver
  `NOTE.md` ahí mismo.
- `test-fixtures/reference/nexrad-l2/rda_simulator_2013/` — módulos Python 2
  escritos por el usuario en 2013 (`MSG_Header.py`, `Digital_Radar_Data.py`,
  `VCP_Data.py`, `CODE_messages.py`, etc.). **No son un decoder**, son un
  simulador RDA que arma mensajes Level II sintéticos para probar el path
  de ingesta de Vesta, hardcodeado a `RDA_Id='CCMW'` y lat/long de
  Camagüey; sus `struct.pack('>...')` sí son oro porque citan tabla/página
  exacta del ICD.
- `test-fixtures/reference/nexrad-l2/l2_probe_py3.py` — nuestro decoder
  Python 3 verificado (ver abajo).

**Verificado de verdad** (no solo leído del ICD): escribí+corrí
`l2_probe_py3.py` (Python 3 stdlib) contra los 3 archivos KMLB reales
completos (43 MB cada uno descomprimidos). 0 frames corruptos en miles de
mensajes recorridos por archivo, valores de reflectividad/velocidad/ZDR/PHI/
RHO decodificados dentro de rango físicamente plausible en las 3.

Layout confirmado (big-endian):

| Bloque | Tamaño | Notas |
|---|---|---|
| Volume Header Record | 24 B | `[0:12]` ASCII tape id (`"AR2V0006.157"`), `[12:16]` fecha juliana (u32 BE, día 1 = 1970-01-01 — literal en Tabla II nota 2 del ICD, no supuesto), `[16:20]` ms del día (u32 BE), `[20:24]` ICAO sitio (`"KMLB"`). No cubierto por el ICD 2620002P (ese documento es la interfaz RDA↔RPG, no el wrapper de archivo Archive II) — layout confirmado empíricamente contra los 3 fixtures. |
| Prefijo de frame | 12 B, siempre cero | ICD §3.2.2.2: *"the communications manager... inserts an additional 12 bytes to the ICD format message"* — cita textual verificada contra el PDF. Es el placeholder `CTM_Header.py` (`'>3I'`), inerte en archivo. |
| Message Header | 16 B | `'>H2B2HI2H'`: message_size (halfwords), RDA_redundant_channel, message_type, id_sequence_number, julian_date, milliseconds_of_day, number_of_message_segments, message_segment_number. `RDA_Redundant_Channel=8` confirmado como "ORDA Single Channel" válido en Tabla II (no es basura). |
| Framing | fijo 2432 B para todo tipo ≠ 31 (12+16+hasta 2400 payload, zero-pad); tipo 31 **no** se rellena, tamaño exacto `12 + message_size*2` — confirmado escaneando el archivo completo (~7600 firmas), no una muestra. |
| Msg 31 — Data Header Block | 68 B | `'>4sIHHfBBHBBBBfBBH9I'`: radar_id, collection_time, mjd, azimuth_number/angle, compression_indicator, radial_length, elevation_number/angle, 9 punteros u32 (VOL/ELV/RAD/REF/VEL/SW/ZDR/PHI/RHO). **Corrección importante**: la posición de cada puntero es fija, pero qué momento hay en cada slot NO es confiable (cortes solo-vigilancia dual-pol usan el slot "VEL" para ZDR) — hay que identificar cada bloque por su propio tag de 4 bytes (`DREF`/`DVEL`/`DZDR`/etc.), nunca por posición de puntero. |
| Msg 31 — Data Moment block | 28 B header + N gates | `'>4sIHHHHhBBff'`: tag, n_gates, range, interval, tover, snr_threshold (firmado — bug latente en el simulador de referencia que lo empaca sin signo), data_word_size (8/16 bit), scale, offset. Valor físico = `(raw-offset)/scale` para `raw>=2`; `raw=0`=bajo umbral, `raw=1`=range-folded. |

**Compresión: NO usa bzip2** en estos 3 archivos — cero ocurrencias de la
firma `BZh` en 43 MB, y el propio campo `compression_indicator` del header
Msg 31 lee 0 ("uncompressed") en cada radial muestreado. Esto contradice la
suposición común de que `AR2V0006` implica bzip2 — al menos para este
sitio/build no aplica.

**Sin resolver:** una corrida de ~177 KB de frames tipo 0 (no es tipo ICD
válido) entre dos mensajes de metadata cerca del inicio del archivo — no
rompe el parseo (el stride fijo de 2432 B lo atraviesa igual) pero la causa
no está confirmada. Qué significa exactamente "0006" en `AR2V0006` — no
está en el ICD 2620002P (ese documento no cubre el wrapper de archivo).

## Formato interno — `.obs` (Vesta)

No es un formato de radar de entrada, es el **contenedor propio de Vesta**
al que el original convierte cualquier observación tras ciertas operaciones
(`Observation.pas`: "esta es convertida automáticamente a este formato").
Datos crudos reales en `test-fixtures/observations/insmet/` (4
observaciones del radar Camagüey/`rdCamaguey1`). Material de referencia en
`test-fixtures/reference/insmet/`: `Obs_Parser.py` (script propio del
usuario, 2013, que lo decodifica) y `obs_probe_py3.py` (nuestro port
verificado, ver abajo).

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

Datos crudos en `test-fixtures/observations/<formato>/`, material de
referencia (specs, decoders/simuladores) en `test-fixtures/reference/<formato>/`.

**rainbow5/**

- Volumen reflectividad simple (single channel, PPI 360°).
- Volumen multicanal (reflectividad + velocidad Doppler + ancho espectral).
- Caso `anglestep < 1°` (bug histórico de sectores, changelog 5.3.17.1-3).
- Caso con sectores ≠ 360 (valida fix de orden de sectores).
- Volumen con RHI (corte vertical), no solo PPI.

**nexrad-l2/** — recibido y verificado (2026-07-23): 3 archivos reales KMLB
(`.gz`, wrapper NCDC), 0 frames corruptos en los 3, momentos REF/VEL/SW/
ZDR/PHI/RHO decodificados en rango físico plausible. Pendiente todavía:
volumen parcial/corrupto para probar manejo de error (los 3 que tenemos son
casos felices completos).
