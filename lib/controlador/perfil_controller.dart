import 'dart:developer';

import '../modelo/usuario.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';
import 'login_controller.dart';

class PerfilController {
  PerfilController._();
  static final PerfilController instance = PerfilController._();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<Usuario?> cargarPerfil() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final usuario = await _firestoreService.obtenerUsuario(user.uid);
      if (usuario != null) return usuario;
    } catch (e, stack) {
      log('Error al cargar perfil: $e', stackTrace: stack);
    }

    return LoginController.instance.usuarioActual;
  }

  Future<Usuario?> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String dni,
    required String fotoPerfil,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    final actual = LoginController.instance.usuarioActual;
    final actualizado = Usuario(
      id: user.uid,
      nombre: nombre.trim().isEmpty ? (actual?.nombre ?? '') : nombre.trim(),
      apellido: apellido.trim(),
      dni: dni.trim(),
      email: actual?.email ?? user.email ?? '',
      fotoPerfil: fotoPerfil.trim(),
      createdAt: actual?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      activo: actual?.activo ?? true,
    );

    try {
      await _firestoreService.actualizarUsuario(user.uid, {
        'nombre': actualizado.nombre,
        'apellido': actualizado.apellido,
        'dni': actualizado.dni,
        'fotoPerfil': actualizado.fotoPerfil,
      });
    } catch (e, stack) {
      log('Error al actualizar perfil: $e', stackTrace: stack);
    }

    LoginController.instance.usuarioActual = actualizado;
    return actualizado;
  }

  Future<void> cerrarSesion() async {
    await _authService.signOut();
    LoginController.instance.usuarioActual = null;
  }
}
