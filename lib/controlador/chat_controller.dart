import '../modelo/chat_service.dart';
import '../modelo/conversacion.dart';
import '../modelo/info_pdf_service.dart';
import '../modelo/mensaje.dart';
import '../modelo/producto_service.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class ChatController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  final ProductoService _productoService = ProductoService();
  final InfoPdfService _infoPdfService = InfoPdfService();
  bool _catalogoCargado = false;
  bool _infoPdfCargado = false;

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

    mensajes = await _firestoreService.obtenerMensajes(conversacionId);
    return mensajes;
  }

  Future<Conversacion?> crearNuevaConversacion() async {
    final uid = _uid;
    if (uid.isEmpty) return null;

    final id = await _firestoreService.crearConversacion(uid);
    final ahora = DateTime.now();
    final nueva = Conversacion(
      id: id,
      usuarioId: uid,
      titulo: 'Nueva conversación',
      estado: 'activa',
      createdAt: ahora,
      updatedAt: ahora,
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

  Future<List<String>> cargarCategorias() async {
    await _cargarCatalogo();
    return _productoService.categorias;
  }

  Future<void> _cargarCatalogo() async {
    if (_catalogoCargado) return;
    try {
      final productos = await _firestoreService.obtenerProductos();
      if (productos.isNotEmpty) {
        _productoService.usarCatalogo(productos);
      } else {
        await _productoService.cargarCatalogo();
      }
    } catch (_) {
      await _productoService.cargarCatalogo();
    }
    _catalogoCargado = true;
  }

  Future<void> _generarYGuardarTitulo(
    String uid,
    String conversacionId,
    String primerMensaje,
  ) async {
    var titulo = await _chatService.generarTitulo(primerMensaje);
    if (titulo.isEmpty) {
      titulo = _tituloDeRespaldo(primerMensaje);
    }
    if (titulo.isEmpty) return;

    try {
      await _firestoreService.actualizarTituloConversacion(
        conversacionId,
        titulo,
      );
    } catch (_) {
      return;
    }

    for (var i = 0; i < conversaciones.length; i++) {
      if (conversaciones[i].id == conversacionId) {
        final actual = conversaciones[i];
        conversaciones[i] = Conversacion(
          id: actual.id,
          usuarioId: actual.usuarioId,
          titulo: titulo,
          estado: actual.estado,
          createdAt: actual.createdAt,
          updatedAt: actual.updatedAt,
        );
        break;
      }
    }
    if (conversacionSeleccionada?.id == conversacionId) {
      final actual = conversacionSeleccionada!;
      conversacionSeleccionada = Conversacion(
        id: actual.id,
        usuarioId: actual.usuarioId,
        titulo: titulo,
        estado: actual.estado,
        createdAt: actual.createdAt,
        updatedAt: actual.updatedAt,
      );
    }
  }

  String _tituloDeRespaldo(String texto) {
    final palabras = texto.trim().split(RegExp(r'\s+')).take(4).join(' ');
    if (palabras.isEmpty) return '';
    return palabras.length > 40 ? palabras.substring(0, 40).trim() : palabras;
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

    final esPrimerMensaje = mensajes.isEmpty;

    isLoading = true;
    errorMensaje = null;

    try {
      final mensajeUsuario = Mensaje(
        id: '',
        autor: 'user',
        mensaje: contenido,
        createdAt: DateTime.now(),
        tipo: 'texto',
      );
      await _firestoreService.guardarMensaje(conversacionId, mensajeUsuario);

      final tituloFuture = esPrimerMensaje
          ? _generarYGuardarTitulo(uid, conversacionId, contenido)
          : Future.value();

      await _cargarCatalogo();

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

      if (!_infoPdfCargado) {
        await _infoPdfService.cargar();
        _infoPdfCargado = true;
      }

      final fragmentos = _infoPdfService.buscar(contenido);
      if (fragmentos.isNotEmpty) {
        final info = fragmentos.join('\n');
        historial.add({
          'role': 'system',
          'content': 'Información del asistente (extraída del documento de '
              'referencia):\n$info\n\n'
              'Usá esta información si responde a la consulta del usuario. '
              'No inventes datos que no estén ahí.',
        });
      }

      final respuesta = await _chatService.sendMessage(contenido, historial);
      await tituloFuture;
      final mensajeBot = Mensaje(
        id: '',
        autor: 'assistant',
        mensaje: respuesta,
        createdAt: DateTime.now(),
        tipo: 'texto',
      );
      await _firestoreService.guardarMensaje(conversacionId, mensajeBot);
    } catch (e) {
      errorMensaje = e.toString();
    } finally {
      isLoading = false;
      mensajes = await _firestoreService.obtenerMensajes(conversacionId);
    }

    return mensajes;
  }

  Future<void> eliminarConversacion(String conversacionId) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    await _firestoreService.eliminarConversacion(conversacionId);
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
      await _firestoreService.eliminarConversacion(conv.id);
    }
    conversaciones = [];
    conversacionSeleccionada = null;
    mensajes = [];
  }
}

extension on Iterable<Conversacion> {
  Conversacion? get firstOrNull => isEmpty ? null : first;
}
