import '../modelo/configuracion.dart';
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
  Configuracion? configuracion;

  Conversacion? conversacionSeleccionada;
  List<Conversacion> conversaciones = [];
  List<Mensaje> mensajes = [];
  bool isLoading = false;
  String? errorMensaje;

  String get _uid => _authService.currentUser?.uid ?? '';

  Future<Configuracion?> cargarConfiguracion() async {
    try {
      configuracion = await _firestoreService.obtenerConfiguracion();
    } catch (_) {
      // Si no existe o no hay acceso, se usa la configuración por defecto
    }
    return configuracion;
  }

  Future<List<Conversacion>> cargarConversaciones() async {
    final uid = _uid;
    if (uid.isEmpty) return [];

    try {
      conversaciones = await _firestoreService.obtenerConversaciones(uid);
    } catch (e) {
      errorMensaje = _mensajeError(e);
      return conversaciones;
    }
    if (conversacionSeleccionada == null && conversaciones.isNotEmpty) {
      conversacionSeleccionada = conversaciones.first;
    }
    return conversaciones;
  }

  Future<List<Mensaje>> cargarMensajes(String conversacionId) async {
    final uid = _uid;
    if (uid.isEmpty) return [];

    try {
      mensajes = await _firestoreService.obtenerMensajes(conversacionId);
    } catch (e) {
      errorMensaje = _mensajeError(e);
    }
    return mensajes;
  }

  Future<Conversacion?> crearNuevaConversacion() async {
    final uid = _uid;
    if (uid.isEmpty) return null;

    String id;
    try {
      id = await _firestoreService.crearConversacion(uid);
    } catch (e) {
      errorMensaje = _mensajeError(e);
      return null;
    }
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
    try {
      final categoriasFirestore =
          await _firestoreService.obtenerCategorias(soloActivas: true);
      if (categoriasFirestore.isNotEmpty) {
        return categoriasFirestore.map((c) => c.nombre).toList();
      }
    } catch (_) {}
    await _cargarCatalogo();
    return _productoService.categorias;
  }

  /// Arma el contexto del catálogo que se envía a la IA en cada consulta.
  /// Se manda siempre (no solo cuando hay coincidencias) porque, si no se
  /// envía, el modelo responde que "no tiene acceso al catálogo en tiempo
  /// real".
  String? _contextoCatalogo(String consulta) {
    final catalogo = _productoService.catalogo;
    if (catalogo.isEmpty) return null;

    final coincidencias = _productoService.buscar(consulta).take(5).toList();
    final buffer = StringBuffer()
      ..writeln('Productos disponibles en total: ${catalogo.length}.');

    if (coincidencias.isNotEmpty) {
      buffer.writeln('Productos que coinciden con la consulta:');
      for (final producto in coincidencias) {
        buffer.writeln(producto.presentacion);
      }
    }

    buffer.writeln('Catálogo actual (marca, nombre, categoría, precio y stock):');
    for (final producto in catalogo.take(60)) {
      buffer.writeln(
        '- ${producto.marca} ${producto.nombre} | ${producto.categoria} | '
        '\$${producto.precio.toStringAsFixed(0)} ${producto.moneda} | '
        'stock: ${producto.stock}',
      );
    }
    return buffer.toString().trim();
  }

  Future<void> _cargarCatalogo() async {
    if (_catalogoCargado) return;
    try {
      final productos = await _firestoreService.obtenerProductos(limite: 200);
      if (productos.isNotEmpty) {
        _productoService.usarCatalogo(productos);
      } else {
        await _productoService.cargarCatalogo(consultarFirestore: false);
      }
    } catch (_) {
      // Firestore no disponible: se usa el catálogo del bundle local sin
      // volver a consultar la red.
      await _productoService.cargarCatalogo(consultarFirestore: false);
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
      // Sin permiso de Firestore: el título queda solo en memoria.
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

  /// Ventana del historial que se envía a la IA. Sin tope, cada turno reenvía
  /// la conversación completa y la latencia y el costo crecen sin límite.
  static const int _maxMensajesHistorial = 12;

  /// Devuelve las últimas interacciones recortando en un par user/assistant
  /// para que el historial siempre empiece con un mensaje del usuario.
  List<Map<String, String>> _historialReciente() {
    final todos = mensajes
        .map((m) => {
              'role': m.autor == 'user' ? 'user' : 'assistant',
              'content': m.mensaje,
            })
        .toList();

    if (todos.length <= _maxMensajesHistorial) return todos;

    var inicio = todos.length - _maxMensajesHistorial;
    if (todos[inicio]['role'] == 'assistant') inicio += 1;
    return todos.sublist(inicio);
  }

  Future<List<Mensaje>> enviarMensaje(String texto) async {
    final uid = _uid;
    final contenido = texto.trim();
    if (contenido.isEmpty || uid.isEmpty) return mensajes;
    if (isLoading) return mensajes;

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

      if (configuracion == null) {
        await cargarConfiguracion();
      }

      await _cargarCatalogo();

      final historial = _historialReciente();

      String? contextoCatalogo;
      if (configuracion?.catalogoHabilitado ?? true) {
        contextoCatalogo = _contextoCatalogo(contenido);
      }

      if (!_infoPdfCargado) {
        await _infoPdfService.cargar();
        _infoPdfCargado = true;
      }

      final fragmentos = _infoPdfService.buscar(contenido);
      final contextoInfo = fragmentos.join('\n');

      final respuesta = await _chatService.sendMessage(
        contenido,
        historial,
        contextoCatalogo:
            (contextoCatalogo == null || contextoCatalogo.isEmpty)
                ? null
                : contextoCatalogo,
        contextoInfo: contextoInfo.isEmpty ? null : contextoInfo,
      );
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
      errorMensaje = _mensajeError(e);
    } finally {
      isLoading = false;
      try {
        mensajes = await _firestoreService.obtenerMensajes(conversacionId);
      } catch (_) {
        // Sin permiso de Firestore: se conserva lo que hay en memoria.
      }
    }

    return mensajes;
  }

  String _mensajeError(Object e) {
    final texto = e.toString();
    if (texto.contains('permission-denied') || texto.contains('PERMISSION_DENIED')) {
      return 'Sin permiso de Firestore: publicá las reglas del esquema nuevo '
          '(firestore.rules) en el proyecto.';
    }
    return texto;
  }

  Future<void> eliminarConversacion(String conversacionId) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    try {
      await _firestoreService.eliminarConversacion(conversacionId);
    } catch (e) {
      errorMensaje = _mensajeError(e);
    }
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
      try {
        await _firestoreService.eliminarConversacion(conv.id);
      } catch (e) {
        errorMensaje = _mensajeError(e);
      }
    }
    conversaciones = [];
    conversacionSeleccionada = null;
    mensajes = [];
  }
}

extension on Iterable<Conversacion> {
  Conversacion? get firstOrNull => isEmpty ? null : first;
}
