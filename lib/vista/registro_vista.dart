import 'package:flutter/material.dart';

import '../controlador/registro_controller.dart';
import '../tema/app_text_styles.dart';
import '../tema/app_widgets.dart';
import 'chat_vista.dart';

class RegistroVista extends StatefulWidget {
  const RegistroVista({super.key});

  @override
  State<RegistroVista> createState() => _RegistroVistaState();
}

class _RegistroVistaState extends State<RegistroVista> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final RegistroController _registroController = RegistroController.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _isLoading = true);
    final resultado = await _registroController.registrar(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      dni: _dniController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmarPassword: _confirmController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado.ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatVista()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resultado.mensaje ?? 'No se pudo crear la cuenta. Revisá los datos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: TechBackground(
        child: TechCentered(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GradientText(
                'Completá tus datos',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creá tu cuenta para comenzar a usar el asistente.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TechCard(
                child: Column(
                  children: [
                    TechTextField(
                      controller: _nombreController,
                      icon: Icons.person_outline_rounded,
                      labelText: 'Nombre',
                      hintText: 'Tu nombre',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TechTextField(
                      controller: _apellidoController,
                      icon: Icons.badge_outlined,
                      labelText: 'Apellido',
                      hintText: 'Tu apellido',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TechTextField(
                      controller: _dniController,
                      icon: Icons.credit_card_outlined,
                      labelText: 'DNI',
                      hintText: 'Documento',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TechTextField(
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      labelText: 'Email',
                      hintText: 'tucorreo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TechTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                      labelText: 'Contraseña',
                      hintText: 'Mínimo 6 caracteres',
                      obscureText: true,
                      allowObscureToggle: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TechTextField(
                      controller: _confirmController,
                      icon: Icons.verified_user_outlined,
                      labelText: 'Confirmar contraseña',
                      hintText: 'Repetí la contraseña',
                      obscureText: true,
                      allowObscureToggle: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _registrar(),
                    ),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Crear cuenta',
                      icon: Icons.person_add_alt_1_rounded,
                      loading: _isLoading,
                      onPressed: _registrar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}