import 'dart:developer';

import '../modelo/usuario.dart';
import '../modelo/firebase/firestore.dart';

class LoginController {
  LoginController._();
  static final LoginController instance = LoginController._();

  final FirestoreService _firestoreService = FirestoreService();
  Usuario? usuarioActual;

  Future<Usuario?> iniciarSesionConDni(String dni) async {
    final dniTrim = dni.trim();
    if (dniTrim.isEmpty) return null;

    try {
      final usuario = await _firestoreService.obtenerUsuarioPorDNI(dniTrim) ??
          await _crearUsuario(dniTrim);

      usuarioActual = usuario;
      return usuario;
    } catch (e, stack) {
      log('Error en login con DNI: $e', stackTrace: stack);
      return null;
    }
  }

  Future<Usuario> _crearUsuario(String dni) async {
    return _firestoreService.crearUsuario(dni);
  }

  bool estaLogueado() => usuarioActual != null;

  void cerrarSesion() {
    usuarioActual = null;
  }
}
