import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_mobile/modelo/info_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InfoPdfService service;

  setUp(() {
    service = InfoPdfService();
  });

  test('carga y extrae texto del PDF de info', () async {
    await service.cargar();
    expect(service.cargado, isTrue);
    expect(service.hayInfo, isTrue);
    expect(service.segmentos.length, greaterThan(5));
  });

  test('busca informacion del asistente y su alcance', () async {
    await service.cargar();
    expect(service.buscar('¿qué hace este asistente?'), isNotEmpty);
    expect(service.buscar('no son una tienda?'), isNotEmpty);
    expect(service.buscar('hacen envíos?'), isNotEmpty);
    expect(service.buscar('como me ayuda a elegir'), isNotEmpty);
  });

  test('no devuelve nada si la consulta no corresponde al PDF', () async {
    await service.cargar();
    expect(service.buscar('me pasas una receta de cocina'), isEmpty);
  });

  test('segmenta respetando los titulos de seccion', () {
    final segmentos = InfoPdfService.segmentar(
      'Envios\n- Envio GRATIS en compras superiores a USD 500.\n'
      '- Costo fijo de USD 10.\n',
    );
    expect(segmentos, hasLength(2));
    expect(segmentos.first, startsWith('Envios: - Envio GRATIS'));
  });
}
