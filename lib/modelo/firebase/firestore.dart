import 'package:cloud_firestore/cloud_firestore.dart';

import '../carrito.dart';
import '../categoria.dart';
import '../configuracion.dart';
import '../conversacion.dart';
import '../documento.dart';
import '../mensaje.dart';
import '../pedido.dart';
import '../producto.dart';
import '../usuario.dart';

class FirestoreService {
  static const String usuariosCollection = 'usuarios';
  static const String productosCollection = 'productos';
  static const String categoriasCollection = 'categorias';
  static const String conversacionesCollection = 'conversaciones';
  static const String carritosCollection = 'carritos';
  static const String pedidosCollection = 'pedidos';
  static const String documentosCollection = 'documentos';
  static const String configuracionCollection = 'configuracion';
  static const String configuracionDoc = 'asistente';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ─── Usuarios ───

  Future<void> crearUsuario(Usuario usuario) async {
    await _db.collection(usuariosCollection).doc(usuario.id).set(
      usuario.toFirestore(useServerTimestamps: true),
      SetOptions(merge: true),
    );
  }

  Future<Usuario?> obtenerUsuario(String uid) async {
    final doc = await _db.collection(usuariosCollection).doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromFirestore(doc.data() ?? {}, doc.id);
  }

  /// Datos crudos del perfil: sirve para detectar campos que faltan
  /// en documentos creados con el esquema anterior.
  Future<Map<String, dynamic>?> obtenerUsuarioDatos(String uid) async {
    final doc = await _db.collection(usuariosCollection).doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() ?? {};
  }

