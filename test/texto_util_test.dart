import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_mobile/modelo/texto_util.dart';

void main() {
  test('normaliza acentos y signos', () {
    expect(normalizarTexto('¿Teléfono?'), ' telefono ');
    expect(terminosDe('busco un aire barato'), containsAll(['busco', 'aire', 'barato']));
  });
}
