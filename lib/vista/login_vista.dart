import 'package:flutter/material.dart';
import '../controlador/login_controller.dart';
import 'chat_vista.dart';

class LoginVista extends StatefulWidget {
  const LoginVista({super.key});

  @override
  State<LoginVista> createState() => _LoginVistaState();
}

class _LoginVistaState extends State<LoginVista> {
  final TextEditingController _dniController = TextEditingController();
  final LoginController _loginController = LoginController.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    setState(() => _isLoading = true);
    final usuario = await _loginController.iniciarSesionConDni(_dniController.text);
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
      const SnackBar(
        content: Text('No se pudo iniciar sesión. Ingresá un DNI válido.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login DNI')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Ingresá tu DNI'),
            const SizedBox(height: 20),
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'DNI',
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _ingresar,
                    child: const Text('Ingresar'),
                  ),
          ],
        ),
      ),
    );
  }
}
