import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'producto.dart';
import 'texto_util.dart';

class ProductoService {
  static const String productosCollection = 'productos';
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  List<Producto> _catalogo = [];
  List<String> _textoNormalizado = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final _catalogoStreamController = StreamController<List<Producto>>.broadcast();

  Stream<List<Producto>> get catalogoStream => _catalogoStreamController.stream;

  void usarCatalogo(List<Producto> productos) {
    _catalogo = productos;
    _reindexar();
  }

  /// Precalcula el texto normalizado de cada producto para que la búsqueda
  /// no normalice strings en cada consulta.
  void _reindexar() {
    _textoNormalizado = _catalogo
        .map((p) => normalizarTexto(
              '${p.categoriaId} ${p.marca} ${p.nombre} ${p.descripcion}',
            ))
        .toList();
  }

  List<Producto> get catalogo => List.unmodifiable(_catalogo);

  List<String> get categorias =>
      _catalogo.map((p) => p.categoria).where((c) => c.isNotEmpty).toSet().toList();

  /// Carga el catálogo: primero el bundle local para disponibilidad inmediata,
  /// después una consulta acotada a Firestore (solo productos activos).
  /// No se mantiene una escucha permanente de toda la colección: el catálogo
  /// queda en memoria y las búsquedas del chat no lo vuelven a bajar entero.
  /// [consultarFirestore] en false evita una segunda ida a la red cuando ya
  /// sabemos que la consulta falló o vino vacía.
  Future<void> cargarCatalogo({
    int limite = 50,
    bool consultarFirestore = true,
  }) async {
    if (_catalogo.isEmpty) {
      await _cargarLocal();
    }
    if (consultarFirestore) {
      await _cargarDesdeFirestore(limite: limite);
    }
  }

  Future<void> _cargarDesdeFirestore({int limite = 50}) async {
    try {
      final snapshot = await _db
          .collection(productosCollection)
          .where('activo', isEqualTo: true)
          .limit(limite)
          .get();
      if (snapshot.docs.isEmpty) return;
      _catalogo = snapshot.docs
          .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
          .where((p) => p.nombre.isNotEmpty || p.marca.isNotEmpty)
          .toList();
      _reindexar();
      _catalogoStreamController.add(_catalogo);
      debugPrint('Catálogo cargado desde Firestore: ${_catalogo.length} productos');
    } catch (e) {
      debugPrint('No se pudo cargar el catálogo desde Firestore: $e');
    }
  }

  Future<void> _cargarLocal() async {
    try {
      final json = await rootBundle.loadString('assets/catalogo.json');
      final List<dynamic> data = jsonDecode(json);
      _catalogo = data.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
      _reindexar();
      _catalogoStreamController.add(_catalogo);
    } catch (e) {
      debugPrint('Error cargando catálogo local: $e');
    }
  }

  /// Escucha en tiempo real los cambios en la colección 'productos' de Firestore.
  /// Es opcional: la app no la activa por defecto para no bajar el catálogo
  /// completo en cada arranque.
  void iniciarEscuchaTiempoReal() {
    _subscription?.cancel();
    try {
      _subscription = _db.collection(productosCollection).snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _catalogo = snapshot.docs
                .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
                .where((p) => p.marca.isNotEmpty || p.nombre.isNotEmpty)
                .toList();
            _reindexar();
            _catalogoStreamController.add(_catalogo);
            debugPrint('Catálogo actualizado en tiempo real: ${_catalogo.length} productos');
          }
        },
        onError: (error) {
          debugPrint('Error en stream de Firestore productos: $error');
        },
      );
    } catch (e) {
      debugPrint('No se pudo iniciar la escucha en tiempo real de Firestore: $e');
    }
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
          batch.set(docRef, Producto.fromJson(item).toFirestore(),
              SetOptions(merge: true));
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
      _catalogo.where((p) => p.precio >= min && p.precio <= max).toList();

  List<Producto> buscar(String query) {
    final terminos = terminosDe(query);
    if (terminos.isEmpty) return [];

    final puntajes = <MapEntry<Producto, int>>[];
    for (var i = 0; i < _catalogo.length; i++) {
      final producto = _catalogo[i];
      if (!producto.activo) continue;
      final campos = i < _textoNormalizado.length ? _textoNormalizado[i] : '';
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
          p.categoria.toLowerCase() == categoria.toLowerCase()).toList();
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
