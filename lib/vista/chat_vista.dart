import 'package:flutter/material.dart';

import '../controlador/chat_controller.dart';
import 'perfil_vista.dart';

class ChatVista extends StatefulWidget {
  const ChatVista({super.key});

  @override
  State<ChatVista> createState() => _ChatVistaState();
}

class _ChatVistaState extends State<ChatVista> {
  final ChatController _chatController = ChatController();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await _chatController.cargarConversaciones();
    if (_chatController.conversacionSeleccionada != null) {
      await _chatController.cargarMensajes(_chatController.conversacionSeleccionada!.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    _mensajeController.clear();
    await _chatController.enviarMensaje(texto);
    if (mounted) setState(() {});
    if (_chatController.errorMensaje != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_chatController.errorMensaje!),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
      _chatController.errorMensaje = null;
    }
    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _nuevoChat() async {
    await _chatController.crearNuevaConversacion();
    if (mounted) setState(() {});
  }

  Future<void> _borrarHistorial() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text('¿Estás seguro de eliminar todas las conversaciones?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar todo')),
        ],
      ),
    );
    if (confirm != true) return;

    await _chatController.eliminarHistorial();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final conversaciones = _chatController.conversaciones;
    final mensajes = _chatController.mensajes;
    final isLoading = _chatController.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nuevo Chat',
            onPressed: _nuevoChat,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Borrar Historial',
            onPressed: conversaciones.isEmpty ? null : _borrarHistorial,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil de Usuario',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilVista()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (conversaciones.isNotEmpty)
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: conversaciones.length,
                itemBuilder: (context, index) {
                  final conversacion = conversaciones[index];
                  final seleccionada = conversacion.id == _chatController.conversacionSeleccionada?.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: GestureDetector(
                      onTap: () async {
                        await _chatController.seleccionarConversacion(conversacion.id);
                        await _chatController.cargarMensajes(conversacion.id);
                        setState(() {});
                      },
                      child: Chip(
                        label: Text(
                          conversacion.titulo,
                          style: TextStyle(
                            color: seleccionada ? Colors.white : null,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: seleccionada ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: mensajes.isEmpty && !isLoading
                ? const Center(
                    child: Text(
                      'Iniciá una conversación\nsobre lo que estás buscando',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: mensajes.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isLoading && index == mensajes.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Procesando...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      final mensaje = mensajes[index];
                      final esUsuario = mensaje.autor == 'user';
                      return Align(
                        alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: esUsuario ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: esUsuario ? const Radius.circular(16) : Radius.zero,
                              bottomRight: esUsuario ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            mensaje.mensaje,
                            style: TextStyle(
                              color: esUsuario ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: isLoading ? null : (_) => _enviarMensaje(),
                    decoration: InputDecoration(
                      hintText: 'Escribí tu mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isLoading ? Colors.grey : Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: isLoading ? null : _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
