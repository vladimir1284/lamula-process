# Formatos soportados

## Estructura de `test-fixtures/`

```
test-fixtures/
├── observations/        # SOLO datos crudos reales (lo que un parser real recibe)
│   ├── insmet/           # .obs (Camagüey)
│   ├── nexrad-l2/        # .gz (KMLB, Archive II)
│   └── rainbow/          # .vol (bandaS = HNS/Tegucigalpa, bandaX = HNX/La Ceiba)
└── reference/            # specs, decoders/simuladores de referencia, no son observaciones
    ├── insmet/           # Obs_Parser.py original + nuestro port verificado
    ├── nexrad-l2/        # ICD, simulador RDA 2013, referencia libL2 de NOAA, nuestro decoder verificado
    └── rainbow/          # nuestro decoder verificado (rainbow_probe.py)
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

## Formato 1 — Rainbow 5.0 (Gematronik/Leonardo-Selex)

- Extensión `.vol`, contenedor XML + blobs binarios (no XML puro).
- Confirmado en `Leeme_Process.txt` cronología 5.3.4.7, 5.3.13.1, 5.3.16.1,
  5.3.17.1-5.3.17.3 ("Rainbow5 Translator", "gematronik").
- **Sin código fuente legacy vendido**: `Process.dpr` referencia
  `Rainbow5_Translator.pas`/`Rainbow5_File.pas` pero ninguno de los dos
  archivos está en `legacy/` (mismo gap que Nexrad, ver arriba). Oráculo
  usado en su lugar: [xradar](https://github.com/openradar/xradar)
  (`xradar/io/backends/rainbow.py`), cruzado contra bytes reales.
- Sensible a locale (separador decimal) — bug documentado en el original,
  no reintroducirlo.

**Material recibido**, organizado en:

- `test-fixtures/observations/rainbow/bandaS/` — volumen real S-band, sitio
  `HNS`/Tegucigalpa (Honduras), 15 elevaciones (0.0°-30.0°), un archivo por
  momento (`dBZ`, `dBuZ`, `V`, `W`).
- `test-fixtures/observations/rainbow/bandaX/` — volumen real X-band, sitio
  `HNX`/La Ceiba (Honduras), 4 elevaciones (1.3°-5.0°), un archivo por
  momento (`dBZ`, `dBuZ`, `V`, `W`, `RhoHV`, `uPhiDP`).
- `test-fixtures/reference/rainbow/rainbow_probe.py` — nuestro decoder
  Python 3 stdlib-only, verificado contra los 10 archivos (0 fallos de
  descompresión/layout, rangos físicos plausibles en cada uno).

**Verificado de verdad** (bytes reales, no solo la lectura de xradar):
corrí `rainbow_probe.py` contra los 10 archivos completos.

Layout confirmado:

| Bloque                                      | Notas                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Header XML                                  | un único `<volume>` raíz, termina en la línea literal `<!-- END XML -->`. `volume > scan` (uno por archivo) y `volume > sensorinfo` (**hermano** de `scan`, no anidado — confirmado por posición de bytes real) con `lon`/`lat`/`alt`/`wavelen`/`beamwidth`.                                                                                                                                                                                                                                                                                                                         |
| Blobs binarios                              | tras el marcador, secuencia plana: `<BLOB blobid="N" size="S" compression="qt">\n<S bytes>\n</BLOB>\n`. `blobid` es un contador único para **todo el archivo** (no se reinicia por slice/elevación): slice 0 usa 0,1,2; slice 1 usa 3,4,5; etc. Hay un `\n` literal después del `>` de apertura, uno antes de `</BLOB>`, y uno más entre `</BLOB>` y el siguiente `<BLOB>` — los tres confirmados byte a byte.                                                                                                                                                                       |
| Compresión `qt`                             | primeros 4 bytes del payload = tamaño sin comprimir (u32 big-endian), el resto es un stream zlib crudo (`zlib.decompress`). Ningún otro valor de compresión visto en los fixtures.                                                                                                                                                                                                                                                                                                                                                                                                   |
| Por `<slice refid="N">` (una por elevación) | `posangle` = ángulo de elevación en grados. `slicedata` contiene 2× `<rayinfo refid="startangle"/"stopangle">` (ángulo por rayo, u16, único depth=16 visto en `rayinfo`) + 1× `<rawdata type="..." rays bins min max depth blobid>` (dato del momento).                                                                                                                                                                                                                                                                                                                              |
| Decode `rayinfo` (ángulo)                   | `grados = raw * 360.0 / 65536.0` — **divide por `2**depth`**, no por `2**depth-2`. Confirmado: la secuencia decodificada avanza ~1.0° entre rayos, igual al `anglestep` real del volumen.                                                                                                                                                                                                                                                                                                                                                                                            |
| Decode `rawdata` (momento)                  | u8 (depth=8: `dBZ`/`dBuZ`/`V`/`W`/`RhoHV`) o u16 (depth=16: `uPhiDP`, único caso visto). `raw=0` = sin dato/bajo umbral. Para `raw>=1`: `scale=(vmax-vmin)/(2**depth-2)`, `físico = vmin + (raw-1)*scale` — **no** la fórmula ingenua `vmin + raw*scale` (corre todo medio paso). Confirmado empíricamente: el `raw==1` real más bajo de un sweep mapea EXACTO al `vmin` declarado del slice, a 3+ decimales — coincide con la fórmula de xradar (`scale_factor=(vmax-vmin)/(2**depth-2)`, `add_offset=vmin-scale_factor`, `raw*scale_factor+add_offset`, algebraicamente idéntica). |

**Sin resolver:** `@depth` sub-byte (ej. 6-bit) y el bit-unpacking asociado
— ningún fixture lo usa, no verificado con bytes reales. Valores de
`compression` distintos de `"qt"` — no vistos. Ambigüedad `raw==1` vs
mínimo físico real cuando `vmin=0` (ej. `RhoHV`) — mismo tipo de ambigüedad
que en `.obs`/Level II, no resuelta aquí tampoco.

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
- `test-fixtures/observations/nexrad-l2/KBYX20260726_113948_V06` — archivo
  real descargado del bucket público `noaa-nexrad-level2` en AWS (radar
  KBYX, Key West FL), sin envoltorio `.gz`, **bzip2-comprimido por registro**
  (ver más abajo). A diferencia de los 3 KMLB, este es representativo de lo
  que cualquier descarga real de ese bucket entrega hoy.
- `test-fixtures/observations/nexrad-l3/` — dos productos Level III reales
  (`BYX_N0B_...`/`BYX_N0G_...`, reflectividad/velocidad super-res) del mismo
  volumen KBYX, del bucket público `unidata-nexrad-level3`, usados para
  validar geometría de gates de forma independiente (ver
  `test-fixtures/reference/nexrad-l3/l3_probe_py3.py`).

**Verificado de verdad** (no solo leído del ICD): escribí+corrí
`l2_probe_py3.py` (Python 3 stdlib) contra los 3 archivos KMLB reales
completos (43 MB cada uno descomprimidos). 0 frames corruptos en miles de
mensajes recorridos por archivo, valores de reflectividad/velocidad/ZDR/PHI/
RHO decodificados dentro de rango físicamente plausible en las 3.

Layout confirmado (big-endian):

| Bloque                     | Tamaño                                                                                                                                                                                                           | Notas                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Volume Header Record       | 24 B                                                                                                                                                                                                             | `[0:12]` ASCII tape id (`"AR2V0006.157"`), `[12:16]` fecha juliana (u32 BE, día 1 = 1970-01-01 — literal en Tabla II nota 2 del ICD, no supuesto), `[16:20]` ms del día (u32 BE), `[20:24]` ICAO sitio (`"KMLB"`). No cubierto por el ICD 2620002P (ese documento es la interfaz RDA↔RPG, no el wrapper de archivo Archive II) — layout confirmado empíricamente contra los 3 fixtures.                                                                                                                       |
| Prefijo de frame           | 12 B, siempre cero                                                                                                                                                                                               | ICD §3.2.2.2: _"the communications manager... inserts an additional 12 bytes to the ICD format message"_ — cita textual verificada contra el PDF. Es el placeholder `CTM_Header.py` (`'>3I'`), inerte en archivo.                                                                                                                                                                                                                                                                                             |
| Message Header             | 16 B                                                                                                                                                                                                             | `'>H2B2HI2H'`: message_size (halfwords), RDA_redundant_channel, message_type, id_sequence_number, julian_date, milliseconds_of_day, number_of_message_segments, message_segment_number. `RDA_Redundant_Channel=8` confirmado como "ORDA Single Channel" válido en Tabla II (no es basura).                                                                                                                                                                                                                    |
| Framing                    | fijo 2432 B para todo tipo ≠ 31 (12+16+hasta 2400 payload, zero-pad); tipo 31 **no** se rellena, tamaño exacto `12 + message_size*2` — confirmado escaneando el archivo completo (~7600 firmas), no una muestra. |
| Msg 31 — Data Header Block | 68 B                                                                                                                                                                                                             | `'>4sIHHfBBHBBBBfBBH9I'`: radar_id, collection_time, mjd, azimuth_number/angle, compression_indicator, radial_length, elevation_number/angle, 9 punteros u32 (VOL/ELV/RAD/REF/VEL/SW/ZDR/PHI/RHO). **Corrección importante**: la posición de cada puntero es fija, pero qué momento hay en cada slot NO es confiable (cortes solo-vigilancia dual-pol usan el slot "VEL" para ZDR) — hay que identificar cada bloque por su propio tag de 4 bytes (`DREF`/`DVEL`/`DZDR`/etc.), nunca por posición de puntero. |
| Msg 31 — Data Moment block | 28 B header + N gates                                                                                                                                                                                            | `'>4sIHHHHhBBff'`: tag, n_gates, range, interval, tover, snr_threshold (firmado — bug latente en el simulador de referencia que lo empaca sin signo), data_word_size (8/16 bit), scale, offset. Valor físico = `(raw-offset)/scale` para `raw>=2`; `raw=0`=bajo umbral, `raw=1`=range-folded.                                                                                                                                                                                                                 |

**Compresión — corrección importante (2026-07-26):** los 3 fixtures KMLB
originales **no** usan bzip2 (cero firmas `BZh`, `compression_indicator=0`
en cada radial) — pero esto resultó ser la excepción, no la regla. Un
archivo real recién bajado del bucket (`KBYX20260726_113948_V06`, ver
arriba) sí viene comprimido: tras el Volume Header de 24 B, el archivo es
una secuencia de registros `[4 B BE longitud][bzip2 "BZh..." de esa
longitud]`, donde CADA registro es su propio stream bzip2 independiente
(confirmado descomprimiendo con `bz2` de Python: 55 registros, 0 errores,
offset final exacto al tamaño del archivo). El parser original **no tenía
ningún soporte bzip2** — con un archivo real tiraba `no message-31 found` o
peor, con la primera librería JS probada (`bzip2` de npm, decoder puro-JS de
2014), truncaba silenciosamente cualquier registro que superara 900.000
bytes descomprimidos (varios registros reales llegan a 1.4 MB), corrompiendo
el resto del stream sin lanzar error. Solucionado migrando a `bzip2-wasm`
(libbzip2 real compilado a WASM, mismo código C que usa el `bz2` de Python)
— ver `src/lib/parsers/nexrad-l2/archive2Bzip2.ts` y su test de regresión
específico para el bug de los 900k.

**Sin resolver:** una corrida de ~177 KB de frames tipo 0 (no es tipo ICD
válido) entre dos mensajes de metadata cerca del inicio del archivo — no
rompe el parseo (el stride fijo de 2432 B lo atraviesa igual) pero la causa
no está confirmada. Qué significa exactamente "0006" en `AR2V0006` — no
está en el ICD 2620002P (ese documento no cubre el wrapper de archivo).

**Validación cruzada de geometría de gates contra Level III (2026-07-26):**
motivada por duda de que la distancia/gate no se estuviera leyendo bien.
Con el bug de bzip2 arriba corregido, se descargó también Level III
(reflectividad N0B + velocidad N0G, mismo volumen KBYX) para verificar
`rangeToFirstGateM`/`gateLengthM` contra un producto RPG independiente, no
solo re-derivar los mismos bytes de Level II. Decoder de referencia en
`test-fixtures/reference/nexrad-l3/l3_probe_py3.py` (grounded contra
Py-ART, no contra un ICD PDF — no hay uno de Level III en este repo).
Tres coincidencias independientes contra el primer corte REF decodificado
por Level II: cantidad de radiales (720 == 720), azimut del primer radial
(358.25° L3 vs 358.248° L2) y espaciado de gate (`range_scale_raw × 0.25 =
249.75m` L3 vs `250m` L2). Conclusión: la matemática de rango/gate de Level
II (`message31.ts`) ya era correcta — el bug real era la falta de soporte
bzip2 de arriba, no un error de unidades/off-by-one.

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
`file()`) y usa `struct` en modo _nativo_ (sin prefijo `<`/`>`/`=`), que
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

| Bloque                          | Tamaño              | Formato `struct` | Notas                                                                                                                                                               |
| ------------------------------- | ------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Header parte 1                  | 64 B                | `<20s4H36s`      | firma `"Vesta Observation\x1a\x00\x00"`, versión, `design` (string, ej. `VCP_31`, `VCP_11_Merged`)                                                                  |
| Header parte 2                  | 20 B (offset 64)    | `<B2?Bd2I`       | radar (código→`dRadar`), daylight, variance, dummy, `time` (OLE date, double), `ppi_count`, `channel_count`                                                         |
| Tabla de ubicaciones            | `4×ppi_count` B     | `<{n}I`          | offset absoluto de cada bloque PPI                                                                                                                                  |
| Channel desc (×`channel_count`) | 32 B c/u            | `<2Bh3I3fI`      | wave_length, pulse, dummy, number_of_cells, cell_length_m, num_of_sectors, beam_width_deg, met_potential, delta_potential, index                                    |
| PPI Desc (×`ppi_count`)         | 28 B                | `<3BxdI2B3hI`    | radar, speed, dummy, **pad**, time, channel, kind (H/V), measure (código→`dMeasure`), angle/start_az/finish_az (código 16-bit→grados, `code*360/4096`), sectorCount |
| PPI Header                      | 12 B (tras el Desc) | `<BxH2I`         | pack_method (0/1/2, 2=zlib), **pad**, dummy, packed_size, unpacked_size                                                                                             |
| PPI data                        | `packed_size` B     | zlib             | descomprime a `unpacked_size` bytes → array `(sectors, gates)` de `uint8`; `dBZ = byte-80`, `m/s (MS/SW) = (byte-128)/2`                                            |

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

**Parser `.obs` (`src/lib/parsers/insmet/`), notas del parseo real:**

- El campo `number_of_cells` del channel desc **no es fiable** para el
  canal 1 (velocidad/ancho espectral): en los 4 fixtures reales, el bloque
  PPI decodificado siempre tiene el mismo ancho de fila que el canal 0
  (1800 gates), sin importar lo que diga `number_of_cells` del canal 1
  (450/540 según el archivo). El único valor consistente y verificado es
  `unpacked_size / sector_count` (del PPI Header/Desc, no del channel
  desc) — así es como el parser deriva `Scan.numGates`, ignorando
  deliberadamente `number_of_cells`.
- Un mismo momento (ej. `dBZ`) puede venir de **dos canales físicos
  distintos** dentro de una misma observación: cortes "batch"/split-cut
  alternan reflectividad de pulso largo (canal 0) y de pulso corto (canal
  1, junto con V/W) en distintas elevaciones — confirmado en
  `c02y1830.obs`, donde el canal 1 también trae PPIs `unDBZ` con su propio
  `met_potential` (`-26.99` vs `-36.99` del canal 0). El parser agrupa por
  el par `(índice de canal físico, momento)`, no solo por momento (a
  diferencia de NEXRAD L2), para no perder esa calibración distinta.
- `.obs` no da ángulos por rayo ni rango al primer gate: solo un par
  `start_az`/`finish_az` y un `sectorCount` por PPI. En los 4 fixtures
  siempre es `start=0, finish=360, sectorCount=360` (1°/sector exacto), así
  que el parser subdivide uniformemente ese rango — no es un dato
  inventado, pero tampoco literal por-rayo; revisar si aparece algún
  fixture con sector parcial. `rangeToFirstGateM` se asume 0 (no hay campo
  para esto en el contenedor).
- Medidas soportadas: solo `unDBZ` (byte-80), `unMS`→`V` y `unSW`→`W`
  (ambas `(byte-128)/2`) — las únicas ejercitadas por fixtures reales.
  `unDB` (necesita la corrección `dB2dBZ()` con rango, nunca vista en
  datos reales) y el resto (`ZDR`/`uPhiDP`/`RhoHV`/`KDP`/...) lanzan error
  en vez de adivinar una fórmula. El propio `Obs_Parser.py` invierte el
  signo de `unMS` con un comentario `# TODO speed sign correction` del
  autor original — no se replica esa inversión aquí por ser una duda del
  propio autor, no una convención confirmada.
