import 'package:flutter/material.dart';

import '../controlador/firebase_controller.dart';
import '../controlador/login_controller.dart';
import '../modelo/firebase/firebase.dart';
import 'chat_vista.dart';
import 'login_vista.dart';

class SplashVista extends StatefulWidget {
  const SplashVista({super.key});

  @override
  State<SplashVista> createState() => _SplashVistaState();
}

class _SplashVistaState extends State<SplashVista> {
  String _estado = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _iniciarAplicacion();
  }

  Future<void> _iniciarAplicacion() async {
    setState(() => _estado = 'Conectando a Firebase...');

    final controller = FirebaseController();
    final status = await controller.inicializar();

    if (!mounted) return;

    if (status == FirebaseStatus.connected) {
      setState(() => _estado = 'Verificando sesión...');
      final loginController = LoginController.instance;
      final usuario = await loginController.cargarUsuarioActual();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => usuario != null ? const ChatVista() : const LoginVista(),
        ),
      );
      return;
    }

    setState(() => _estado = 'No se pudo conectar a Firebase.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _estado,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
