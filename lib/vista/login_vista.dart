import 'package:flutter/material.dart';

import '../controlador/login_controller.dart';
import '../tema/app_colors.dart';
import '../tema/app_text_styles.dart';
import '../tema/app_widgets.dart';
import 'chat_vista.dart';
import 'recuperar_password_vista.dart';
import 'registro_vista.dart';

class LoginVista extends StatefulWidget {
  const LoginVista({super.key});

  @override
  State<LoginVista> createState() => _LoginVistaState();
}

class _LoginVistaState extends State<LoginVista> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginController _loginController = LoginController.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    setState(() => _isLoading = true);
    final usuario = await _loginController.iniciarSesionConEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (usuario != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatVista()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo iniciar sesión. Revisá tus credenciales.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: TechBackground(
        child: TechCentered(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EntryFade(
                scaleFrom: 0.9,
                offset: 0,
                duration: Duration(milliseconds: 520),
                child: AppLogo(size: 72),
              ),
              const SizedBox(height: 16),
              const EntryFade(
                delay: Duration(milliseconds: 120),
                child: GradientText(
                  'VendedorVirtual',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              EntryFade(
                delay: const Duration(milliseconds: 220),
                offset: 28,
                child: TechCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      'Bienvenido de vuelta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu asistente inteligente de compras te espera. '
                      'Ingresá tus datos para continuar.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 26),
                    TechTextField(
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      labelText: 'Email',
                      hintText: 'tucorreo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TechTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                      labelText: 'Contraseña',
                      hintText: '••••••••',
                      obscureText: true,
                      allowObscureToggle: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _ingresar(),
                    ),
                    const SizedBox(height: 26),
                    GradientButton(
                      label: 'Ingresar',
                      icon: Icons.arrow_forward_rounded,
                      loading: _isLoading,
                      onPressed: _ingresar,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: AppTextStyles.captionMuted,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const RegistroVista()),
                                    ),
                            child: const Text('Crear cuenta'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RecuperarPasswordVista(),
                                      ),
                                    ),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: AppColors.green,
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Tus datos se guardan de forma segura',
                            style: AppTextStyles.captionMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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