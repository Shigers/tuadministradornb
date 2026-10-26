# TuAdministradorNB — Documento de proyecto

**Estado:** Fase 1 (MVP local) implementada y verificada
**Versión:** 2.0 — 26 de octubre de 2026
**Tipo:** aplicación Flutter local-first, gratuita y sin cuenta
**Alcance inicial:** 1.000 archivos, todos los formatos habituales, una empresa por dispositivo

---

## 1. Decisiones cerradas

| Decisión | Elección |
|---|---|
| Coste | Gratis: sin servidores, suscripciones ni servicios de pago |
| Tecnología | Flutter (web, Windows y Android desde el mismo código) |
| Persistencia | Hive CE local: IndexedDB en web, archivos locales en escritorio |
| Cuentas | Acceso con cuenta mediante Supabase Auth. Los datos siguen **locales y aislados por usuario** en el dispositivo (cada cuenta tiene su propio archivo). La sincronización en la nube es Fase 2 |
| Taxonomía inicial | Genérica para cualquier empresa, editable |
| Orden material | Carpetas dentro de la app + exportación ZIP con la estructura real |
| Origen de archivos | Carpetas completas, ZIP y archivos sueltos |
| Volumen de referencia | 1.000 archivos, todos los tipos |
| Clasificación | Reglas deterministas y explicables; sin IA en Fase 1 |
| Originales | Nunca se modifican ni se eliminan |

> **Nota de alcance:** la visión multiusuario en la nube (Vercel + Supabase UE) se mantiene como Fase 2. La Fase 1 es deliberadamente local para que la aplicación sea gratuita y funcione sin infraestructura.
>
> **Acceso con cuenta (añadido tras la v2.0):** la app exige iniciar sesión con Supabase Auth antes de entrar. Supabase se usa **solo para autenticación**; los documentos y carpetas se siguen guardando en local (Hive) y ahora se aíslan por usuario con cajas separadas por id (`documents_<id>`, etc.), de modo que en un mismo dispositivo cada cuenta ve solo sus datos. La sincronización entre dispositivos y el RLS sobre tablas de Supabase llegan en la Fase 2.

---

## 2. Problema y propuesta

Una empresa acumula facturas, hojas de cálculo, contratos, nóminas, extractos y correo en carpetas sin criterio común. Encontrar un documento depende de la memoria de una persona y la información no es explotable.

**Propuesta:** añadir los archivos una vez, dejar que la app proponga qué son, confirmar con un clic y quedarse con un archivo ordenado, buscable y exportable, sin perder ni modificar ningún original.

**Principio rector:** es más grave archivar mal un documento que pedir una confirmación. El sistema prioriza la trazabilidad sobre la automatización total.

---

## 3. Alcance de la Fase 1

### Incluido y funcionando

- Alta de espacio de trabajo con nombre de empresa y responsable.
- Ingesta de archivos sueltos, carpetas completas (escritorio) y ZIP (con estructura interna conservada).
- Índice buscable con tipo, proveedor, fecha, importe y estado.
- Clasificación determinista por nombre, extensión y ruta de origen, con nivel de confianza.
- Bandeja de pendientes con acciones de archivar, cambiar tipo/carpeta y descartar.
- Árbol de carpetas editable: crear, renombrar, mover y eliminar.
- Exportación ZIP con el árbol real, nombres normalizados e `_indice.csv`.
- Detección de duplicados por SHA-256.
- Ajustes de empresa, moneda y almacenamiento, con borrado completo del espacio.
- Interfaz responsive con navegación lateral en escritorio y barra inferior en móvil.

### Fuera de alcance (por ahora)

- Multiusuario, roles e invitaciones (Fase 2).
- Sincronización en la nube y acceso desde varios dispositivos (Fase 2).
- OCR, extracción de texto e IA (Fases 3–4).
- Escaneo automático de discos o NAS.
- Edición del contenido de los documentos.

---

## 4. Arquitectura

```
Flutter (web · Windows · Android)
  │
  ├─ UI responsive (go_router + Provider)
  │
  ├─ AppController
  │    ├─ ImportService: archivos, carpetas, ZIP
  │    ├─ Classifier: reglas + fecha + importe
  │    └─ ExportService: ZIP + CSV
  │
  ▼
WorkspaceStore (interfaz)
  ├─ LocalStore → Hive CE
  │    ├─ settings
  │    ├─ documents
  │    ├─ folders
  │    └─ files (bytes)
  └─ MemoryStore → pruebas
```

