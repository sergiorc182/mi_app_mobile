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

      Usuario? usuario;
      try {
        usuario = await _firestoreService.obtenerUsuario(uid);
      } catch (e) {
        log('Aviso al obtener usuario de Firestore: $e');
      }

      // Si la cuenta existe en Authentication pero no tiene perfil en Firestore,
      // no inventamos datos arbitrarios en Firestore. Creamos la representación en memoria
      // y permitimos que el usuario complete su perfil posteriormente.
      usuario ??= Usuario(
        id: uid,
        nombre: firebaseUser?.displayName ?? '',
        apellido: '',
        dni: '',
        email: firebaseUser?.email ?? emailTrim,
        fotoPerfil: firebaseUser?.photoURL ?? '',
        createdAt: firebaseUser?.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
        activo: true,
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

    Usuario? usuario;
    try {
      usuario = await _firestoreService.obtenerUsuario(user.uid);
    } catch (e) {
      log('Aviso al cargar usuario actual: $e');
    }

    usuario ??= Usuario(
      id: user.uid,
      nombre: user.displayName ?? '',
      apellido: '',
      dni: '',
      email: user.email ?? '',
      fotoPerfil: user.photoURL ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
      activo: true,
    );

    usuarioActual = usuario;
    return usuario;
  }

  Future<bool> recuperarPassword(String email) async {
    final emailTrim = email.trim().toLowerCase();
    if (emailTrim.isEmpty) return false;
    try {
      await _authService.sendPasswordResetEmail(emailTrim);
      return true;
    } catch (e, stack) {
      log('Error al enviar correo de recuperación: $e', stackTrace: stack);
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    await _authService.signOut();
    usuarioActual = null;
  }

  bool estaLogueado() => _authService.currentUser != null;
}
