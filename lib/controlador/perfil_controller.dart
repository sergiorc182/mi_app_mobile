import 'dart:developer';

import '../modelo/usuario.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class PerfilController {
  PerfilController._();
  static final PerfilController instance = PerfilController._();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<Usuario?> cargarPerfil() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      return _firestoreService.obtenerUsuario(user.uid);
    } catch (e, stack) {
      log('Error al cargar perfil: $e', stackTrace: stack);
      return null;
    }
  }

  Future<Usuario?> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String fotoPerfil,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      await _firestoreService.actualizarUsuario(
        user.uid,
        {
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'fotoPerfil': fotoPerfil.trim(),
        },
      );
      return _firestoreService.obtenerUsuario(user.uid);
    } catch (e, stack) {
      log('Error al actualizar perfil: $e', stackTrace: stack);
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    await _authService.signOut();
  }
}
