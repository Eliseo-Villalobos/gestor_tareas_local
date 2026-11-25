# Notas para el reporte

## Problemas reales (mensaje, causa, solución, cómo se verificó)
- (2026-11-24) `flutter analyze` sobre la base: `info - The private field _tareas could be 'final' (prefer_final_fields)`. Causa: la lista de la base nunca se reasigna. Se resolverá al sustituir la lista por la consulta a SQLite.

## Fuentes consultadas (enlace + qué aprendí)
- https://drift.simonbinder.eu/platforms/web/ — en web Drift usa SQLite compilado a WebAssembly; hay que poner `sqlite3.wasm` y `drift_worker.dart.js` en `web/`, descargados de la **misma release** de Drift que indica `pubspec.lock`. Almacenamiento: OPFS (requiere cabeceras COOP/COEP) o IndexedDB; en modo privado puede caer a memoria.
- https://pub.dev/packages/drift_flutter — `driftDatabase(name: ...)` abre la base en la carpeta adecuada de cada plataforma; acepta `DriftWebOptions`.
- https://drift.simonbinder.eu/testing/ — para pruebas se usa `NativeDatabase.memory()` y `closeStreamsSynchronously: true` en pruebas de widgets; por eso la clase de base recibe el `QueryExecutor` en el constructor.
- Versiones vistas en pub.dev (2026-11-24): drift 2.35.4, drift_dev 2.35.3, drift_flutter 0.3.1, sqlite3 3.9.2.

## Pruebas (fecha, entorno, resultado)
| ID | Entorno | Resultado | Observaciones |
|----|---------|-----------|---------------|
| base | Windows (flutter test) | Pasa | Prueba de apertura de la base, 2026-11-24 |

Entornos disponibles (`flutter devices`, 2026-11-24): Windows (escritorio), Chrome y Edge (web). Sin dispositivo Android detectado.

## Uso de IA (herramienta, para qué, qué verifiqué, qué corregí)
