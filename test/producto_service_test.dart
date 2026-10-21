import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_mobile/modelo/producto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductoService service;

  setUp(() async {
    service = ProductoService();
    await service.cargarCatalogo();
  });

  test('encuentra aires con una frase larga', () {
    final resultado =
        service.buscar('Hola, busco un aire acondicionado barato para mi casa');
    expect(resultado, isNotEmpty);
    expect(resultado.first.categoriaId, 'Aire Acondicionado');
  });

  test('encuentra telefonos con acentos y palabras sueltas', () {
    final resultado = service.buscar('necesito un teléfono');
    expect(resultado, isNotEmpty);
    expect(
      resultado.map((p) => p.categoriaId),
      contains('Teléfono'),
    );
  });

  test('devuelve vacio para productos fuera del catalogo', () {
    expect(service.buscar('quiero una bicicleta'), isEmpty);
  });
}
