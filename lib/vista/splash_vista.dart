import 'package:flutter/material.dart';

import '../controlador/firebase_controller.dart';
import '../controlador/login_controller.dart';
import '../modelo/firebase/firebase.dart';
import '../tema/app_colors.dart';
import '../tema/app_text_styles.dart';
import '../tema/app_widgets.dart';
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
      body: TechBackground(
        child: TechCentered(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 88),
              const SizedBox(height: 24),
              const GradientText(
                'VendedorVirtual',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Asistente de compras inteligente',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.violetSoft,
                ),
              ),
              const SizedBox(height: 16),
              Text(_estado, style: AppTextStyles.captionMuted),
            ],
          ),
        ),
      ),
    );
  }
}