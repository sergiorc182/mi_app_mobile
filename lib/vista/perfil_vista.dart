import 'package:flutter/material.dart';

import '../controlador/perfil_controller.dart';
import '../modelo/usuario.dart';
import '../tema/app_colors.dart';
import '../tema/app_gradients.dart';
import '../tema/app_text_styles.dart';
import '../tema/app_widgets.dart';
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

  String get _iniciales {
    final usuario = _usuario;
    if (usuario == null) return '?';
    final letras = (usuario.nombre.isNotEmpty ? usuario.nombre[0] : '') +
        (usuario.apellido.isNotEmpty ? usuario.apellido[0] : '');
    return letras.isEmpty ? '?' : letras.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: TechBackground(
        child: TechCentered(
          maxWidth: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EntryFade(
                scaleFrom: 0.9,
                offset: 0,
                child: _buildAvatar(),
              ),
              const SizedBox(height: 14),
              const EntryFade(
                delay: Duration(milliseconds: 120),
                child: GradientText(
                  'Tu perfil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              EntryFade(
                delay: const Duration(milliseconds: 200),
                offset: 28,
                child: TechCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_usuario != null) ...[
                      _buildDato(
                        icon: Icons.mail_outline_rounded,
                        etiqueta: 'Email',
                        valor: _usuario!.email,
                      ),
                      const SizedBox(height: 10),
                      _buildDato(
                        icon: Icons.credit_card_outlined,
                        etiqueta: 'DNI',
                        valor: _usuario!.dni,
                      ),
                      const SizedBox(height: 22),
                    ],
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
                      controller: _fotoController,
                      icon: Icons.image_outlined,
                      labelText: 'Foto (URL)',
                      hintText: 'https://...',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Guardar cambios',
                      icon: Icons.check_rounded,
                      loading: _isLoading,
                      onPressed: _guardar,
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      label: 'Cerrar sesión',
                      icon: Icons.logout_rounded,
                      gradient: AppGradients.danger,
                      onPressed: _cerrarSesion,
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

  Widget _buildAvatar() {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primaryDiagonal,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        alignment: Alignment.center,
        child: GradientText(
          _iniciales,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDato({
    required IconData icon,
    required String etiqueta,
    required String valor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: AppTextStyles.captionMuted),
              const SizedBox(height: 2),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}