- `wave_length` es un código (`dWaveLength` en `Obs_Parser.py`:
  `0=wl3cm, 1=wl10cm, 2=wl5cm`), no metros directos — el parser traduce el
  código, no asume que el byte crudo ya está en metros.

## Fuera de alcance de parsing (por ahora)

- NMEA/ATTEX (Rusia) — tracking de avión, es P4.
- NetCDF — solo **export**, no formato de entrada.

## Necesidades de fixtures

Datos crudos en `test-fixtures/observations/<formato>/`, material de
referencia (specs, decoders/simuladores) en `test-fixtures/reference/<formato>/`.

**rainbow5/** — recibido y verificado (2026-07-24): `bandaS` (15 elevaciones,
`dBZ`/`dBuZ`/`V`/`W`) y `bandaX` (4 elevaciones, `dBZ`/`dBuZ`/`V`/`W`/
`RhoHV`/`uPhiDP`), 0 fallos de descompresión/layout en los 10 archivos.
Cada momento va en su propio archivo `.vol` (no hay un volumen
multi-momento en un solo archivo entre los fixtures recibidos). Pendiente
todavía:

- Caso `anglestep < 1°` (bug histórico de sectores, changelog 5.3.17.1-3) —
  los fixtures actuales usan `anglestep=1`.
- Volumen con RHI (corte vertical) — los fixtures actuales son solo PPI.
- `@depth` sub-byte (ej. 6-bit) — ningún fixture actual lo usa.
- Volumen parcial/corrupto para probar manejo de error.

**nexrad-l2/** — recibido y verificado (2026-07-23): 3 archivos reales KMLB
(`.gz`, wrapper NCDC), 0 frames corruptos en los 3, momentos REF/VEL/SW/
ZDR/PHI/RHO decodificados en rango físico plausible. Pendiente todavía:
volumen parcial/corrupto para probar manejo de error (los 3 que tenemos son
casos felices completos).
