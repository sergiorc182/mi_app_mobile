import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

import '../modelo/usuario.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class RegistroResultado {
  const RegistroResultado({this.usuario, this.mensaje});

  final Usuario? usuario;
  final String? mensaje;

  bool get ok => usuario != null;
}

class RegistroController {
  RegistroController._();
  static final RegistroController instance = RegistroController._();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<RegistroResultado> registrar({
    required String nombre,
    required String apellido,
    required String dni,
    required String email,
    required String password,
    required String confirmarPassword,
  }) async {
    final error = validarDatos(
      nombre: nombre,
      apellido: apellido,
      dni: dni,
      email: email,
      password: password,
      confirmarPassword: confirmarPassword,
    );

    if (error != null) {
      return RegistroResultado(mensaje: error);
    }

    final nombreTrim = nombre.trim();
    final apellidoTrim = apellido.trim();
    final dniTrim = dni.trim();
    final emailTrim = email.trim().toLowerCase();

    try {
      final cred = await _authService.createUserWithEmailAndPassword(
        emailTrim,
        password,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        return const RegistroResultado(mensaje: 'No se pudo crear la cuenta. Intentá nuevamente.');
      }

      final usuario = Usuario(
        id: uid,
        nombre: nombreTrim,
        apellido: apellidoTrim,
        dni: dniTrim,
        email: emailTrim,
        fotoPerfil: '',
        createdAt: DateTime.now(),
      );

      await _firestoreService.crearUsuario(usuario);
      return RegistroResultado(usuario: usuario);
    } on FirebaseAuthException catch (e, stack) {
      log('Error al registrar usuario: ${e.code} - ${e.message}', stackTrace: stack);
      return RegistroResultado(mensaje: _mensajeAuthError(e.code));
    } catch (e, stack) {
      log('Error al registrar usuario: $e', stackTrace: stack);
      return const RegistroResultado(mensaje: 'No se pudo crear la cuenta. Revisá la conexión e intentá de nuevo.');
    }
  }

  static String? validarDatos({
    required String nombre,
    required String apellido,
    required String dni,
    required String email,
    required String password,
    required String confirmarPassword,
  }) {
    final nombreTrim = nombre.trim();
    final apellidoTrim = apellido.trim();
    final dniTrim = dni.trim();
    final emailTrim = email.trim();

    if (nombreTrim.isEmpty) {
      return 'Ingresá tu nombre.';
    }
    if (apellidoTrim.isEmpty) {
      return 'Ingresá tu apellido.';
    }
    if (dniTrim.isEmpty) {
      return 'Ingresá tu DNI.';
    }
    if (emailTrim.isEmpty) {
      return 'Ingresá un correo electrónico.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailTrim)) {
      return 'Ingresá un email válido.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (confirmarPassword.isEmpty) {
      return 'Confirmá la contraseña.';
    }
    if (password != confirmarPassword) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  String _mensajeAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'operation-not-allowed':
        return 'El acceso con email y contraseña no está habilitado.';
      default:
        return 'No se pudo crear la cuenta. Intentá nuevamente.';
    }
  }
}
