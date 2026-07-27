# Algoritmo VAD (Velocity Azimuth Display) — paquete de migración

Origen: código fuente RPG NEXRAD WSR-88D, árbol `rpg_b24_0r1_20_pub_src`.
Extraído: 2026-07-26.

Este paquete contiene el código fuente original (C) del algoritmo VAD real y de su
salida gráfica (producto **VWP — Velocity Wind Profile**, código ICD 48), más esta
explicación técnica. Sirve como base para portar tanto **(A) el cálculo del perfil de
viento** como **(B) su representación visual tipo barba-de-viento** a un proyecto nuevo.

Todo el contenido de este documento fue verificado leyendo el código fuente citado
(archivo:línea). Donde algo no pudo confirmarse en el árbol de código disponible, se
indica explícitamente en la sección "Puntos no verificados".

---

## 0. Mapa del paquete

```
01_algoritmo_vwindpro/   -> Núcleo matemático VAD + generación del producto (tarea "vwindpro")
02_config_adaptacion/    -> Parámetros configurables del algoritmo (.alg, .dea) + callbacks que los cargan
03_salida_visual/        -> Decodificación del producto + render de barbas de viento (cliente XPDT)
04_referencia_vdeal/     -> Implementación "hermana" del VAD, usada para otro propósito (NO migrar como fuente principal, solo referencia comparativa)
```

Nota importante: este es código de un sistema RPG completo (miles de archivos). Los
archivos aquí incluidos **compilan solo dentro de su árbol original** (dependen de
headers globales del RPG como `<vad.h>`, `basedata.h`, `rpgc.h`, macros `RPGC_*`,
etc., que NO están incluidos en este zip). El objetivo de este paquete no es
compilarlo tal cual, sino **tener la lógica y las fórmulas reales a la vista** para
reescribirlas en el lenguaje/framework del proyecto nuevo.

---

## 1. Qué es el algoritmo VAD

VAD (Velocity Azimuth Display) estima el viento horizontal (velocidad + dirección),
la velocidad vertical del aire y la divergencia, ajustando una curva senoidal
(primer armónico de Fourier) a los valores de velocidad radial Doppler medidos a lo
largo de un círculo completo de azimuts, a un rango deslizante constante, para una
elevación de radar dada. El producto NEXRAD resultante se llama **VWP** (Velocity /
Vertical Wind Profile).

### Dónde vive cada pieza (carpeta `01_algoritmo_vwindpro/`)

| Archivo | Contenido |
|---|---|
| `vwindpro_main.c` | Punto de entrada de la tarea `vwindpro`. Registra el proceso como "volume based" y engancha los callbacks de adaptación (líneas 36-40 del original). |
| `vwindpro_alg.c` | **Núcleo matemático VAD clásico** (ajuste de Fourier, RMS, test de simetría, velocidad vertical/divergencia). |
| `vwindpro_s_alg.c` | Lógica **Enhanced VAD (EVWP)**: VADs suplementarios en múltiples rangos y selección del mejor por altura. |
| `vwindpro_prod.c` | **Generación del producto gráfico VWP** (rejilla, ejes, barbas de viento, bloque alfanumérico). |
| `vwindpro_aux.c` | Aritmética compleja auxiliar usada por el ajuste de Fourier. |
| `vwindpro.h` | Estructuras de datos de resultados (`A317vd_t`, `A317ve_t`, `A317vs_t`) y constantes (`MISSING = -666.0f`, `VADRMS`, etc.). |
| `vwindpro.doc` | Descripción funcional corta del algoritmo (manpage interna). |
| `hplots.4` | Descripción del buffer alfanumérico interno "HPLOTS" (alimenta un producto de hodógrafa separado, no incluido aquí). |

---

## 2. Entradas del algoritmo

Fuente: buffer `COMBBASE` (base de datos combinada reflectividad+velocidad+ancho
espectral, por radial), consumido en modo "volume based" — procesa radial a radial
según llega cada corte de elevación del volumen (`vwindpro_main.c`, `vwindpro_alg.c:58`).

