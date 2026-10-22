import 'dart:developer';

import '../modelo/usuario.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class LoginController {
  LoginController._();
  static final LoginController instance = LoginController._();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Usuario? usuarioActual;

  Future<Usuario?> iniciarSesionConEmail({
    required String email,
    required String password,
  }) async {
    final emailTrim = email.trim().toLowerCase();
    if (emailTrim.isEmpty || password.isEmpty) return null;

    try {
      final cred = await _authService.signInWithEmailAndPassword(emailTrim, password);
      final firebaseUser = cred.user;
      final uid = firebaseUser?.uid;
      if (uid == null) return null;

      final usuario = await _asegurarPerfil(
        uid: uid,
        email: firebaseUser?.email ?? emailTrim,
        nombreMostrado: firebaseUser?.displayName,
      );

      usuarioActual = usuario;
      return usuario;
    } catch (e, stack) {
      log('Error en login con email: $e', stackTrace: stack);
      return null;
    }
  }

  Future<Usuario?> cargarUsuarioActual() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    final usuario = await _asegurarPerfil(
      uid: user.uid,
      email: user.email ?? '',
      nombreMostrado: user.displayName,
    );

    usuarioActual = usuario;
    return usuario;
  }

  /// Crea o completa el perfil en `usuarios/{uid}` con el esquema definitivo.
  /// Si el documento ya existe con todos los campos, no escribe nada.
  Future<Usuario> _asegurarPerfil({
    required String uid,
    required String email,
    String? nombreMostrado,
  }) async {
    Map<String, dynamic>? datos;
    try {
      datos = await _firestoreService.obtenerUsuarioDatos(uid);
    } catch (e) {
      log('Aviso al obtener usuario de Firestore: $e');
    }

    final ahora = DateTime.now();
    final nombre = (nombreMostrado?.trim().isNotEmpty ?? false)
        ? nombreMostrado!.trim()
        : email.split('@').first;

    final usuario = datos == null
        ? Usuario(
            id: uid,
            nombre: nombre,
            apellido: '',
            dni: '',
            email: email,
            fotoPerfil: '',
            createdAt: ahora,
            updatedAt: ahora,
            activo: true,
          )
        : Usuario.fromFirestore(datos, uid);

    final faltaNombre = datos?['nombre']?.toString().trim().isEmpty ?? true;
    final incompleto = datos == null ||
        !datos.containsKey('activo') ||
        !datos.containsKey('updatedAt') ||
        !datos.containsKey('createdAt') ||
        (faltaNombre && nombreMostrado != null);

    if (incompleto) {
      final aGuardar = faltaNombre && (nombreMostrado?.trim().isNotEmpty ?? false)
          ? Usuario(
              id: usuario.id,
              nombre: nombreMostrado!.trim(),
              apellido: usuario.apellido,
              dni: usuario.dni,
              email: usuario.email.isEmpty ? email : usuario.email,
              fotoPerfil: usuario.fotoPerfil,
              createdAt: usuario.createdAt,
              updatedAt: ahora,
              activo: usuario.activo,
            )
          : usuario;
      try {
        await _firestoreService.crearUsuario(aGuardar);
      } catch (e) {
        log('Aviso al guardar perfil en Firestore: $e');
      }
    }

    return usuario;
  }

  Future<void> cerrarSesion() async {
    await _authService.signOut();
    usuarioActual = null;
  }

  bool estaLogueado() => _authService.currentUser != null;
}
