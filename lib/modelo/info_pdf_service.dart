import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'texto_util.dart';

class InfoPdfService {
  static const String _asset = 'assets/info.pdf';

  List<String> _segmentos = [];
  bool _cargado = false;

  bool get cargado => _cargado;
  bool get hayInfo => _segmentos.isNotEmpty;
  List<String> get segmentos => List.unmodifiable(_segmentos);

  Future<void> cargar() async {
    if (_cargado) return;
    _cargado = true;
    try {
      final data = await rootBundle.load(_asset);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final documento = PdfDocument(inputBytes: bytes);
      final texto = PdfTextExtractor(documento).extractText();
      documento.dispose();
      _segmentos = segmentar(texto);
    } catch (_) {
      _segmentos = [];
    }
  }

  List<String> buscar(String query, {int maxResultados = 4}) {
    final q = normalizar(query).trim();
    if (q.isEmpty || _segmentos.isEmpty) return [];

    final terminos = terminosDe(query);

    final puntajes = <MapEntry<String, int>>[];
    for (final segmento in _segmentos) {
      final texto = normalizar(segmento);
      var score = texto.contains(q) ? 3 : 0;
      for (final termino in terminos) {
        if (texto.contains(termino)) score += 1;
      }
      if (score > 0) puntajes.add(MapEntry(segmento, score));
    }

    puntajes.sort((a, b) => b.value.compareTo(a.value));
    return puntajes.take(maxResultados).map((e) => e.key).toList();
  }

  static String normalizar(String texto) => normalizarTexto(texto);

  static List<String> segmentar(String texto) {
    final segmentos = <String>[];
    var titulo = '';
    final actual = StringBuffer();

    void cerrar() {
      if (actual.isNotEmpty) {
        segmentos.add(actual.toString().trim());
        actual.clear();
      }
    }

    for (final lineaCruda in texto.split('\n')) {
      final linea = lineaCruda.trim();
      if (linea.isEmpty) continue;

      if (linea.startsWith('- ')) {
        cerrar();
        actual.write(titulo.isEmpty ? linea : '$titulo: $linea');
        titulo = '';
      } else if (esTitulo(linea)) {
        cerrar();
        titulo = linea;
      } else if (actual.isNotEmpty) {
        actual.write(' $linea');
      } else {
        segmentos.add(linea);
      }
    }
    cerrar();

    return segmentos.where((s) => s.length > 10).toList();
  }

  static bool esTitulo(String linea) =>
      !linea.startsWith('- ') && !RegExp(r'[.!?;,]$').hasMatch(linea);
}
