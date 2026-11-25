# Notas para el reporte

## Problemas reales (mensaje, causa, solución, cómo se verificó)
- (2026-11-24) `flutter analyze` sobre la base: `info - The private field _tareas could be 'final' (prefer_final_fields)`. Causa: la lista de la base nunca se reasigna. **Resuelto** en Etapa 2 (la lista se reemplazó por un Stream de Drift; `flutter analyze`: No issues found).
- (2026-11-24) `dart run build_runner build --delete-conflicting-outputs` → `W These options have been removed and were ignored: --delete-conflicting-outputs`. Causa: build_runner 2.17.1 eliminó esa opción. Solución: usar `dart run build_runner build`. Verificado: generó `database.g.dart` y `flutter analyze` sin errores.
- (2026-11-24) `flutter build windows --debug` → `Building with plugins requires symlink support. Please enable Developer Mode in your system settings.` Causa: los plugins (path_provider, sqlite3) se enlazan con symlinks y Windows los bloquea sin Modo de desarrollador. Solución: activar el Modo de desarrollador en Configuración. Verificación: se activó el Modo de desarrollador y `flutter run -d windows` funcionó sin problemas.
- (2026-11-24) La documentación de Drift web menciona `drift_worker.js` en el texto y `drift_worker.dart.js` en los ejemplos. Cómo se investigó: se consultó la API de GitHub de la release `drift-2.35.4`; los archivos publicados son `drift_worker.js` (363283 bytes) y `sqlite3.wasm` (758836 bytes). Se verificó que `pubspec.lock` fija drift 2.35.4, que los tamaños descargados coinciden y que el `.wasm` empieza con la firma `\0asm`. `flutter build web` compiló y copió ambos archivos a `build/web`.
- (2026-11-24) La base de Windows se creó en `C:\Users\Eliba\OneDrive\Documentos\gestor_tareas.sqlite`. Causa: drift_flutter usa por defecto `getApplicationDocumentsDirectory()` (se vio en `drift_flutter-0.3.1/lib/src/native.dart`) y la carpeta Documentos de esta PC está redirigida a OneDrive, que puede bloquear o duplicar un archivo SQLite abierto. Solución: `DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory)` → AppData. Verificación: tras ejecutar la app, `Get-ChildItem $env:APPDATA -Recurse -Filter gestor_tareas.sqlite` encontró `C:\Users\Eliba\AppData\Roaming\com.example\gestor_tareas_local\gestor_tareas.sqlite` (fuera de OneDrive).
- (2026-11-24) En Chrome, la consola mostró: `Drift web: WasmStorageImplementation.sharedIndexedDb (faltan: {MissingBrowserFeature.dedicatedWorkersInSharedWorkers, MissingBrowserFeature.sharedArrayBuffers})`. Interpretación: Drift no pudo usar OPFS porque `SharedArrayBuffer` requiere las cabeceras COOP/COEP (no configuradas) y Chrome no permite workers dedicados dentro de un shared worker. Eligió **IndexedDB en un shared worker**, que sí persiste y es seguro entre pestañas. Se dejó así: no hace falta OPFS para la práctica, y las cabeceras COOP/COEP habría que configurarlas también en el servidor de despliegue.
- Decisión: la tabla `Tareas` generaría una clase `Tarea` que choca con `lib/models/tarea.dart`. Se usó `@UseRowClass(Tarea)` para que Drift devuelva el modelo existente (su constructor tiene los mismos nombres que las columnas).

## Fuentes consultadas (enlace + qué aprendí)
- https://drift.simonbinder.eu/platforms/web/ — en web Drift usa SQLite compilado a WebAssembly; hay que poner `sqlite3.wasm` y `drift_worker.dart.js` en `web/`, descargados de la **misma release** de Drift que indica `pubspec.lock`. Almacenamiento: OPFS (requiere cabeceras COOP/COEP) o IndexedDB; en modo privado puede caer a memoria.
- https://pub.dev/packages/drift_flutter — `driftDatabase(name: ...)` abre la base en la carpeta adecuada de cada plataforma; acepta `DriftWebOptions`.
- https://drift.simonbinder.eu/testing/ — para pruebas se usa `NativeDatabase.memory()` y `closeStreamsSynchronously: true` en pruebas de widgets; por eso la clase de base recibe el `QueryExecutor` en el constructor.
- Código fuente de `drift_flutter-0.3.1` (`lib/src/connect.dart` y `native.dart`): `DriftWebOptions` acepta `onResult`, que informa qué almacenamiento web se eligió; en nativo la base por defecto es `<Documentos>/<name>.sqlite`.
- https://github.com/simolus3/drift/releases/tag/drift-2.35.4 — los nombres reales de los archivos web y que deben venir de la misma versión que `pubspec.lock`.
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
| auto | Windows (`flutter test`) | Pasa (9/9) | widget_test (1), validacion_test (4), database_test (4). 2026-11-24 |
| build web | `flutter build web` | Pasa | Compila; `sqlite3.wasm` y `drift_worker.js` copiados a `build/web`. 2026-11-24 |
| P1 (repetida) | Windows, base en AppData | Pasa | Tras mover la base fuera de OneDrive, las tareas permanecen al cerrar y abrir. 2026-11-24 |
| P6 | Chrome (web, `--web-port 5000`) | Pasa | Datos permanecen tras recargar (F5) y tras cerrar y abrir la pestaña en `http://localhost:5000`, mismo perfil. Almacenamiento: `sharedIndexedDb`. 2026-11-24 |
| P1 | Android físico: Samsung SM-S721B, Android 16 (API 36), `flutter run -d RZCY614DCAJ` | Pasa | 3 tareas permanecen tras cerrar la app (quitarla de recientes) y abrirla desde el ícono. 2026-11-24 |
| P2 | Android físico (SM-S721B) | Pasa | Estado completada se conserva tras reiniciar. 2026-11-24 |
| P3 | Android físico (SM-S721B) | Pasa | Título editado se conserva tras reiniciar. 2026-11-24 |
| P4 | Android físico (SM-S721B) | Pasa | Tarea eliminada no reaparece tras reiniciar. 2026-11-24 |
| P5 | Android físico (SM-S721B) | Pasa | Título vacío o de solo espacios no se registra. 2026-11-24 |
| Incógnito | Chrome, ventana de incógnito | Limitación esperada | Al abrir `localhost:5000` en incógnito no aparecen las tareas del perfil normal: incógnito usa un almacenamiento separado y temporal. 2026-11-24 |

Entornos disponibles (`flutter devices`, 2026-11-24): Windows (escritorio), Chrome y Edge (web), Samsung SM-S721B con Android 16 (móvil, por USB).

**Resumen:** probado en los 3 entornos: escritorio (Windows), web (Chrome) y móvil (Android físico). iOS/macOS/Linux: previstos por el diseño (mismo código con drift_flutter), no probados (requieren Mac o Linux).

- (2026-11-24) Para probar en Android: `flutter doctor` marcaba `Some Android licenses not accepted`; se resolvió con `flutter doctor --android-licenses`. Además hubo que activar la depuración USB en el teléfono (Opciones de desarrollador).

## Uso de IA (herramienta, para qué, qué verifiqué, qué corregí)
- Claude Code Opus 5.5 
- Para guiarme en el transcurso de las tareas y asi seguir todo paso por paso, mejorando mis propuestas y ayudarme a corregir errores.
- Verifique las respuestas obtenidas y las probe. Sus respuestas eran validas.
- Errores de mis carpetas por tenerlas en OneDrive 