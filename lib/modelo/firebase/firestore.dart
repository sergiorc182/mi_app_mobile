import 'package:cloud_firestore/cloud_firestore.dart';

import '../../modelo/conversacion.dart';
import '../../modelo/mensaje.dart';
import '../../modelo/producto.dart';
import '../../modelo/usuario.dart';

class FirestoreService {
  static const String usersCollection = 'users';
  static const String conversacionesCollection = 'conversaciones';
  static const String mensajesCollection = 'mensajes';
  static const String productosCollection = 'productos';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> crearUsuario(Usuario usuario) async {
    await _db.collection(usersCollection).doc(usuario.id).set(
      usuario.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<Usuario?> obtenerUsuario(String uid) async {
    final doc = await _db.collection(usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromFirestore(doc.data() ?? {}, doc.id);
  }

  Future<void> actualizarUsuario(String uid, Map<String, dynamic> data) async {
    await _db.collection(usersCollection).doc(uid).update(data);
  }

  Future<List<Conversacion>> obtenerConversaciones(String usuarioId) async {
    final snapshot = await _db
        .collection(conversacionesCollection)
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    final conversaciones = snapshot.docs
        .map((doc) => Conversacion.fromFirestore(doc.data(), doc.id))
        .toList();
    conversaciones.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return conversaciones;
  }

  Future<String> crearConversacion(String usuarioId, {String titulo = 'Nueva conversación'}) async {
    final docRef = await _db.collection(conversacionesCollection).add({
      'usuarioId': usuarioId,
      'titulo': titulo,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
  }

  Future<void> eliminarConversacion(String conversacionId) async {
    final batch = _db.batch();
    batch.delete(_db.collection(conversacionesCollection).doc(conversacionId));

    final mensajes = await _db
        .collection(mensajesCollection)
        .where('conversacionId', isEqualTo: conversacionId)
        .get();

    for (final doc in mensajes.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<Mensaje>> obtenerMensajes(String conversacionId) async {
    final snapshot = await _db
        .collection(mensajesCollection)
        .where('conversacionId', isEqualTo: conversacionId)
        .get();

    final mensajes = snapshot.docs
        .map((doc) => Mensaje.fromFirestore(doc.data(), doc.id))
        .toList();
    mensajes.sort((a, b) => a.fecha.compareTo(b.fecha));
    return mensajes;
  }

  Future<void> guardarMensaje(Mensaje mensaje) async {
    await _db.collection(mensajesCollection).add(mensaje.toFirestore());
  }

  Future<void> asegurarProductosIniciales() async {
    final snapshot = await _db.collection(productosCollection).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final productosIniciales = [
      {
        'nombre': 'iPhone 15',
        'categoria': 'Celulares',
        'marca': 'Apple',
        'precio': 999000.0,
        'stock': 12,
        'descripcion': 'Smartphone de última generación',
        'imagen': '',
        'activo': true,
      },
      {
        'nombre': 'MacBook Air',
        'categoria': 'Laptops',
        'marca': 'Apple',
        'precio': 1499000.0,
        'stock': 7,
        'descripcion': 'Laptop ligera y potente',
        'imagen': '',
        'activo': true,
      },
      {
        'nombre': 'Auriculares Sony',
        'categoria': 'Audio',
        'marca': 'Sony',
        'precio': 189000.0,
        'stock': 20,
        'descripcion': 'Sonido envolvente y batería larga',
        'imagen': '',
        'activo': true,
      },
    ];

    for (final producto in productosIniciales) {
      await _db.collection(productosCollection).add(producto);
    }
  }

  Future<List<Producto>> buscarProductos(String texto) async {
    await asegurarProductosIniciales();

    final snapshot = await _db
        .collection(productosCollection)
        .where('activo', isEqualTo: true)
        .get();

    final consulta = texto.toLowerCase();
    return snapshot.docs
        .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
        .where((producto) {
          final hayCoincidencia = producto.nombre.toLowerCase().contains(consulta) ||
              producto.categoria.toLowerCase().contains(consulta) ||
              producto.marca.toLowerCase().contains(consulta) ||
              producto.descripcion.toLowerCase().contains(consulta);
          return hayCoincidencia;
        })
        .toList();
  }
}
