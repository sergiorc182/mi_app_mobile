import 'package:flutter/material.dart';

import '../modelo/firebase/auth.dart';
import '../tema/app_colors.dart';
import '../tema/app_text_styles.dart';
import '../tema/app_widgets.dart';

class RecuperarPasswordVista extends StatefulWidget {
  const RecuperarPasswordVista({super.key});

  @override
  State<RecuperarPasswordVista> createState() => _RecuperarPasswordVistaState();
}

class _RecuperarPasswordVistaState extends State<RecuperarPasswordVista> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _recuperar() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    await _authService.sendPasswordResetEmail(email);
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Se envió un correo para recuperar la contraseña.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: TechBackground(
        child: TechCentered(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EntryFade(
                scaleFrom: 0.9,
                offset: 0,
                child: AppLogo(size: 64, icon: Icons.lock_reset_rounded),
              ),
              const SizedBox(height: 18),
              const EntryFade(
                delay: Duration(milliseconds: 120),
                child: GradientText(
                  'Restablecé tu acceso',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const EntryFade(
                delay: Duration(milliseconds: 200),
                child: Text(
                  'Ingresá tu email y te enviaremos las instrucciones.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              EntryFade(
                delay: const Duration(milliseconds: 280),
                offset: 28,
                child: TechCard(
                child: Column(
                  children: [
                    TechTextField(
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      labelText: 'Email',
                      hintText: 'tucorreo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _recuperar(),
                    ),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Enviar instrucciones',
                      icon: Icons.send_rounded,
                      loading: _isLoading,
                      onPressed: _recuperar,
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: AppColors.green,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'El enlace es de un solo uso y seguro',
                          style: AppTextStyles.captionMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}