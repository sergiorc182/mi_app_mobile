import 'package:cloud_firestore/cloud_firestore.dart';

import '../conversacion.dart';
import '../mensaje.dart';
import '../usuario.dart';

class FirestoreService {
  static const String usersCollection = 'users';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ─── Usuarios ───

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

  // ─── Conversaciones (subcolección de users/{uid}) ───

  CollectionReference<Map<String, dynamic>> _conversacionesRef(String uid) {
    return _db.collection(usersCollection).doc(uid).collection('conversaciones');
  }

  Future<List<Conversacion>> obtenerConversaciones(String uid) async {
    final snapshot = await _conversacionesRef(uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Conversacion.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<String> crearConversacion(String uid, {String titulo = 'Nueva conversación'}) async {
    final docRef = await _conversacionesRef(uid).add({
      'titulo': titulo,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
  }

  Future<void> eliminarConversacion(String uid, String conversacionId) async {
    final batch = _db.batch();
    final convRef = _conversacionesRef(uid).doc(conversacionId);
    batch.delete(convRef);

    final mensajes = await convRef.collection('mensajes').get();
    for (final doc in mensajes.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ─── Mensajes (subcolección de conversaciones) ───

  CollectionReference<Map<String, dynamic>> _mensajesRef(String uid, String conversacionId) {
    return _conversacionesRef(uid).doc(conversacionId).collection('mensajes');
  }

  Future<List<Mensaje>> obtenerMensajes(String uid, String conversacionId) async {
    final snapshot = await _mensajesRef(uid, conversacionId)
        .orderBy('fecha', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => Mensaje.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> guardarMensaje(String uid, String conversacionId, Mensaje mensaje) async {
    await _mensajesRef(uid, conversacionId).add(mensaje.toFirestore());
  }
}
