# Notas para el reporte

## Problemas reales (mensaje, causa, solución, cómo se verificó)
- (2026-11-24) `flutter analyze` sobre la base: `info - The private field _tareas could be 'final' (prefer_final_fields)`. Causa: la lista de la base nunca se reasigna. Se resolverá al sustituir la lista por la consulta a SQLite.
Etapa 2 (la lista se reemplazó por un Stream de Drift; `flutter analyze`: No issue
s found).
- (2026-11-24) `dart run build_runner build --delete-conflicting-outputs` → `W The
se options have been removed and were ignored: --delete-conflicting-outputs`. Caus
a: build_runner 2.17.1 eliminó esa opción. Solución: usar `dart run build_runner b
uild`. Verificado: generó `database.g.dart` y `flutter analyze` sin errores.
- (2026-11-24) `flutter build windows --debug` → `Building with plugins requires s
ymlink support. Please enable Developer Mode in your system settings.` Causa: los
plugins (path_provider, sqlite3) se enlazan con symlinks y Windows los bloquea sin
 Modo de desarrollador. Solución: activar el Modo de desarrollador en Configuració
n. Verificación: Se activo el modo desarrollador y ahora funciono sin problemas.
- Decisión: la tabla `Tareas` generaría una clase `Tarea` que choca con `lib/model
s/tarea.dart`. Se usó `@UseRowClass(Tarea)` para que Drift devuelva el modelo exis
tente (su constructor tiene los mismos nombres que las columnas).

## Fuentes consultadas (enlace + qué aprendí)
- https://drift.simonbinder.eu/platforms/web/ — en web Drift usa SQLite compilado a WebAssembly; hay que poner `sqlite3.wasm` y `drift_worker.dart.js` en `web/`, descargados de la **misma release** de Drift que indica `pubspec.lock`. Almacenamiento: OPFS (requiere cabeceras COOP/COEP) o IndexedDB; en modo privado puede caer a memoria.
- https://pub.dev/packages/drift_flutter — `driftDatabase(name: ...)` abre la base en la carpeta adecuada de cada plataforma; acepta `DriftWebOptions`.
- https://drift.simonbinder.eu/testing/ — para pruebas se usa `NativeDatabase.memory()` y `closeStreamsSynchronously: true` en pruebas de widgets; por eso la clase de base recibe el `QueryExecutor` en el constructor.
- Versiones vistas en pub.dev (2026-11-24): drift 2.35.4, drift_dev 2.35.3, drift_flutter 0.3.1, sqlite3 3.9.2.

## Pruebas (fecha, entorno, resultado)
| ID | Entorno | Resultado | Observaciones |
|----|---------|-----------|---------------|
| base | Windows (flutter test) | Pasa | Prueba de apertura de la base, 2026-11-24 |

Entornos disponibles (`flutter devices`, 2026-11-24): Windows (escritorio), Chrome y Edge (web).

## Uso de IA (herramienta, para qué, qué verifiqué, qué corregí)