  Future<void> actualizarUsuario(String uid, Map<String, dynamic> data) async {
    await _db.collection(usuariosCollection).doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Productos ───

  Future<List<Producto>> obtenerProductos({
    bool soloActivos = true,
    int limite = 50,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(productosCollection);
    if (soloActivos) {
      query = query.where('activo', isEqualTo: true);
    }
    final snapshot = await query.limit(limite).get();
    return snapshot.docs
        .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<Producto?> obtenerProducto(String productoId) async {
    final doc = await _db.collection(productosCollection).doc(productoId).get();
    if (!doc.exists) return null;
    return Producto.fromFirestore(doc.data() ?? {}, doc.id);
  }

  Future<void> guardarProducto(Producto producto) async {
    await _db.collection(productosCollection).doc(producto.id).set(
          producto.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // ─── Categorías ───

  Future<List<Categoria>> obtenerCategorias({bool soloActivas = true}) async {
    Query<Map<String, dynamic>> query = _db.collection(categoriasCollection);
    if (soloActivas) {
      query = query.where('activo', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Categoria.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> guardarCategoria(Categoria categoria) async {
    await _db.collection(categoriasCollection).doc(categoria.id).set(
          categoria.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // ─── Documentos (metadata de PDFs en Storage) ───

  Future<List<Documento>> obtenerDocumentos({String? usuarioId}) async {
    Query<Map<String, dynamic>> query = _db.collection(documentosCollection);
    if (usuarioId != null && usuarioId.isNotEmpty) {
      query = query.where('usuarioId', isEqualTo: usuarioId);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Documento.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> guardarDocumento(Documento documento) async {
    await _db.collection(documentosCollection).doc(documento.id).set(
          documento.toFirestore(useServerTimestamps: true),
          SetOptions(merge: true),
        );
  }

  // ─── Configuración del asistente ───

  Future<Configuracion?> obtenerConfiguracion() async {
    final doc = await _db
        .collection(configuracionCollection)
        .doc(configuracionDoc)
        .get();
    if (!doc.exists) return null;
    return Configuracion.fromFirestore(doc.data() ?? {});
  }

  Future<void> guardarConfiguracion(Configuracion config) async {
    await _db
        .collection(configuracionCollection)
        .doc(configuracionDoc)
        .set(config.toFirestore(useServerTimestamps: true), SetOptions(merge: true));
  }

  // ─── Conversaciones (colección raíz, dueño por usuarioId) ───

  CollectionReference<Map<String, dynamic>> get _conversacionesRef =>
      _db.collection(conversacionesCollection);

  Future<List<Conversacion>> obtenerConversaciones(String uid,
      {int limite = 50}) async {
    final snapshot = await _conversacionesRef
        .where('usuarioId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limite)
        .get();

    return snapshot.docs
        .map((doc) => Conversacion.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<String> crearConversacion(
    String uid, {
    String titulo = 'Nueva conversación',
  }) async {
    final docRef = await _conversacionesRef.add({
      'usuarioId': uid,
      'titulo': titulo,
      'estado': 'activa',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> actualizarTituloConversacion(
    String conversacionId,
    String titulo,
  ) async {
    await _conversacionesRef.doc(conversacionId).update({
      'titulo': titulo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarConversacion(String conversacionId) async {
    final batch = _db.batch();
    final convRef = _conversacionesRef.doc(conversacionId);
    batch.delete(convRef);

    final mensajes = await convRef.collection('mensajes').get();
    for (final doc in mensajes.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ─── Mensajes (subcolección de conversaciones) ───

  CollectionReference<Map<String, dynamic>> _mensajesRef(String conversacionId) {
    return _conversacionesRef.doc(conversacionId).collection('mensajes');
  }

  /// Devuelve los últimos [limite] mensajes (los consulta del más reciente al
  /// más viejo, pero los devuelve en orden cronológico ascendente).
  /// [antesDe] actúa como cursor: trae los mensajes anteriores a esa fecha.
  Future<List<Mensaje>> obtenerMensajes(
    String conversacionId, {
    int limite = 20,
    DateTime? antesDe,
  }) async {
    Query<Map<String, dynamic>> query =
        _mensajesRef(conversacionId).orderBy('createdAt', descending: true);
    if (antesDe != null) {
      query = query.startAfter([Timestamp.fromDate(antesDe)]);
    }
    final snapshot = await query.limit(limite).get();

    final mensajes = snapshot.docs
        .map((doc) => Mensaje.fromFirestore(doc.data(), doc.id))
        .toList();
    return mensajes.reversed.toList();
  }

  Future<void> guardarMensaje(String conversacionId, Mensaje mensaje) async {
    await _mensajesRef(conversacionId).add(
      mensaje.toFirestore(useServerTimestamps: true),
    );
    await _conversacionesRef.doc(conversacionId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Carritos ───

  CollectionReference<Map<String, dynamic>> _itemsCarritoRef(String uid) {
    return _db.collection(carritosCollection).doc(uid).collection('items');
  }

  Future<Carrito> obtenerCarrito(String uid) async {
    final doc = await _db.collection(carritosCollection).doc(uid).get();
    final itemsSnap = await _itemsCarritoRef(uid).get();
    final items = itemsSnap.docs
        .map((d) => ItemCarrito.fromFirestore(d.data(), d.id))
        .toList();
    if (!doc.exists) {
      return Carrito(
        id: uid,
        estado: 'activo',
        moneda: 'ARS',
        updatedAt: DateTime.now(),
        items: items,
      );
    }
    return Carrito.fromFirestore(doc.data() ?? {}, uid, items: items);
  }

  Future<void> guardarItemCarrito(
    String uid,
    String productoId,
    ItemCarrito item,
  ) async {
    if (item.cantidad <= 0) {
      await eliminarItemCarrito(uid, productoId);
      return;
    }
    await _itemsCarritoRef(uid).doc(productoId).set(
          item.toFirestore(useServerTimestamps: true),
        );
    await _db.collection(carritosCollection).doc(uid).set({
      'estado': 'activo',
      'moneda': 'ARS',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> agregarAlCarrito(
    String uid,
    String productoId, {
    int cantidad = 1,
  }) async {
    if (cantidad <= 0) return;
    final itemDoc = await _itemsCarritoRef(uid).doc(productoId).get();
    int nuevaCantidad = cantidad;
    if (itemDoc.exists) {
      final actual = (itemDoc.data()?['cantidad'] as num?)?.toInt() ?? 0;
      nuevaCantidad = actual + cantidad;
    }
    await _itemsCarritoRef(uid).doc(productoId).set({
      'cantidad': nuevaCantidad,
      'addedAt': itemDoc.exists
          ? (itemDoc.data()?['addedAt'] ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection(carritosCollection).doc(uid).set({
      'estado': 'activo',
      'moneda': 'ARS',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> actualizarCantidadCarrito(
    String uid,
    String productoId,
    int cantidad,
  ) async {
    if (cantidad <= 0) {
      await eliminarItemCarrito(uid, productoId);
      return;
    }
    await _itemsCarritoRef(uid).doc(productoId).update({
      'cantidad': cantidad,
    });
    await _db.collection(carritosCollection).doc(uid).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> eliminarItemCarrito(String uid, String productoId) async {
    await _itemsCarritoRef(uid).doc(productoId).delete();
    await _db.collection(carritosCollection).doc(uid).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> vaciarCarrito(String uid) async {
    final itemsSnap = await _itemsCarritoRef(uid).get();
    final batch = _db.batch();
    for (final doc in itemsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.set(_db.collection(carritosCollection).doc(uid), {
      'estado': 'activo',
      'moneda': 'ARS',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  // ─── Pedidos ───

  Future<String> crearPedido(Pedido pedido) async {
    final docRef = await _db
        .collection(pedidosCollection)
        .add(pedido.toFirestore(useServerTimestamps: true));
    return docRef.id;
  }

  Future<Pedido?> obtenerPedido(String pedidoId) async {
    final doc = await _db.collection(pedidosCollection).doc(pedidoId).get();
    if (!doc.exists) return null;
    return Pedido.fromFirestore(doc.data() ?? {}, doc.id);
  }

  Future<List<Pedido>> obtenerPedidos(String uid, {int limite = 50}) async {
    final snapshot = await _db
        .collection(pedidosCollection)
        .where('usuarioId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limite)
        .get();
    return snapshot.docs
        .map((doc) => Pedido.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