Por cada radial se usa:
- `azimuth` (grados) y `elevation` (grados) del radial.
- Offsets a los arrays de momentos Doppler de velocidad y reflectividad.
- Primer bin Doppler, número de bins, resolución de velocidad.
- Rango (slant range) fijo por altura, calculado a partir del **rango de análisis VAD**
  adaptable (`anal_range`, ver sección 4).

Filtros aplicados antes del ajuste:
- Sector azimutal configurable (`start_azimuth`/`end_azimuth`), con manejo correcto
  del cruce 0°/360°.
- En modo "aire despejado" (clear air), se promedian 3 bins de rango adyacentes.
- Para cada altura objetivo (lista de hasta 30 alturas, ver sección 4), se elige el
  corte de elevación disponible cuya intersección con el rango de análisis VAD más
  se acerque a esa altura (documentado literalmente en `vwindpro.doc`).

**Resumen**: entrada = velocidad radial Doppler muestreada en 360° de azimut, a rango
fijo, para un corte de elevación PPI dado, repetido para cada altura estándar
configurada.

---

## 3. El algoritmo matemático

### 3.1 Modelo físico

Si el viento horizontal es uniforme dentro del anillo circular muestreado, la
velocidad radial Doppler medida en azimut `θ` a elevación `φ` sigue:

```
V_r(θ) = -cos(θ - θ0) · |V_h| · cos(φ)  +  V_z·sin(φ)  +  W_f·sin(φ)
```

Es una función senoidal de periodo 360° en azimut. El término constante (armónico 0)
contiene la contribución vertical (velocidad vertical del aire + velocidad de caída
de precipitación); el primer armónico (senos y cosenos de `θ`) codifica velocidad y
dirección horizontal.

### 3.2 Ajuste por mínimos cuadrados (coeficientes de Fourier complejos)

Función `A317h2_vad_lsf` en `vwindpro_alg.c` (≈líneas 1899-2045). Para cada punto
válido `v_i` a azimut `a_i` (grados):

```c
Q0 = (1/N) Σ v_i
Q3 = (1/N) Σ v_i·cos(a_i)  - i·(1/N) Σ v_i·sin(a_i)
Q4 = (1/2N) Σ cos(a_i)     + i·(1/2N) Σ sin(a_i)
Q5 = (1/2N) Σ cos(2a_i)    - i·(1/2N) Σ sin(2a_i)

QQ      = Q4 - 1/(4·Q4*)
Q2      = ( Q4* - Q5/(2·Q4*) ) / QQ
Q1      = ( Q0  - Q3/(2·Q4*) ) / QQ
QQ_INT  = 1 - |Q2|²
int_coeff = (Q1 - Q2·Q1*) / QQ_INT

CF2 = Re(int_coeff)
CF3 = Im(int_coeff)
CF1 = Q0 - 2·Re(int_coeff · Q4)
```

Salida: **CF1** (término constante), **CF2, CF3** (coeficientes del primer armónico),
y `dnpt` = número de puntos válidos usados en el ajuste.

Este esquema es el algoritmo VAD clásico de **Browning & Wexler (1968)**. La misma
matemática (con otra notación: `Q0r/Q0i…Q5r/Q5i`) aparece en
`04_referencia_vdeal/vdeal_vad.c` (función `Vad_analysis`), confirmando que ambos
módulos comparten el núcleo, aunque con propósitos distintos (ver sección 7).

### 3.3 Velocidad y dirección de viento

```c
speed_horizontal   = sqrt(CF2² + CF3²) / cos(elev_rad)
dir_viento_grados  = (π − atan2(CF3, CF2)) · rad2deg      // convención: de dónde viene el viento
```

### 3.4 RMS del ajuste

```c
speed = sqrt(CF2² + CF3²)
erv_i = -cos(azm_i - dir)·speed + CF1
RMS   = sqrt( (1/N) Σ (erv_i - v_i)² )
```

