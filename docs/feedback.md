# Feedback de usuarios

La app puede recoger comentarios de quien la usa sin pedir cuenta ni contraseña. Los mensajes no
se quedan aquí: van a la **misma bandeja** que los del
[LAMULA WebViewer](https://github.com/LADETEC-CU/lamula-webviewer), con una columna que dice de
qué producto viene cada uno. El diseño y los descartes están en las decisiones **50** y **51** de
`docs/decisiones.md` de ese repo; el plan de implementación, en
[Plan de feedback de usuarios](plan-feedback.md).

## Qué se recoge

Con cada mensaje viaja un contexto automático, construido en `src/lib/feedback/context.ts`:

| Campo                             | Ejemplo               | Para qué                                   |
| --------------------------------- | --------------------- | ------------------------------------------ |
| `app`                             | `process`             | Separar los dos productos en la bandeja    |
| `platform`                        | `web` / `tauri`       | El mismo fallo puede no darse en los dos   |
| `buildId`                         | SHA de git, o `dev`   | Mapear el reporte a un despliegue concreto |
| `clientId`                        | UUID                  | Detectar un reenvío duplicado de la cola   |
| `locale`, `viewport`, `userAgent` | `es`, `1920x1080`     | Reproducir la pantalla del usuario         |
| `format`                          | `insmet`, `nexrad-l2` | Qué parser leyó el fichero                 |
| `siteCode`                        | `rdCMW`               | Qué radar                                  |
| `elevationDeg`                    | `1.5`                 | Qué corte miraba                           |
| `productsOpen`                    | `["map:ppi", "rhi"]`  | Qué tenía abierto al escribir              |
| `filtersActive`                   | `["speckle"]`         | Si el filtro pudo influir                  |

Y lo que el usuario escribe: ocupación (obligatoria), tipo, valoración opcional, mensaje, y
opcionalmente nombre, correo, institución y país.

## Qué NO se recoge, nunca

- **El nombre del fichero abierto.** Ni la ruta, ni la clave S3, ni la etiqueta de "recientes".
- **Ninguna muestra de los datos.** Ni un valor de reflectividad, ni una cabecera del fichero.

No es una preferencia de estilo: son ficheros operativos del INSMET y del IDEAM. El formato, el
código de sitio y la elevación bastan para reproducir cualquier fallo.

La garantía es de código, no de disciplina. `buildContext()` arma el objeto **campo a campo**
desde un tipo de entrada cerrado: no esparce el objeto del llamante, así que un campo nuevo aguas
arriba no se puede colar. `src/lib/feedback/context.spec.ts` siembra un nombre de fichero
reconocible y falla si aparece en el JSON serializado.

## Identidad sin cuentas

En el primer uso se genera un token aleatorio de 32 bytes y se guarda en `localStorage`, bajo
`lamula-process:feedback`. Viaja en la cabecera `x-feedback-token`; el servidor solo guarda su
`sha256`. Eso permite devolverle al usuario sus propios mensajes y las respuestas del equipo sin
saber quién es.

`localStorage` es **por origen**: la misma persona en el WebViewer, en Process web y en
Process/Tauri son tres identidades sin relación. No se arregla sin cuentas reales. Consecuencia
práctica: no se pueden contar usuarios únicos sumando filas de `feedback_users`.

Si `localStorage` falta o su `setItem` lanza (modo privado, kiosko bloqueado), la sesión sigue
funcionando en memoria en vez de perder mensajes en silencio.

## Sin conexión

Esta app se usa en puestos que pueden pasar horas sin internet, así que un envío que falla **no
se pierde**: se encola en `localStorage` (hasta 20; al llenarse se descarta el más antiguo y se
avisa) y se reintenta al arrancar, al volver la conexión y al abrir el diálogo.

La cola se drena de una en una, nunca en paralelo: el servidor admite 5 envíos por hora por
`${ip}:${token}` y mandarlas todas a la vez solo convertiría la cola en 429. Un fallo
reintentable para la tanda; un 4xx de validación descarta esa entrada, porque reintentarla
fallaría siempre.

Nada de esto bloquea la app: si la API está caída o mal configurada, se siguen abriendo ficheros,
calculando productos y exportando igual.

## Sin captcha

El WebViewer es público y exige Turnstile. Process **no**: cargar el script de
`challenges.cloudflare.com` sería su única dependencia de red externa, y en un puesto sin salida
a internet general el captcha no resolvería nunca. El servidor exime del captcha a
`app: 'process'` y a cambio aplica un límite por IP (30/h) al camino sin captcha. Decisión 51 del
WebViewer, con el riesgo anotado: cualquiera puede mandar `app: 'process'` y entrar sin captcha;
el daño techo es spam en una bandeja interna.

## Variables de build

Las dos son constantes de compilación (`define` en `vite.config.ts`), no variables de ejecución:
el build es estático y no hay servidor que las lea.

| Variable              | Dónde se pone                             | Si falta                            |
| --------------------- | ----------------------------------------- | ----------------------------------- |
| `PUBLIC_FEEDBACK_API` | Variable de repo en GitHub Actions        | **La feature entera queda apagada** |
| `GIT_SHA`             | `ci.yml` la pasa como `${{ github.sha }}` | `buildId` sale como `dev`           |

Valor de producción: `PUBLIC_FEEDBACK_API=https://webviewer.ladetec.com/api`.

### Cómo se apaga

Dejando `PUBLIC_FEEDBACK_API` vacía. Sin ella no se monta el menú `Ayuda`, ni el nudge, ni el
badge de la barra de estado, y no se hace ninguna petición. Es el estado por defecto en
desarrollo, y el que queda si alguien despliega sin configurar nada.

Para probarlo en local con la feature encendida:

```bash
PUBLIC_FEEDBACK_API=https://webviewer.ladetec.com/api pnpm dev
```

(El envío fallará por CORS mientras el origen de desarrollo no esté en `NUXT_CORS_ORIGINS` del
Swarm. El mensaje queda encolado, que es exactamente lo que debe pasar.)

## Cuándo aparece el aviso

El aviso no se dispara por tiempo de sesión: esta app no da valor por mirar un mapa, lo da cuando
se procesa algo. Se ofrece **al cerrar una ventana de producto**, nunca antes de 60 s desde el
arranque, como mucho 3 veces en la vida del navegador. "Más tarde" lo pospone 3 días; **"No,
gracias" es permanente**; tras enviar no vuelve a aparecer.

## Runbook de la bandeja

La bandeja vive en el WebViewer, no aquí.

1. Panel: `/admin/feedback` del WebViewer (sesión propia por HMAC; sin `NUXT_ADMIN_TOKEN`
   configurado el login está deshabilitado).
2. Filtrar por producto con el selector `app`: `process` son los de esta app. Sin filtro salen
   los dos.
3. Responder desde ahí. La respuesta le aparece al usuario en _Ayuda → Mis mensajes_, y mientras
   no la lea tiene un punto rojo en la barra de estado.
4. Si hay webhook configurado (`NUXT_FEEDBACK_WEBHOOK_URL`), el aviso ya trae el campo `app`.
