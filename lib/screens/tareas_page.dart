import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/validacion.dart';
import '../models/tarea.dart';

// Pantalla principal: CRUD de tareas sobre SQLite (Drift).
class TareasPage extends StatefulWidget {
  final AppDatabase database;

  const TareasPage({super.key, required this.database});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  /// Se crea UNA vez en initState. build() solo lo escucha,
  /// así no se lanza una consulta nueva en cada reconstrucción.
  late final Stream<List<Tarea>> _tareasStream;

  @override
  void initState() {
    super.initState();
    _tareasStream = widget.database.observarTareas();
  }

  Future<void> _agregarTarea() async {
    final titulo = normalizarTitulo(_tituloController.text);
    if (titulo == null) {
      _mostrarMensaje('El título no puede estar vacío');
      return;
    }
    try {
      await widget.database.insertarTarea(titulo);
      _tituloController.clear();
      // No hace falta setState: el Stream de watch() emite la lista nueva.
    } catch (e) {
      _mostrarMensaje('No se pudo guardar la tarea: $e');
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    try {
      final filas = await widget.database.cambiarEstado(tarea.id, completada);
      if (filas == 0) _mostrarMensaje('La tarea ya no existe');
    } catch (e) {
      _mostrarMensaje('No se pudo actualizar el estado: $e');
    }
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (_) => _EditarTareaDialog(tituloActual: tarea.titulo),
    );
    // null = el usuario canceló, o el título no cambió.
    if (nuevoTitulo == null || nuevoTitulo == tarea.titulo) return;
    try {
      final filas = await widget.database.actualizarTitulo(
        tarea.id,
        nuevoTitulo,
      );
      _mostrarMensaje(
        filas == 0 ? 'La tarea ya no existe' : 'Título actualizado',
      );
    } catch (e) {
      _mostrarMensaje('No se pudo editar la tarea: $e');
    }
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${tarea.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      final filas = await widget.database.eliminarTarea(tarea.id);
      _mostrarMensaje(filas == 0 ? 'La tarea ya no existe' : 'Tarea eliminada');
    } catch (e) {
      _mostrarMensaje('No se pudo eliminar la tarea: $e');
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareasStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al leer la base: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(tarea.titulo),
                          subtitle: Text('ID: ${tarea.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar el título. Es un StatefulWidget para poder
/// liberar su TextEditingController en dispose() y mostrar el error
/// de validación debajo del campo.
class _EditarTareaDialog extends StatefulWidget {
  final String tituloActual;

  const _EditarTareaDialog({required this.tituloActual});

  @override
  State<_EditarTareaDialog> createState() => _EditarTareaDialogState();
}

class _EditarTareaDialogState extends State<_EditarTareaDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.tituloActual,
  );
  String? _error;

  void _guardar() {
    final titulo = normalizarTitulo(_controller.text);
    if (titulo == null) {
      setState(() => _error = 'El título no puede estar vacío');
      return;
    }
    Navigator.pop(context, titulo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Título', errorText: _error),
        onSubmitted: (_) => _guardar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