### 3.5 Iteración / eliminación de valores anómalos

Controlado por `num_fit_tests` (parámetro `FT`, ver sección 4). Se repite el ciclo
ajuste→RMS→test hasta `FT` veces. `A317j2_fit_test` marca como `MISSING` cualquier
punto que se desvíe más de 1×RMS de la curva ajustada **y hacia la línea de
velocidad cero** (elimina outliers de baja magnitud, típicamente contaminación por
reflejo de tierra residual o ruido).

### 3.6 Test de simetría

`A317k2_sym_chk`: el ajuste se acepta como "simétrico" si:

```c
|CF1| < TSMY   AND   |CF1| - speed <= 0
```

donde `TSMY` es el parámetro adaptable `symmetry`. Si el término constante (ligado a
movimiento vertical) es demasiado grande respecto de la amplitud horizontal, el
viento estimado se descarta.

### 3.7 Criterio de aceptación final

Solo se acepta el resultado si `RMS < THV` (parámetro `thresh_velocity`) **y**
`sym` es verdadero.

### 3.8 Velocidad vertical y divergencia

`A317l2_vv_div`: modelo de área de superficie esférica entre cortes de elevación
consecutivos (radio efectivo `RE_M = 6371000 m` con factor de refracción `4/3`, tabla
de densidad atmosférica estándar tipo ICAO en incrementos de ~500 m desde -1125 m
hasta 21750 m). De ahí se derivan velocidad vertical `dsvw` (m/s) y divergencia `ddiv` (1/s).

Para modo precipitación, velocidad de caída de partículas (fórmula empírica basada
en reflectividad y altura):

```c
pfv = Z^0.114 · 2.65 · ( ht_sea·0.02863 + 1.01091 + ht_sea²·0.00259 )
```

### 3.9 Enhanced VAD (EVWP)

Cuando `enhanced_vad = Yes` (ver `vwindpro_s_alg.c`), además del VAD "clásico" a
rango fijo, se calculan VADs suplementarios a distintos rangos deslizantes dentro de
`[min_proc_range, max_proc_range]`. Para cada altura estándar se decide cuál
estimación es la mejor:

- Filtro de aceptación: `speed >= scale_rms·RMS` **y** `|CF1| - speed < min_symmetry`
  **y** `n_puntos >= min_points`.
- Si hay ≥4 estimaciones válidas para la misma altura: se promedia vectorialmente y
  se elige la más cercana al promedio.
- Si hay <4: se elige la de menor razón `RMS / velocidad / n_puntos`.
- El viento "oficial" se sustituye por el suplementario solo si su razón de calidad
  es mejor.

---

## 4. Parámetros de configuración / adaptación (carpeta `02_config_adaptacion/`)

### 4.1 `vad.alg` — 13 parámetros del algoritmo VAD

| Parámetro (código) | Nombre ICD | Tipo | Default | Rango | Unidad |
|---|---|---|---|---|---|
| `thresh_velocity` | RMS Threshold [THV] | double | 5.0 | 0.0 – 15.0 | m/s |
| `num_fit_tests` | Number Of Passes [FT] | int | 2 | 1 – 5 | – |
| `min_samples` | Data Points Threshold [NPTS] | int | 25 | 1 – 360 | – |
| `anal_range` | VAD Analysis Slant Range [VAD] | double | 30.0 | 1.0 – 230.0 | km |
| `start_azimuth` | Beginning Azimuth Angle [TBZ] | double | 0.0 | 0.0 – 359.9 | grados |
| `end_azimuth` | Ending Azimuth Angle [TEZ] | double | 0.0 | 0.0 – 359.9 | grados |
| `symmetry` | Symmetry Threshold [THY] | double | 7.0 | 0.0 – 20.0 | m/s |
| `enhanced_vad` | Enables Enhanced VAD logic | enum | Yes | {No, Yes} | – |
| `min_points` | EVWP Min Points Threshold | int | 25 | 0 – 100 | – |
| `min_symmetry` | EVWP Minimum Symmetry Value | float | -6.0 | -10.0 – -1.0 | – |
| `scale_rms` | EVWP RMS Scaling Factor | float | 2.0 | 1.0 – 5.0 | – |
| `min_proc_range` | EVWP Minimum Processing Range | float | 10.0 | 5.0 – 30.0 | km |
| `max_proc_range` | EVWP Maximum Processing Range | float | 120.0 | 30.0 – 120.0 | km |

