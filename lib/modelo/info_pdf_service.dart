import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'texto_util.dart';

class InfoPdfService {
  static const String _storagePath = 'conocimiento_ia/vendedorVirtual.pdf';

  List<String> _segmentos = [];
  List<String> _segmentosNormalizados = [];
  bool _cargado = false;

  bool get cargado => _cargado;
  bool get hayInfo => _segmentos.isNotEmpty;
  List<String> get segmentos => List.unmodifiable(_segmentos);

  Future<void> cargar({String? storagePath}) async {
    if (_cargado) return;
    _cargado = true;
    try {
      final path = storagePath ?? _storagePath;
      final ref = FirebaseStorage.instance.ref(path);
      final Uint8List? bytes = await ref.getData();

      if (bytes == null || bytes.isEmpty) {
        _segmentos = [];
        _segmentosNormalizados = [];
        return;
      }

      final documento = PdfDocument(inputBytes: bytes);
      final texto = PdfTextExtractor(documento).extractText();
      documento.dispose();
      _segmentos = segmentar(texto);
      _segmentosNormalizados =
          _segmentos.map((s) => normalizarTexto(s)).toList();
    } catch (_) {
      _segmentos = [];
      _segmentosNormalizados = [];
    }
  }

  List<String> buscar(String query, {int maxResultados = 4}) {
    final q = normalizar(query).trim();
    if (q.isEmpty || _segmentos.isEmpty) return [];

    final terminos = terminosDe(query);

    final puntajes = <MapEntry<String, int>>[];
    for (var i = 0; i < _segmentos.length; i++) {
      final texto = i < _segmentosNormalizados.length
          ? _segmentosNormalizados[i]
          : normalizar(_segmentos[i]);
      var score = texto.contains(q) ? 3 : 0;
      for (final termino in terminos) {
        if (texto.contains(termino)) score += 1;
      }
      if (score > 0) puntajes.add(MapEntry(_segmentos[i], score));
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
