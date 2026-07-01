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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);
    _mensajeController.clear();
    await _chatController.enviarMensaje(texto);
    if (mounted) setState(() => _isLoading = false);
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversaciones = _chatController.conversaciones;
    final mensajes = _chatController.mensajes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilVista()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: conversaciones.length,
              itemBuilder: (context, index) {
                final conversacion = conversaciones[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () async {
                      await _chatController.seleccionarConversacion(conversacion.id);
                      await _chatController.cargarMensajes(conversacion.id);
                      setState(() {});
                    },
                    child: Chip(label: Text(conversacion.titulo)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = mensajes[index];
                final esUsuario = mensaje.autor == 'user';
                return Align(
                  alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esUsuario ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(mensaje.mensaje),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribí tu mensaje',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _isLoading ? null : _enviarMensaje, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'newConversation',
            onPressed: () async {
              await _chatController.crearNuevaConversacion();
              await _chatController.cargarMensajes(_chatController.conversacionSeleccionada!.id);
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'deleteConversation',
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              final conversacion = _chatController.conversacionSeleccionada;
              if (conversacion == null) return;
              await _chatController.eliminarConversacion(conversacion.id);
              setState(() {});
            },
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}