> Nota: el propio `vad.alg` declara `min_points` con `value = 25.0` pero `type = int`
> — inconsistencia presente en el archivo fuente original, no una interpretación.

Estos parámetros se cargan a la estructura en memoria `vad_t Vad` mediante el
callback `vad_callback_fx.c` (incluido), identificado por el nombre de bloque
`VAD_DEA_NAME = "alg.vad"`. Luego se mapean a la estructura de trabajo interna:

```c
A317va->vad_rng   = Vad.anal_range * 1e3f;   // km -> m
A317va->minpts    = Vad.min_samples;
A317va->azm_beg   = Vad.start_azimuth;
A317va->azm_end   = Vad.end_azimuth;
A317va->th_rms    = Vad.thresh_velocity;
A317va->tsmy      = Vad.symmetry;
A317va->fit_tests = Vad.num_fit_tests;
A317va->rh        = Siteadp.rda_elev * FT_TO_M;   // altura de la antena, dato de sitio
```

### 4.2 `prod_params.dea` — alturas estándar VAD (30 niveles, metros AGL)

```
vad_rcm_heights_t.vad = 1000, 2000, 3000, ..., 20000, 22000, 24000, 25000, 26000,
                        28000, 30000, 35000, 40000, 45000, 50000;
```

Cargadas por `vad_rcm_heights_callback_fx.c` (incluido). Estas son las alturas para
las que la tarea calcula y publica el perfil de viento.

### 4.3 `prod_schedule.dea` — programación de la tarea

Contiene entradas `Prod_Schedule.vwindpro.*` (habilitación, ID de producto, VCPs
aplicables) y una entrada legado separada `Prod_Schedule.vad.*`. En este archivo de
ejemplo ambas aparecen con `disabled = Yes` — esto refleja la configuración de este
árbol de código de referencia, **no** un estado operativo real; verificar contra la
config activa de cualquier sitio real antes de asumir algo.

### 4.4 `product_attr_table_extracto_VAD.txt`

