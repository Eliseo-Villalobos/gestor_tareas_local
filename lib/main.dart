import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

/// Punto de entrada de la aplicación.
/// Es dueña de la base de datos: la abre una vez y la cierra en dispose().
class GestorTareasApp extends StatefulWidget {
  /// Las pruebas pueden inyectar una base (por ejemplo, en memoria).
  final AppDatabase? database;

  const GestorTareasApp({super.key, this.database});

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final AppDatabase _database;
  late final bool _esPropia;

  @override
  void initState() {
    super.initState();
    _esPropia = widget.database == null;
    _database = widget.database ?? AppDatabase();
  }

  @override
  void dispose() {
    // Solo cerramos la base si la abrimos nosotros.
    if (_esPropia) {
      _database.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(database: _database),
    );
  }
}
