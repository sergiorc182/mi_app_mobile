import 'package:flutter/material.dart';

import '../controlador/perfil_controller.dart';
import '../modelo/usuario.dart';
import 'login_vista.dart';

class PerfilVista extends StatefulWidget {
  const PerfilVista({super.key});

  @override
  State<PerfilVista> createState() => _PerfilVistaState();
}

class _PerfilVistaState extends State<PerfilVista> {
  final PerfilController _perfilController = PerfilController.instance;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();
  Usuario? _usuario;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    final usuario = await _perfilController.cargarPerfil();
    if (!mounted) return;
    setState(() {
      _usuario = usuario;
      _nombreController.text = usuario?.nombre ?? '';
      _apellidoController.text = usuario?.apellido ?? '';
      _fotoController.text = usuario?.fotoPerfil ?? '';
    });
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);
    final actualizado = await _perfilController.actualizarPerfil(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      fotoPerfil: _fotoController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    setState(() => _usuario = actualizado);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado.')),
    );
  }

  Future<void> _cerrarSesion() async {
    await _perfilController.cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginVista()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            if (_usuario != null) ...[
              Text('Email: ${_usuario!.email}', style: const TextStyle(fontSize: 16)),
              Text('UID: ${_usuario!.id}', style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 16),
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _apellidoController, decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _fotoController, decoration: const InputDecoration(labelText: 'Foto', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _guardar, child: const Text('Guardar cambios')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cerrarSesion,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
