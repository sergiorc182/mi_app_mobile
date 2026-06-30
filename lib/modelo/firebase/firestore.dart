import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelo/usuario.dart';
import 'firebase.dart';

class FirestoreService {
  static const String usersCollection = 'users';
  static const String legacyUsuarioCollection = 'Usuario';
  static const String preguntasCollection = 'preguntas';

  // Getter to avoid accessing FirebaseFirestore.instance before Firebase is initialized
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<Usuario?> obtenerUsuarioPorDNI(String dni) async {
    final result = await _db
        .collection(usersCollection)
        .where('dni', isEqualTo: dni)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    final doc = result.docs.first;
    return Usuario.fromFirestore(doc.data(), doc.id);
  }

  Future<Usuario> crearUsuario(String dni) async {
    final data = {
      'dni': dni,
      'nombre': 'Usuario',
      'email': '',
      'imagenCara': '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _db.collection(usersCollection).add(data);
    final doc = await docRef.get();
    final docData = doc.data();
    if (docData == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'No se pudo obtener el documento de usuario creado',
      );
    }
    return Usuario.fromFirestore(docData, doc.id);
  }

  Future<FirebaseStatus> verificarColeccionUsers() async {
    try {
      final snapshot = await _db.collection(usersCollection).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return FirebaseStatus.connected;
      }

      final legacySnapshot =
          await _db.collection(legacyUsuarioCollection).limit(20).get();
      if (legacySnapshot.docs.isNotEmpty) {
        await _migrarColeccionUsuario(legacySnapshot.docs);
        return FirebaseStatus.collectionMissing;
      }

      await _db.collection(usersCollection).add({
        'dni': '00000000',
        'nombre': 'Sistema',
        'email': '',
        'imagenCara': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return FirebaseStatus.collectionMissing;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return FirebaseStatus.firestoreDenied;
      }
      return FirebaseStatus.firestoreError;
    } catch (_) {
      return FirebaseStatus.firestoreError;
    }
  }

  Future<void> _migrarColeccionUsuario(
      List<QueryDocumentSnapshot> docs) async {
    final batch = _db.batch();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final newData = {
        'dni': data['dni'] ?? '00000000',
        'nombre': data['nombre'] ?? 'Usuario',
        'email': data['email'] ?? '',
        'imagenCara': data['imagenCara'] ?? '',
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      };
      final newRef = _db.collection(usersCollection).doc();
      batch.set(newRef, newData);
    }
    await batch.commit();
  }

  Future<List<Map<String, String>>> obtenerPreguntas() async {
    final snapshot = await _db.collection(preguntasCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'keyword': data['keyword'] as String? ?? '',
        'pregunta': data['pregunta'] as String? ?? 'Contame más sobre lo que buscás',
      };
    }).toList();
  }

  Future<String> obtenerRespuestaPorIntencion(String texto) async {
    try {
      final snapshot = await _db.collection(preguntasCollection).get();
      final mensaje = texto.toLowerCase();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final keyword = data['keyword'] as String? ?? '';
        if (keyword.isNotEmpty && mensaje.contains(keyword.toLowerCase())) {
          return data['pregunta'] as String? ??
              'Contame más sobre lo que buscás';
        }
      }

      return 'Contame más sobre lo que buscás';
    } catch (_) {
      return 'Contame más sobre lo que buscás';
    }
  }

  Future<void> semillarPreguntas() async {
    try {
      final snapshot = await _db.collection(preguntasCollection).limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final preguntasIniciales = [
        {'keyword': 'aire', 'pregunta': '¿Cuántas frigorías necesitás?'},
        {'keyword': 'tv', 'pregunta': '¿De cuántas pulgadas?'},
        {'keyword': 'heladera', 'pregunta': '¿Con freezer o sin freezer?'},
        {'keyword': 'lavarropa', 'pregunta': '¿De carga frontal o superior?'},
        {'keyword': 'cocina', 'pregunta': '¿A gas o eléctrica?'},
        {'keyword': 'microondas', 'pregunta': '¿Con grill o sin grill?'},
      ];

      for (final data in preguntasIniciales) {
        await _db.collection(preguntasCollection).add(data);
      }
    } catch (_) {
      // Ignorar errores de inicialización de preguntas.
    }
  }
}
