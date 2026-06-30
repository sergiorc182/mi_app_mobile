import 'package:flutter/foundation.dart';
import '../modelo/firebase/firestore.dart';

class ChatController {
  final List<Map<String, String>> _mensajes = [
    {'bot': 'Hola 👋\n¿Qué estás buscando?'}
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final List<Map<String, String>> _preguntasCache = [];

  List<Map<String, String>> get mensajes => List.unmodifiable(_mensajes);

  VoidCallback? onChanged;

  int _usuarioMensajes = 0;

  Future<void> enviarMensaje(String texto) async {
    final contenido = texto.trim();
    if (contenido.isEmpty) return;

    _agregarMensajeUsuario(contenido);
    _usuarioMensajes++;

    if (_usuarioMensajes == 1) {
      _agregarMensajeBot('Contame más sobre lo que buscás');
      return;
    }

    if (_preguntasCache.isEmpty) {
      await _cargarPreguntas();
    }

    final respuesta = _buscarRespuestaLocal(contenido);
    _agregarMensajeBot(respuesta);
  }

  Future<void> _cargarPreguntas() async {
    final preguntas = await _firestoreService.obtenerPreguntas();
    _preguntasCache.addAll(preguntas);
  }

  String _buscarRespuestaLocal(String texto) {
    final mensaje = texto.toLowerCase();

    for (final pregunta in _preguntasCache) {
      final keyword = pregunta['keyword']?.toLowerCase() ?? '';
      final respuesta = pregunta['pregunta'];
      if (keyword.isNotEmpty && mensaje.contains(keyword)) {
        return respuesta ?? 'Contame más sobre lo que buscás';
      }
    }

    return 'Contame más sobre lo que buscás';
  }

  void _agregarMensajeUsuario(String texto) {
    _mensajes.add({'user': texto});
  }

  void _agregarMensajeBot(String texto) {
    _mensajes.add({'bot': texto});
    onChanged?.call();
  }
}
