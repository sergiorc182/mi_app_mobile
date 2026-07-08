import '../modelo/chat_service.dart';
import '../modelo/conversacion.dart';
import '../modelo/mensaje.dart';
import '../modelo/producto.dart';
import '../modelo/producto_service.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class ChatController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  final ProductoService _productoService = ProductoService();
  bool _catalogoCargado = false;

  Conversacion? conversacionSeleccionada;
  List<Conversacion> conversaciones = [];
  List<Mensaje> mensajes = [];
  bool isLoading = false;
  String? errorMensaje;

  String get _uid => _authService.currentUser?.uid ?? '';

  Future<List<Conversacion>> cargarConversaciones() async {
    final uid = _uid;
    if (uid.isEmpty) return [];

    conversaciones = await _firestoreService.obtenerConversaciones(uid);
    if (conversacionSeleccionada == null && conversaciones.isNotEmpty) {
      conversacionSeleccionada = conversaciones.first;
    }
    return conversaciones;
  }

  Future<List<Mensaje>> cargarMensajes(String conversacionId) async {
    final uid = _uid;
    if (uid.isEmpty) return [];

    mensajes = await _firestoreService.obtenerMensajes(uid, conversacionId);
    return mensajes;
  }

  Future<Conversacion?> crearNuevaConversacion() async {
    final uid = _uid;
    if (uid.isEmpty) return null;

    final id = await _firestoreService.crearConversacion(uid);
    final nueva = Conversacion(
      id: id,
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
    final uid = _uid;
    final contenido = texto.trim();
    if (contenido.isEmpty || uid.isEmpty) return mensajes;

    if (conversacionSeleccionada == null) {
      await crearNuevaConversacion();
    }

    final conversacionId = conversacionSeleccionada?.id;
    if (conversacionId == null) return mensajes;

    isLoading = true;
    errorMensaje = null;

    try {
      final mensajeUsuario = Mensaje(
        id: '',
        conversacionId: conversacionId,
        autor: 'user',
        mensaje: contenido,
        fecha: DateTime.now(),
      );
      await _firestoreService.guardarMensaje(uid, conversacionId, mensajeUsuario);

      if (!_catalogoCargado) {
        await _productoService.cargarCatalogo();
        _catalogoCargado = true;
      }

      final historial = mensajes
          .map((m) => {'role': m.autor == 'user' ? 'user' : 'assistant', 'content': m.mensaje})
          .toList();

      final productos = _productoService.buscar(contenido);
      if (productos.isNotEmpty) {
        final contexto = productos.take(5).map((p) => p.presentacion).join('\n');
        historial.add({
          'role': 'system',
          'content': 'Productos disponibles según la consulta del usuario:\n$contexto\n\n'
              'Usá esta información para responder. No inventes productos que no estén en esta lista.',
        });
      }

      final respuesta = await _chatService.sendMessage(contenido, historial);
      final mensajeBot = Mensaje(
        id: '',
        conversacionId: conversacionId,
        autor: 'assistant',
        mensaje: respuesta,
        fecha: DateTime.now(),
      );
      await _firestoreService.guardarMensaje(uid, conversacionId, mensajeBot);
    } catch (e) {
      errorMensaje = e.toString();
    } finally {
      isLoading = false;
      mensajes = await _firestoreService.obtenerMensajes(uid, conversacionId);
    }

    return mensajes;
  }

  Future<void> eliminarConversacion(String conversacionId) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    await _firestoreService.eliminarConversacion(uid, conversacionId);
    conversaciones.removeWhere((c) => c.id == conversacionId);
    if (conversacionSeleccionada?.id == conversacionId) {
      conversacionSeleccionada = conversaciones.isNotEmpty ? conversaciones.first : null;
      mensajes = [];
    }
  }

  Future<void> eliminarHistorial() async {
    final uid = _uid;
    if (uid.isEmpty) return;

    for (final conv in conversaciones) {
      await _firestoreService.eliminarConversacion(uid, conv.id);
    }
    conversaciones = [];
    conversacionSeleccionada = null;
    mensajes = [];
  }
}

extension on Iterable<Conversacion> {
  Conversacion? get firstOrNull => isEmpty ? null : first;
}
