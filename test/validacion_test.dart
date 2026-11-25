import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/validacion.dart';

void main() {
  group('normalizarTitulo', () {
    test('rechaza texto vacío', () {
      expect(normalizarTitulo(''), isNull);
    });

    test('rechaza texto de solo espacios, tabs o saltos de línea', () {
      expect(normalizarTitulo('   '), isNull);
      expect(normalizarTitulo('\t\n  '), isNull);
    });

    test('quita espacios al inicio y al final', () {
      expect(normalizarTitulo('  Comprar pan  '), 'Comprar pan');
    });

    test('conserva espacios internos de un título válido', () {
      expect(normalizarTitulo('Estudiar   SQLite'), 'Estudiar   SQLite');
    });
  });
}
