/// Validación del título de una tarea, separada de la interfaz
/// para poder probarla con `flutter test`.
///
/// Devuelve el título sin espacios al inicio ni al final,
/// o `null` si queda vacío (vacío o solo espacios).
String? normalizarTitulo(String texto) {
  final limpio = texto.trim();
  return limpio.isEmpty ? null : limpio;
}
