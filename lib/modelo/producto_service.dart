import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'producto.dart';
import 'texto_util.dart';

class ProductoService {
  List<Producto> _catalogo = [];

  Future<void> cargarCatalogo() async {
    final json = await rootBundle.loadString('assets/catalogo.json');
    final List<dynamic> data = jsonDecode(json);
    _catalogo = data.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  }

  void usarCatalogo(List<Producto> productos) {
    _catalogo = productos;
  }

  List<Producto> get catalogo => List.unmodifiable(_catalogo);

  List<String> get categorias =>
      _catalogo.map((p) => p.categoriaId).toSet().toList();

  List<Producto> porCategoria(String categoria) =>
      _catalogo.where((p) =>
          p.categoriaId.toLowerCase() == categoria.toLowerCase()).toList();

  List<Producto> porPrecio(double min, double max) =>
      _catalogo.where((p) => p.precio >= min && p.precio <= max).toList();

  List<Producto> buscar(String query) {
    final terminos = terminosDe(query);
    if (terminos.isEmpty) return [];

    final puntajes = <MapEntry<Producto, int>>[];
    for (final producto in _catalogo) {
      if (!producto.activo) continue;
      final campos = normalizarTexto(
        '${producto.categoriaId} ${producto.marca} ${producto.nombre} '
        '${producto.descripcion}',
      );
      var score = 0;
      for (final termino in terminos) {
        if (campos.contains(termino)) score += 1;
      }
      if (score > 0) puntajes.add(MapEntry(producto, score));
    }

    puntajes.sort((a, b) => b.value.compareTo(a.value));
    return puntajes.map((e) => e.key).toList();
  }

  List<Producto> filtrar({
    String? categoria,
    double? precioMin,
    double? precioMax,
    String? busqueda,
  }) {
    var resultados = _catalogo.where((p) => p.activo).toList();

    if (categoria != null) {
      resultados = resultados.where((p) =>
          p.categoriaId.toLowerCase() == categoria.toLowerCase()).toList();
    }
    if (precioMin != null) {
      resultados = resultados.where((p) => p.precio >= precioMin).toList();
    }
    if (precioMax != null) {
      resultados = resultados.where((p) => p.precio <= precioMax).toList();
    }
    if (busqueda != null) {
      final q = busqueda.toLowerCase();
      resultados = resultados.where((p) =>
          p.marca.toLowerCase().contains(q) ||
          p.nombre.toLowerCase().contains(q) ||
          p.descripcion.toLowerCase().contains(q)).toList();
    }

    return resultados;
  }
}
