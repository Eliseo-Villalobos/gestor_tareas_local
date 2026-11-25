import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

import '../models/tarea.dart';

// Archivo generado por build_runner (dart run build_runner build).
part 'database.g.dart';

/// Definición de la tabla `tareas`.
/// Drift traduce cada getter a una columna de SQLite.
/// @UseRowClass hace que las consultas devuelvan nuestro modelo [Tarea]
/// en lugar de una clase generada con el mismo nombre.
@UseRowClass(Tarea)
class Tareas extends Table {
  /// INTEGER PRIMARY KEY AUTOINCREMENT: SQLite asigna el id.
  IntColumn get id => integer().autoIncrement()();

  /// TEXT NOT NULL con longitud de 1 a 200 caracteres.
  TextColumn get titulo => text().withLength(min: 1, max: 200)();

  /// SQLite no tiene BOOLEAN: se guarda como INTEGER 0/1.
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Si no se pasa un [executor], se abre la base persistente en disco.
  /// Las pruebas pasan una base en memoria (NativeDatabase.memory()).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  /// drift_flutter elige la ubicación del archivo según la plataforma.
  /// En web usa SQLite compilado a WebAssembly: sqlite3.wasm y
  /// drift_worker.js están en web/ y vienen de la release drift-2.35.4
  /// (la misma versión que fija pubspec.lock).
  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      // Por defecto drift_flutter usa la carpeta Documentos, que en esta PC
      // está sincronizada con OneDrive. La carpeta de soporte de la app
      // (AppData en Windows) no se sincroniza ni la ve el usuario.
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        // Informa en consola qué almacenamiento eligió el navegador
        // (OPFS o IndexedDB) y qué funciones faltan.
        onResult: (resultado) {
          debugPrint(
            'Drift web: ${resultado.chosenImplementation} '
            '(faltan: ${resultado.missingFeatures})',
          );
        },
      ),
    );
  }

  /// SELECT * FROM tareas ORDER BY id, como Stream:
  /// vuelve a emitir cada vez que la tabla cambia.
  Stream<List<Tarea>> observarTareas() {
    return (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();
  }

  /// INSERT INTO tareas (titulo) VALUES (?). Devuelve el id generado.
  Future<int> insertarTarea(String titulo) {
    return into(tareas).insert(TareasCompanion.insert(titulo: titulo));
  }

  /// UPDATE tareas SET titulo = ? WHERE id = ?. Devuelve filas afectadas.
  Future<int> actualizarTitulo(int id, String titulo) {
    return (update(tareas)..where((t) => t.id.equals(id))).write(
      TareasCompanion(titulo: Value(titulo)),
    );
  }

  /// UPDATE tareas SET completada = ? WHERE id = ?. Devuelve filas afectadas.
  Future<int> cambiarEstado(int id, bool completada) {
    return (update(tareas)..where((t) => t.id.equals(id))).write(
      TareasCompanion(completada: Value(completada)),
    );
  }

  /// DELETE FROM tareas WHERE id = ?. Devuelve filas borradas.
  Future<int> eliminarTarea(int id) {
    return (delete(tareas)..where((t) => t.id.equals(id))).go();
  }
}
