import 'dart:developer';

import '../modelo/conversacion.dart';
import '../modelo/mensaje.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class ChatController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Conversacion? conversacionSeleccionada;
  List<Conversacion> conversaciones = [];
  List<Mensaje> mensajes = [];

  Future<List<Conversacion>> cargarConversaciones() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    conversaciones = await _firestoreService.obtenerConversaciones(user.uid);
    if (conversacionSeleccionada == null && conversaciones.isNotEmpty) {
      conversacionSeleccionada = conversaciones.first;
    }
    return conversaciones;
  }

  Future<List<Mensaje>> cargarMensajes(String conversacionId) async {
    mensajes = await _firestoreService.obtenerMensajes(conversacionId);
    return mensajes;
  }

  Future<Conversacion?> crearNuevaConversacion() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    final id = await _firestoreService.crearConversacion(user.uid);
    final nueva = Conversacion(
      id: id,
      usuarioId: user.uid,
      titulo: 'Nueva conversación',
      createdAt: DateTime.now(),
    );

    conversaciones.insert(0, nueva);
    conversacionSeleccionada = nueva;
    mensajes = [];
    return nueva;
  }

  Future<void> seleccionarConversacion(String conversacionId) async {
    final seleccionada = conversaciones.where((c) => c.id == conversacionId).firstOrNull;
    if (seleccionada != null) {
      conversacionSeleccionada = seleccionada;
    }
  }

  Future<List<Mensaje>> enviarMensaje(String texto) async {
    final contenido = texto.trim();
    if (contenido.isEmpty) return mensajes;

    if (conversacionSeleccionada == null) {
      await crearNuevaConversacion();
    }

    final conversacionId = conversacionSeleccionada?.id;
    if (conversacionId == null) return mensajes;

    final mensajeUsuario = Mensaje(
      id: '',
      conversacionId: conversacionId,
      autor: 'user',
      mensaje: contenido,
      fecha: DateTime.now(),
    );
    await _firestoreService.guardarMensaje(mensajeUsuario);

    final respuesta = await _generarRespuestaBot(contenido);
    final mensajeBot = Mensaje(
      id: '',
      conversacionId: conversacionId,
      autor: 'bot',
      mensaje: respuesta,
      fecha: DateTime.now(),
    );
    await _firestoreService.guardarMensaje(mensajeBot);

    mensajes = await _firestoreService.obtenerMensajes(conversacionId);
    return mensajes;
  }

  Future<void> eliminarConversacion(String conversacionId) async {
    await _firestoreService.eliminarConversacion(conversacionId);
    conversaciones.removeWhere((c) => c.id == conversacionId);
    if (conversacionSeleccionada?.id == conversacionId) {
      conversacionSeleccionada = conversaciones.isNotEmpty ? conversaciones.first : null;
      mensajes = [];
    }
  }

  Future<String> _generarRespuestaBot(String texto) async {
    try {
      final productos = await _firestoreService.buscarProductos(texto);
      if (productos.isNotEmpty) {
        final producto = productos.first;
        return 'Vi este producto: ${producto.nombre} por ${producto.precio.toStringAsFixed(0)}. ¿Quieres que te ayude con más opciones?';
      }
      return 'Gracias por tu mensaje. Estoy listo para ayudarte con productos, categorías o recomendaciones.';
    } catch (e, stack) {
      log('Error al generar respuesta del bot: $e', stackTrace: stack);
      return 'Gracias por tu mensaje. Estoy listo para ayudarte.';
    }
  }
}

extension on Iterable<Conversacion> {
  Conversacion? get firstOrNull => isEmpty ? null : first;
}
