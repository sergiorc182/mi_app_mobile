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
      final uid = cred.user?.uid;
      if (uid == null) return null;

      final usuario = await _firestoreService.obtenerUsuario(uid);
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

    final usuario = await _firestoreService.obtenerUsuario(user.uid);
    usuarioActual = usuario;
    return usuario;
  }

  Future<void> cerrarSesion() async {
    await _authService.signOut();
    usuarioActual = null;
  }

  bool estaLogueado() => _authService.currentUser != null;
}
