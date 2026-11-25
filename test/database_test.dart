import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';

/// Pruebas de la capa de datos con una base SQLite real, pero en memoria:
/// mismas tablas y consultas que la app, sin tocar el disco.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('insertar asigna ids únicos y la tarea inicia pendiente', () async {
    final id1 = await db.insertarTarea('Primera');
    final id2 = await db.insertarTarea('Segunda');

    expect(id1, isNot(id2));
    final tareas = await db.observarTareas().first;
    expect(tareas.map((t) => t.titulo), ['Primera', 'Segunda']);
    expect(tareas.every((t) => t.completada == false), isTrue);
  });

  test('actualizar título y estado modifica solo esa fila', () async {
    final id = await db.insertarTarea('Original');
    final otro = await db.insertarTarea('Sin cambios');

    expect(await db.actualizarTitulo(id, 'Editado'), 1);
    expect(await db.cambiarEstado(id, true), 1);

    final tareas = await db.observarTareas().first;
    final editada = tareas.firstWhere((t) => t.id == id);
    final intacta = tareas.firstWhere((t) => t.id == otro);
    expect(editada.titulo, 'Editado');
    expect(editada.completada, isTrue);
    expect(intacta.titulo, 'Sin cambios');
    expect(intacta.completada, isFalse);
  });

  test('eliminar por id borra la fila; un id inexistente afecta 0', () async {
    final id = await db.insertarTarea('Borrar');

    expect(await db.eliminarTarea(id), 1);
    expect(await db.observarTareas().first, isEmpty);
    expect(await db.eliminarTarea(id), 0);
  });

  test('la tabla rechaza un título vacío aunque falle la interfaz', () async {
    expect(() => db.insertarTarea(''), throwsA(isA<InvalidDataException>()));
  });
}
