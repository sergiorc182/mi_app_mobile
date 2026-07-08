import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'producto.dart';

class ProductoService {
  List<Producto> _catalogo = [];

  Future<void> cargarCatalogo() async {
    final json = await rootBundle.loadString('assets/catalogo.json');
    final List<dynamic> data = jsonDecode(json);
    _catalogo = data.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  }

  List<Producto> get catalogo => List.unmodifiable(_catalogo);

  List<String> get categorias =>
      _catalogo.map((p) => p.categoria).toSet().toList();

  List<Producto> porCategoria(String categoria) =>
      _catalogo.where((p) =>
          p.categoria.toLowerCase() == categoria.toLowerCase()).toList();

  List<Producto> porPrecio(double min, double max) =>
      _catalogo.where((p) => p.precioUSD >= min && p.precioUSD <= max).toList();

  List<Producto> buscar(String query) {
    final q = query.toLowerCase();
    return _catalogo.where((p) =>
        p.marca.toLowerCase().contains(q) ||
        p.modelo.toLowerCase().contains(q) ||
        p.especificacionClave.toLowerCase().contains(q) ||
        p.categoria.toLowerCase().contains(q)).toList();
  }

  List<Producto> filtrar({
    String? categoria,
    double? precioMin,
    double? precioMax,
    String? busqueda,
  }) {
    var resultados = _catalogo;

    if (categoria != null) {
      resultados = resultados.where((p) =>
          p.categoria.toLowerCase() == categoria.toLowerCase()).toList();
    }
    if (precioMin != null) {
      resultados = resultados.where((p) => p.precioUSD >= precioMin).toList();
    }
    if (precioMax != null) {
      resultados = resultados.where((p) => p.precioUSD <= precioMax).toList();
    }
    if (busqueda != null) {
      final q = busqueda.toLowerCase();
      resultados = resultados.where((p) =>
          p.marca.toLowerCase().contains(q) ||
          p.modelo.toLowerCase().contains(q) ||
          p.especificacionClave.toLowerCase().contains(q)).toList();
    }

    return resultados;
  }
}
