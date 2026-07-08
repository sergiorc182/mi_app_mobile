import 'package:flutter/material.dart';

import '../modelo/firebase/auth.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Ingresá tu email para recibir instrucciones', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _recuperar, child: const Text('Enviar')),
          ],
        ),
      ),
    );
  }
}