- **Local-first:** la app funciona sin red y sin cuenta.
- **Persistencia abstracta:** `WorkspaceStore` permite probar toda la lógica sin Hive.
- **Sin bloqueo de UI:** los archivos se leen de uno en uno en escritorio; en web llegan en memoria.
- **Duplicados:** el hash se calcula antes de guardar y se compara con el índice existente.

---

## 5. Flujo de un archivo

```
Seleccionado → Leyendo → Clasificado → Por revisar / Archivado / Duplicado / Error
```

1. **Ingesta:** se calcula SHA-256, se detecta extensión y MIME, y se conserva la ruta de origen.
2. **Clasificación:** palabras clave del nombre y de la ruta → tipo de documento y carpeta propuesta.
3. **Metadatos:** fecha e importe se extraen solo cuando aparecen con un formato inequívoco.
4. **Revisión:** toda importación entra en la bandeja. La confianza decide si aparece «por revisar» o «sin clasificar»; archivar siempre es una acción humana.
5. **Archivado:** se asigna carpeta y nombre normalizado; el original permanece intacto.
6. **Exportación:** ZIP con la estructura de carpetas y un CSV índice.

### Umbrales

| Confianza | Acción |
|---|---|
| ≥ 0,55 | Por revisar, con tipo y carpeta propuestos |
| < 0,55 | Sin clasificar |

Ningún documento se archiva solo en la Fase 1: la confirmación humana es obligatoria. Los umbrales viven en el controlador y se ajustarán con archivos reales.

---

## 6. Taxonomía genérica

```
01 Facturas/
   Recibidas/
   Emitidas/
02 Fiscal/
   IVA/
   Modelos y declaraciones/
03 Contabilidad/
04 Laboral/
   Nóminas/
   Seguros sociales/
   Contratos/
05 Bancos/
   Extractos/
06 Clientes/
07 Proveedores/
08 Contratos y legal/
09 Presupuestos/
10 Seguros/
11 Administración pública/
12 Correspondencia/
13 Hojas de cálculo/
99 Sin clasificar/
```

- Editable: crear, renombrar, mover y eliminar carpetas.
- Los documentos sin clasificar nunca se pierden: van a `99 Sin clasificar`.

### Tipos de documento

Factura recibida, factura emitida, nómina, seguro social, extracto bancario, modelo fiscal, contrato, presupuesto, albarán, póliza, escritura, acta, certificado, carta, hoja de cálculo, imagen, XML Facturae y otro.

### Convención de nombres

```
AAAA-MM-DD__TIPO__PROVEEDOR__IMPORTE.ext
2026-03-14__FACTURA-RECIBIDA__ENDESA-ENERGIA__1234,50EUR.pdf
```

- Si falta un dato, se omite ese bloque; nunca se inventa.
- Si falta la fecha se usa `SIN-FECHA`.
- Si hay colisión, se añade `__v2`, `__v3`.
- El nombre original se conserva en el índice y es visible en la ficha.

### Formatos aceptados

PDF, JPG, PNG, TIFF, HEIC, DOC/DOCX, XLS/XLSX, CSV, PPT/PPTX, TXT, ZIP, EML/MSG, XML Facturae, JSON. Cualquier otro formato se almacena y se marca como «otro»: nada se rechaza por desconocido.

### Límites de la Fase 1

| Límite | Valor |
|---|---|
| Archivos por lote | 1.000 |
| Entradas por ZIP | 1.000 |
| Tamaño descomprimido por ZIP | 512 MB |
| ZIP anidados | No se expanden en cascada |

Si un ZIP no se puede leer, se guarda tal cual: nunca se pierde un archivo.

---

## 7. Modelo de datos

| Entidad | Campos principales |
|---|---|
| `AppSettings` | empresa, responsable, CIF, moneda, onboarding, fecha de alta |
| `FolderNode` | id, padre, nombre, ruta calculada, orden, carpeta de sistema |
| `DocumentRecord` | id, nombre original, extensión, MIME, tamaño, hash, ruta origen, carpeta, tipo, estado, proveedor, fecha, importe, moneda, confianza, notas, borrado lógico, fechas |
| Bytes | `files`: contenido por id de documento |

- Los bytes se guardan aparte del índice para que el listado sea ligero.
- Un registro corrupto se ignora al cargar y no impide abrir el archivo.
- El borrado desde la bandeja es lógico; el borrado definitivo solo ocurre al vaciar el espacio.

---

## 8. Pantallas