Extracto (grep) de la tabla completa de atributos de producto (3720 líneas en el
original) con solo las líneas relacionadas a VAD/VWP. Contiene el ID interno de
producto `VADTMHGT = 97`. El código ICD oficial del producto NEXRAD es **48** ("VAD
Wind Profile").

---

## 5. Salida del algoritmo — estructura de datos

Definidas en `vwindpro.h`. Por cada altura estándar y por volumen histórico
(`NVOL = 11`), el algoritmo conserva:

```c
// altura, RMS, velocidad, vertical, divergencia, dirección — indexado por corte de elevación
float htg[MAX_VAD_ELVS], rms[MAX_VAD_ELVS], shw[MAX_VAD_ELVS],
      svw[MAX_VAD_ELVS], div[MAX_VAD_ELVS], hwd[MAX_VAD_ELVS];

// indexado por altura estándar y volumen
int   nrads[MAX_VAD_HTS];        // radiales usados en el ajuste
int   elcn[MAX_VAD_HTS];         // nº de corte de elevación usado
float slrn[MAX_VAD_HTS];         // rango deslizante (km)
float hcf1, hcf2, hcf3[MAX_VAD_HTS]; // coeficientes de Fourier
float vhtg[NVOL][MAX_VAD_HTS];   // altura por volumen/altura
float vrms[NVOL][MAX_VAD_HTS];   // RMS
int   vnpt[NVOL][MAX_VAD_HTS];   // nº de puntos usados
float vhwd[NVOL][MAX_VAD_HTS];   // dirección de viento (grados)
float vshw[NVOL][MAX_VAD_HTS];   // velocidad de viento (m/s)
```

**Para replicar solo el cálculo (sin salida gráfica NEXRAD)**, esta es la estructura
mínima útil por altura: `{altura_m, velocidad_ms, direccion_grados, rms_ms,
n_puntos, coef_fourier[3]}`. Valor faltante universal: `MISSING = -666.0f`.

---

## 6. Salida visual (carpeta `03_salida_visual/`)

### 6.1 Tipo de gráfico: diagrama tiempo–altura (NO hodógrafa)

- **Eje vertical** = altura (kft AGL), hasta 30 líneas horizontales.
- **Eje horizontal** = tiempo, 11 marcas (una por volumen histórico, `NVOL=11`).
- Producto de 512×512 px en el generador original.
- Confirmado tanto en el generador (`vwindpro_prod.c`) como en el visualizador
  (`display_vad_data.c`: etiquetas `"ALT KFT"` en eje Y, `"TIME"` en eje X).

### 6.2 Símbolo por celda: barba de viento meteorológica estándar

Cada celda tiempo×altura se dibuja como una **barba de viento** (no flecha, no
letra), codificada en el paquete gráfico tipo **4** (`packet_4.c/h`):

```c
p->code = 4;
p->wind_dir = round(wd);                 // grados
p->wind_spd = round(ws * MPS_TO_KTS);    // nudos
```

Convenciones de dibujo (ver `make_windbarb.c`):
- Asta orientada según `wind_dir`.
- Banderín triangular = 50 kt.
- Barba completa = 10 kt.
- Media barba = 5 kt.
- Velocidad ≤ 2 kt → se dibuja un **círculo** (calma), no barba.
- Sin dato válido en la celda → texto **"ND"** ("No Data"), vía paquete de texto tipo 8.

**Color de la barba = calidad del ajuste (RMS), NO la velocidad** — se toma de una
tabla de color adaptable indexada por RMS en nudos (`VADRMS`).

### 6.3 Estructura de "packets" gráficos usados

| Packet | Rol en VWP | Archivos en este paquete |
|---|---|---|
| 8 (texto/símbolo con color) | Etiquetas de eje (horas, alturas), texto "ND" | `packet_8.c`, `packet_8_cvg.h` |
| 10 (vector no enlazado, valor uniforme) | Rejilla de fondo: bordes, eje de altura, eje de tiempo | `packet_10.c/h` |
| 4 (barba de viento) | Cada símbolo de viento por celda | `packet_4.c/h` |

### 6.4 Decodificación en el cliente (XPDT)

`decode.prod.c` detecta `product_code == 48` ("VAD Wind Profile") y llena una
estructura (ver `rle.h`):

```c
struct vwp {
    struct { ... } heights[30][3];   // etiquetas de altura, 3 chars
    struct { ... } times[11][5];     // etiquetas de tiempo, 5 chars
    struct wind { int color; int time; int height; int direction; int speed; } barb[30][11];
};
```

`display_vad_data.c` recorre `barb[altura][tiempo]`: si `direction < 0` dibuja "ND";
si `speed <= 2` dibuja círculo (calma); si no, llama a `make_windbarb()` y dibuja la
barba con segmentos de línea.

### 6.5 Nota: producto de hodógrafa (no incluido)

`vwindpro_alg.c`/`vwindpro_prod.c` también alimentan un buffer interno llamado
**HPLOTS** (ver `hplots.4` en carpeta 01) con hasta 52 páginas alfanuméricas de
vientos VAD. Este buffer sirve de insumo a un **producto de hodógrafa generado por
otra tarea downstream que no está en este árbol de código** — no confundir con el
diagrama tiempo-altura VWP, que es el que sí está completamente cubierto aquí.

---

## 7. Relación con `vdeal` (carpeta `04_referencia_vdeal/`) — NO es la misma fuente

`vdeal_vad.c` (tarea de "velocity dealiasing/unfolding", desambiguación de velocidad
Doppler) contiene una **reimplementación independiente** del mismo ajuste de Fourier
(función `Vad_analysis`), pero **no es el algoritmo que genera el producto VWP**:

1. Corre **antes** que `vwindpro` en la cadena de procesamiento — su salida (datos ya
   "desplegados"/sin ambigüedad Doppler) es la que consume `vwindpro` vía `COMBBASE`.
2. No usa `vad.alg`/`vad_t` — sus umbrales están codificados/derivados internamente.
3. Su VAD **no se publica como producto**; es estado interno usado solo para asistir
   el despliegue de velocidad radial ambigua.
4. Calcula VADs en múltiples rangos a lo largo del radial (más parecido en espíritu
   a la lógica EVWP que al VAD clásico de rango único), pero es una base de código
   separada, sin funciones ni estructuras compartidas con `vwindpro_alg.c`.

Se incluye únicamente como **referencia comparativa** de la misma matemática con otra
notación — no usar como fuente principal para portar el algoritmo ni el producto.

---

## 8. Guía práctica de migración

**Para (A) portar el cálculo del perfil de viento:**
1. Reescribir `A317h2_vad_lsf` (sección 3.2) — es autocontenido, solo necesita un
   array de `(azimuth, velocidad_radial)` por corte/altura y devuelve CF1/CF2/CF3.
2. Envolver con velocidad/dirección (3.3), RMS (3.4), fit-test iterativo (3.5),
   symmetry check (3.6) y criterio de aceptación (3.7).
3. Los 13 parámetros de `vad.alg` (sección 4.1) son la superficie de configuración
   completa — exponerlos como config del nuevo proyecto tal cual (incluye rangos).
4. EVWP (sección 3.9) es opcional/incremental — se puede migrar en una segunda fase.
5. Ignorar por completo las dependencias `RPGC_*`/`basedata.h` — son infraestructura
   RPG específica de cómo llegan los radiales; el nuevo proyecto solo necesita
   alimentar el ajuste con pares (azimuth, velocidad_radial) ya extraídos de su
   propia fuente de datos de radar.

**Para (B) portar la salida visual:**
1. Si el proyecto nuevo necesita el mismo formato NEXRAD exacto (barba de viento,
   grilla tiempo-altura, colores por RMS): usar sección 6 completa como spec —
   `make_windbarb.c` tiene la lógica de dibujo de barbas lista para portar a
   cualquier motor gráfico (es geometría pura: ángulos y segmentos de línea).
2. Si alcanza con visualizar el perfil de viento sin atarse al formato NEXRAD: la
   estructura mínima de salida (sección 5, versión simplificada) alcanza para
   renderizar como se prefiera (ej. gráfico de líneas velocidad/dirección vs.
   altura) — mucho más simple que replicar barbas + packets.

---

## 9. Puntos no verificados (no asumir sin confirmar)

1. No se localizó en el árbol de código disponible la tarea que consume el buffer
   `HPLOTS` para construir el producto de hodógrafa — solo se confirma que
   `vwindpro` lo genera y que `hplots.4` describe su contenido.
2. `Prod_Schedule.vwindpro.disabled = Yes` y `Prod_Schedule.vad.disabled = Yes` en
   `prod_schedule.dea` reflejan este archivo de configuración de referencia; no
   representan necesariamente el estado operativo de un sitio RPG en producción.
3. La entrada separada `Prod_Schedule.vad` (distinta de `vwindpro`) sugiere un
   producto/tarea legado llamado simplemente "vad" (posible antecesor alfanumérico
   del VWP gráfico) — su código fuente no se encontró en el árbol disponible.
4. El header `<vad.h>` (referenciado por `vad_callback_fx.c`, define el struct
   `vad_t`) no está presente en este árbol `src` — vive en un paquete de includes
   compartidos del RPG que no forma parte de esta exportación. El campo mapping en
   sección 4.1 se reconstruyó a partir del uso real en `vwindpro_alg.c`, no leyendo
   el header directamente.
