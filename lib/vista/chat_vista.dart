import 'package:flutter/material.dart';
import '../controlador/chat_controller.dart';
import '../controlador/login_controller.dart';
import 'login_vista.dart';

class ChatVista extends StatefulWidget {
  const ChatVista({super.key});

  @override
  State<ChatVista> createState() => _ChatVistaState();
}

class _ChatVistaState extends State<ChatVista> {
  late final ChatController _chatController;
  final LoginController _loginController = LoginController.instance;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    _chatController.onChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _chatController.onChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _loginController.usuarioActual;

    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de compra')),
      endDrawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              child: Text('Mi Cuenta', style: TextStyle(fontSize: 20)),
            ),
            if (_loginController.estaLogueado() && usuario != null) ...[
              ListTile(title: Text('DNI: ${usuario.dni}')),
              ListTile(
                title: const Text('Cerrar sesión'),
                onTap: () {
                  _loginController.cerrarSesion();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginVista()),
                  );
                },
              ),
            ] else ...[
              const ListTile(title: Text('No estás registrado')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginVista()),
                    );
                  },
                  child: const Text('Registrarse'),
                ),
              ),
            ]
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _chatController.mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = _chatController.mensajes[index];
                final esBot = mensaje.containsKey('bot');
                return Align(
                  alignment:
                      esBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esBot ? Colors.grey[300] : Colors.blue[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(mensaje.values.first),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      _chatController.enviarMensaje('Aire acondicionado'),
                  child: const Text('Aire'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _chatController.enviarMensaje('Heladera'),
                  child: const Text('Heladera'),
                ),
                ElevatedButton(
                  onPressed: () => _chatController.enviarMensaje('TV'),
                  child: const Text('TV'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