1. **Bienvenida** — alta del espacio con nombre de empresa y responsable.
2. **Inicio** — resumen de documentos, pendientes, espacio usado y accesos rápidos.
3. **Bandeja** — documentos por revisar con acciones de archivar, editar y descartar.
4. **Documentos** — búsqueda, filtros por tipo/estado/carpeta y ficha de detalle.
5. **Carpetas** — árbol editable con recuento de documentos.
6. **Exportar** — generación de ZIP con estructura y CSV del índice.
7. **Equipo** — estado de la Fase 1 y hoja de ruta del modo multiusuario.
8. **Ajustes** — datos de empresa, moneda, almacenamiento y borrado seguro.

---

## 9. Requisitos no funcionales

| Requisito | Objetivo |
|---|---|
| Volumen | 1.000 archivos con fluidez; diseño para 50.000 |
| Arranque | La app abre sin conexión y sin cuenta |
| Búsqueda | Resultados inmediatos sobre el índice en memoria |
| Integridad | Hash SHA-256 y detección de duplicados |
| Reversibilidad | Los originales nunca se modifican; el borrado es lógico |
| Accesibilidad | Navegación por teclado, contraste AA y textos legibles |
| Idiomas | Español inicial; textos preparados para añadir idiomas |
| Móvil | Uso completo en tableta y móvil |

---

## 10. Privacidad y seguridad

- Los datos no salen del dispositivo: no hay servidor ni telemetría.
- En web, la información vive en IndexedDB bajo el origen de la app.
- En escritorio, en la carpeta de datos de la aplicación.
- No se envía ningún archivo a terceros; no hay IA ni OCR externos.
- El usuario puede borrar todo el espacio desde Ajustes.
- Limitación honesta: al ser local, no hay copia de seguridad automática; la exportación ZIP es el mecanismo de respaldo.

---

## 11. Plan por fases

| Fase | Contenido | Estado |
|---|---|---|
| **1. MVP local** | Ingesta, índice, clasificación, carpetas, exportación, ajustes | ✅ Implementada |
| **2. Multiusuario** | Cuentas, organizaciones, roles, Supabase UE, sincronización | Pendiente |
| **3. Automatización** | Extracción de texto, OCR, reglas aprendidas, cola de revisión | Pendiente |
| **4. Escala** | Informes, conexión con Drive/OneDrive, agente de escritorio, plantillas por sector | Pendiente |

### Fase 2: criterios de aceptación

1. Dos empresas aisladas mediante RLS verificada con pruebas automáticas.
2. Invitación y roles (propietario, administrador, gestor, revisor, lectura).
3. Los archivos se sincronizan entre dispositivos sin pérdida ni duplicados.
4. La app sigue funcionando sin conexión y reconcilia al volver la red.
5. Exportación y estructura de carpetas idénticas a la Fase 1.

---

## 12. Cómo ejecutar y verificar

```powershell
# Dependencias
flutter pub get

# Calidad
flutter analyze
flutter test

# Desarrollo web
flutter run -d chrome

# Compilación de producción
flutter build web --release
```

**Estado verificado:** `flutter analyze` sin incidencias, 44 pruebas en verde (clasificador, utilidades, bienvenida y layout de las 7 pantallas en escritorio y móvil) y `flutter build web --release` correcto.

### Limitaciones conocidas del entorno

- Compilar para Windows requiere Modo desarrollador (symlinks).
- Android requiere SDK; no está instalado en este equipo.
- La revisión visual automatizada se limita al panel del navegador (~800 px).

---

## 13. Riesgos y mitigación

| Riesgo | Mitigación |
|---|---|
| Clasificación errónea por exceso de confianza | Reglas deterministas, umbral alto y revisión en bandeja |
| Pérdida de datos al ser local | Exportación ZIP periódica; borrado solo con confirmación |
| ZIP mal formado o gigante | Límites de entradas y bytes; el ZIP original se conserva |
| Nombres imposibles en Windows | Segmentos saneados y rutas únicas con `__vN` |
| Esperar escaneo del PC o NAS | Aviso explícito; agente de escritorio en fase 4 |
| Crecimiento del volumen | Índice ligero, bytes separados y lectura de uno en uno |

---

## 14. Coste

**Fase 1: 0 €.** No hay servidores, base de datos, almacenamiento ni servicios de pago. El único coste es el equipo del usuario y, si se publica en tiendas, las cuotas de las tiendas.

La Fase 2 tendrá coste de infraestructura (orientativo 45–70 $/mes con Vercel + Supabase), a decidir cuando se aborde.
