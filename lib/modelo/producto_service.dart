import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'producto.dart';

class ProductoService {
  static const String productosCollection = 'productos';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Producto> _catalogo = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final _catalogoStreamController = StreamController<List<Producto>>.broadcast();

  Stream<List<Producto>> get catalogoStream => _catalogoStreamController.stream;

  List<Producto> get catalogo => List.unmodifiable(_catalogo);

  List<String> get categorias =>
      _catalogo.map((p) => p.categoria).toSet().toList();

  /// Carga el catálogo: primero local para disponibilidad inmediata,
  /// luego inicia la escucha en tiempo real de Cloud Firestore.
  Future<void> cargarCatalogo() async {
    if (_catalogo.isEmpty) {
      await _cargarLocal();
    }
    iniciarEscuchaTiempoReal();
  }

  Future<void> _cargarLocal() async {
    try {
      final json = await rootBundle.loadString('assets/catalogo.json');
      final List<dynamic> data = jsonDecode(json);
      _catalogo = data.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
      _catalogoStreamController.add(_catalogo);
    } catch (e) {
      debugPrint('Error cargando catálogo local: $e');
    }
  }

  /// Escucha en tiempo real los cambios en la colección 'productos' de Firestore
  void iniciarEscuchaTiempoReal() {
    _subscription?.cancel();
    _subscription = _db.collection(productosCollection).snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _catalogo = snapshot.docs
              .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
              .where((p) => p.marca.isNotEmpty || p.modelo.isNotEmpty)
              .toList();
          _catalogoStreamController.add(_catalogo);
          debugPrint('Catálogo actualizado en tiempo real: ${_catalogo.length} productos');
        } else {
          // Si la colección está vacía en Firestore, intentamos sembrar el catálogo inicial
          sincronizarCatalogoAFirestore().catchError((e) {
            debugPrint('No se pudo auto-sembrar productos en Firestore: $e');
            return 0;
          });
        }
      },
      onError: (error) {
        debugPrint('Error en stream de Firestore productos: $error');
      },
    );
  }

  /// Sube los productos de assets/catalogo.json a Firestore en lote (batch)
  Future<int> sincronizarCatalogoAFirestore() async {
    try {
      final json = await rootBundle.loadString('assets/catalogo.json');
      final List<dynamic> data = jsonDecode(json);
      final batch = _db.batch();
      int subidos = 0;

      for (final item in data) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          final docRef = _db.collection(productosCollection).doc(id);
          batch.set(docRef, item, SetOptions(merge: true));
          subidos++;
        }
      }

      await batch.commit();
      debugPrint('Sincronizados $subidos productos a Cloud Firestore con éxito');
      return subidos;
    } catch (e) {
      debugPrint('Error sincronizando catálogo a Firestore: $e');
      rethrow;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _catalogoStreamController.close();
  }

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
