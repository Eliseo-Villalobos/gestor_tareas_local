# Notas para el reporte

## Problemas reales (mensaje, causa, solución, cómo se verificó)
- (2026-11-24) `flutter analyze` sobre la base: `info - The private field _tareas could be 'final' (prefer_final_fields)`. Causa: la lista de la base nunca se reasigna. **Resuelto** en Etapa 2 (la lista se reemplazó por un Stream de Drift; `flutter analyze`: No issues found).
- (2026-11-24) `dart run build_runner build --delete-conflicting-outputs` → `W These options have been removed and were ignored: --delete-conflicting-outputs`. Causa: build_runner 2.17.1 eliminó esa opción. Solución: usar `dart run build_runner build`. Verificado: generó `database.g.dart` y `flutter analyze` sin errores.
- (2026-11-24) `flutter build windows --debug` → `Building with plugins requires symlink support. Please enable Developer Mode in your system settings.` Causa: los plugins (path_provider, sqlite3) se enlazan con symlinks y Windows los bloquea sin Modo de desarrollador. Solución: activar el Modo de desarrollador en Configuración. Verificación: se activó el Modo de desarrollador y `flutter run -d windows` funcionó sin problemas.
- Decisión: la tabla `Tareas` generaría una clase `Tarea` que choca con `lib/models/tarea.dart`. Se usó `@UseRowClass(Tarea)` para que Drift devuelva el modelo existente (su constructor tiene los mismos nombres que las columnas).

## Fuentes consultadas (enlace + qué aprendí)
- https://drift.simonbinder.eu/platforms/web/ — en web Drift usa SQLite compilado a WebAssembly; hay que poner `sqlite3.wasm` y `drift_worker.dart.js` en `web/`, descargados de la **misma release** de Drift que indica `pubspec.lock`. Almacenamiento: OPFS (requiere cabeceras COOP/COEP) o IndexedDB; en modo privado puede caer a memoria.
- https://pub.dev/packages/drift_flutter — `driftDatabase(name: ...)` abre la base en la carpeta adecuada de cada plataforma; acepta `DriftWebOptions`.
- https://drift.simonbinder.eu/testing/ — para pruebas se usa `NativeDatabase.memory()` y `closeStreamsSynchronously: true` en pruebas de widgets; por eso la clase de base recibe el `QueryExecutor` en el constructor.
- Versiones vistas en pub.dev (2026-11-24): drift 2.35.4, drift_dev 2.35.3, drift_flutter 0.3.1, sqlite3 3.9.2.

## Pruebas (fecha, entorno, resultado)
| ID | Entorno | Resultado | Observaciones |
|----|---------|-----------|---------------|
| base | Windows (flutter test) | Pasa | Prueba de apertura de la pantalla con base en memoria, 2026-11-24 |
| P1 | Windows (escritorio, `flutter run -d windows`) | Pasa | Se agregaron 3 tareas, se cerró la app y al volver a ejecutarla seguían las 3. 2026-11-24 |
| P2 | Windows | Pasa | Tarea marcada como completada conserva el estado tras cerrar y abrir. 2026-11-24 |
| P3 | Windows | Pasa | Título editado aparece con el nuevo texto tras reiniciar. 2026-11-24 |
| P4 | Windows | Pasa | Tarea eliminada no reaparece tras reiniciar. 2026-11-24 |
| P5 | Windows | Pasa | Título vacío o de solo espacios no se registra y muestra "El título no puede estar vacío" (alta y edición). 2026-11-24 |
| P6 | Chrome (web) | Pendiente | Etapa 4 |

Entornos disponibles (`flutter devices`, 2026-11-24): Windows (escritorio), Chrome y Edge (web).

## Uso de IA (herramienta, para qué, qué verifiqué, qué corregí)
