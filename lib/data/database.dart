import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  static QueryExecutor _abrirConexion() {
    return driftDatabase(name: 'gestor_tareas');
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
}
