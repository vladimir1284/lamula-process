# LAMULA-Process

Reescritura de **Vesta | Proceso**, software de procesamiento y visualización de
radar meteorológico del Centro de Radares, Instituto de Meteorología de Cuba
(Ing. Wilfredo Pozas). Original en Delphi/VCL, código fuente vendido en
[`legacy/`](https://github.com/LADETEC-CU/vesta_process) dentro de este mismo
repo, para consulta durante todo el desarrollo.

## Por qué reescribir

El original es Windows-only (VCL), sin soporte de desarrollo activo
(Delphi/OleAuto), difícil de extender. Meta: una app que corra tanto en web
(cliente puro, sin backend) como de escritorio (Windows/Linux) desde un mismo
código base.

## Ecosistema relacionado

- [`nexrad-l3-pipeline`](https://github.com/vladimir1284/nexrad-l3-pipeline) — pipeline que produce productos NEXRAD Level III, con schema en D1.
- [`lamula-webviewer`](https://github.com/vladimir1284/lamula-webviewer) — visualizador web (Nuxt) de esos productos Level III sobre Cloudflare Pages (D1 + R2).
- **`lamula-process`** (este repo) — reescritura del procesador original: ingesta datos crudos de radar (no solo Level III ya derivado), calcula productos, corre en desktop y web.

## Mapa de la documentación

- [Alcance y prioridades](alcance.md)
- [Formatos soportados](formatos.md)
- [Stack tecnológico](stack.md)
- [Plan de implementación](plan-implementacion.md)
- [Estrategia de pruebas](pruebas.md)
- [CI/CD](ci-cd.md)
