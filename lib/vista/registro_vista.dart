import 'package:flutter/material.dart';

import '../controlador/registro_controller.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text('Completá tus datos', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _apellidoController, decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _dniController, decoration: const InputDecoration(labelText: 'DNI', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar contraseña', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _registrar, child: const Text('Crear cuenta')),
          ],
        ),
      ),
    );
  }
}
