import 'package:flutter/material.dart';

// 👇 para ir al login si no está registrado
import 'login.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ChatScreen({super.key, this.userData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> mensajes = [
    {"bot": "👋 Hola, ¿Qué estás buscando?"}
  ];

  void enviarOpcion(String texto) {
    setState(() {
      mensajes.add({"user": texto});

      // lógica simple inicial
      if (texto.toLowerCase().contains("aire")) {
        mensajes.add({"bot": "¿Cuántas frigorías necesitás?"});
      } else if (texto.toLowerCase().contains("tv")) {
        mensajes.add({"bot": "¿De cuántas pulgadas?"});
      } else if (texto.toLowerCase().contains("heladera")) {
        mensajes.add({"bot": "¿Con freezer o sin freezer?"});
      } else {
        mensajes.add({"bot": "Contame más sobre lo que buscás"});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistente de compra"),
      ),

      // 👉 PANEL DERECHO
      endDrawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              child: Text("Mi Cuenta", style: TextStyle(fontSize: 20)),
            ),

            if (widget.userData != null) ...[
              ListTile(
                title: Text("DNI: ${widget.userData!["dni"]}"),
              ),
              ListTile(
                title: const Text("Cerrar sesión"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ] else ...[
              ListTile(
                title: const Text("No estás registrado"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("Registrarse"),
              ),
            ]
          ],
        ),
      ),

      body: Row(
        children: [
          // 💬 CHAT
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = mensajes[index];

                      final esBot = mensaje.containsKey("bot");

                      return Align(
                        alignment: esBot
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esBot
                                ? Colors.grey[300]
                                : Colors.blue[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            mensaje.values.first,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 👇 OPCIONES RÁPIDAS
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () => enviarOpcion("Aire acondicionado"),
                        child: const Text("Aire"),
                      ),
                      ElevatedButton(
                        onPressed: () => enviarOpcion("Heladera"),
                        child: const Text("Heladera"),
                      ),
                      ElevatedButton(
                        onPressed: () => enviarOpcion("TV"),
                        child: const Text("TV"),
                      ),
                    ],
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