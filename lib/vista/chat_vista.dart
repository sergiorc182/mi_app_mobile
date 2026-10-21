import 'package:flutter/material.dart';

import '../controlador/chat_controller.dart';
import '../controlador/perfil_controller.dart';
import '../tema/app_colors.dart';
import '../tema/app_gradients.dart';
import '../tema/app_text_styles.dart';
import '../tema/app_widgets.dart';
import 'login_vista.dart';
import 'perfil_vista.dart';

class ChatVista extends StatefulWidget {
  const ChatVista({super.key});

  @override
  State<ChatVista> createState() => _ChatVistaState();
}

class _ChatVistaState extends State<ChatVista> {
  final ChatController _chatController = ChatController();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _drawerAbierto = false;
  List<String> _categorias = <String>[];
  static const List<Color> _acentosCategorias = [
    AppColors.cyan,
    AppColors.violet,
    AppColors.blue,
    AppColors.pink,
    AppColors.orange,
    AppColors.green,
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    List<String> categorias = <String>[];
    try {
      categorias = await _chatController.cargarCategorias();
    } catch (_) {
      categorias = <String>[];
    }

    await _chatController.cargarConversaciones();
    if (_chatController.conversacionSeleccionada != null) {
      await _chatController.cargarMensajes(
        _chatController.conversacionSeleccionada!.id,
      );
    }
    if (mounted) {
      setState(() => _categorias = categorias);
    }
  }

  Future<void> _enviarTexto(String texto) async {
    final contenido = texto.trim();
    if (contenido.isEmpty) return;

    _mensajeController.clear();
    FocusScope.of(context).unfocus();
    await _chatController.enviarMensaje(contenido);
    final errorMensaje = _chatController.errorMensaje;
    _chatController.errorMensaje = null;
    if (!mounted) return;
    setState(() {});
    if (errorMensaje != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMensaje),
          backgroundColor: const Color(0xFF2A1520),
        ),
      );
    }
    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _nuevoChat() async {
    await _chatController.crearNuevaConversacion();
    if (!mounted) return;
    setState(() {});
    _mensajeController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _borrarHistorial() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Borrar historial',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Estás seguro de eliminar todas las conversaciones?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _chatController.eliminarHistorial();
    if (mounted) setState(() {});
  }

  Future<void> _cerrarSesion() async {
    await PerfilController.instance.cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginVista()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mensajes = _chatController.mensajes;
    final isLoading = _chatController.isLoading;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      onDrawerChanged: (abierto) => setState(() => _drawerAbierto = abierto),
      body: TechBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: mensajes.isEmpty && !isLoading
                    ? _buildHero(context)
                    : _buildMensajes(mensajes, isLoading),
              ),
              _buildInputBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.70),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _botonMenu(context),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'VendedorVirtual',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'En línea',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonMenu(BuildContext context) {
    return Tooltip(
      message: _drawerAbierto ? 'Cerrar menú' : 'Abrir menú',
      child: GestureDetector(
        onTap: () {
          final scaffold = _scaffoldKey.currentState;
          if (scaffold == null) return;
          if (scaffold.isDrawerOpen) {
            scaffold.closeDrawer();
          } else {
            scaffold.openDrawer();
          }
        },
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedRotation(
            turns: _drawerAbierto ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VendedorVirtual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Asistente de compras',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.add_comment_outlined,
              label: 'Nuevo chat',
              onTap: () {
                Navigator.pop(context);
                _nuevoChat();
              },
            ),
            _drawerItem(
              icon: Icons.badge_outlined,
              label: 'Mis datos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilVista()),
                );
              },
            ),
            _drawerItem(
              icon: Icons.delete_sweep_outlined,
              label: 'Borrar historial',
              enabled: _chatController.conversaciones.isNotEmpty,
              onTap: () {
                Navigator.pop(context);
                _borrarHistorial();
              },
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CONVERSACIONES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildConversaciones()),
            const Divider(color: AppColors.border, height: 1),
            _drawerItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    Color? color,
  }) {
    final colorFinal = enabled
        ? (color ?? AppColors.textPrimary)
        : AppColors.textMuted;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: colorFinal, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: colorFinal,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildConversaciones() {
    final conversaciones = _chatController.conversaciones;
    if (conversaciones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'Todavía no tenés conversaciones.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        itemCount: conversaciones.length,
        itemBuilder: (context, index) {
          final conversacion = conversaciones[index];
          final seleccionada =
              conversacion.id == _chatController.conversacionSeleccionada?.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: GestureDetector(
              onTap: () async {
                await _chatController.seleccionarConversacion(conversacion.id);
                await _chatController.cargarMensajes(conversacion.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (mounted) setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: seleccionada ? AppGradients.primary : null,
                  color: seleccionada ? null : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: seleccionada ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color:
                          seleccionada ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        conversacion.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: seleccionada
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 18),
                  child: child,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    _buildRobotGlow(),
                    const SizedBox(height: 26),
                    const GradientText(
                      '¿Qué estás buscando hoy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Elegí una categoría abajo o escribí directamente.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'CATEGORÍAS',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      child: _categorias.isEmpty
                          ? const Padding(
                              key: ValueKey('categorias-loading'),
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.violetSoft,
                                ),
                              ),
                            )
                          : Wrap(
                              key: const ValueKey('categorias-lista'),
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: _categorias.asMap().entries.map((entry) {
                                final categoria = entry.value;
                                final accent = _acentosCategorias[
                                    entry.key % _acentosCategorias.length];
                                return EntryFade(
                                  delay: Duration(milliseconds: 60 * entry.key),
                                  offset: 12,
                                  child: CategoryChip(
                                    label: categoria,
                                    accent: accent,
                                    onTap: () => _enviarTexto(categoria),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRobotGlow() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withValues(alpha: 0.28),
            AppColors.blue.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.32),
            blurRadius: 60,
            spreadRadius: -8,
          ),
        ],
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Color(0xFFB9A6FF),
        size: 52,
      ),
    );
  }

  Widget _buildMensajes(List mensajes, bool isLoading) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: mensajes.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoading && index == mensajes.length) {
          return const _TypingIndicator();
        }

        final mensaje = mensajes[index];
        final esUsuario = mensaje.autor == 'user';
        final texto = mensaje.mensaje;

        return _MensajeBurbuja(
          key: ValueKey(mensaje.id),
          esUsuario: esUsuario,
          texto: texto,
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final isLoading = _chatController.isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.6),
        ),
      ),
      child: TechTextField(
        controller: _mensajeController,
        icon: Icons.search_rounded,
        hintText: 'Buscar productos o escribí tu consulta...',
        textInputAction: TextInputAction.send,
        onSubmitted: isLoading ? null : (value) => _enviarTexto(value),
        trailing: _buildEnviarBoton(context, isLoading),
      ),
    );
  }

  Widget _buildEnviarBoton(BuildContext context, bool isLoading) {
    final enabled = !isLoading;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: enabled ? () => _enviarTexto(_mensajeController.text) : null,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: enabled ? AppGradients.primary : null,
            color: enabled ? null : AppColors.surfaceAlt,
            shape: BoxShape.circle,
            border: enabled ? null : Border.all(color: AppColors.border),
          ),
          child: Icon(
            Icons.arrow_upward_rounded,
            color: enabled ? Colors.white : AppColors.textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MensajeBurbuja extends StatelessWidget {
  const _MensajeBurbuja({
    super.key,
    required this.esUsuario,
    required this.texto,
  });

  final bool esUsuario;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(esUsuario ? (1 - value) * 16 : (value - 1) * 16, 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            gradient: esUsuario ? AppGradients.primary : null,
            color: esUsuario ? null : AppColors.surfaceAlt,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(esUsuario ? 18 : 5),
              bottomRight: Radius.circular(esUsuario ? 5 : 18),
            ),
            border: esUsuario
                ? null
                : Border.all(color: AppColors.border),
            boxShadow: esUsuario
                ? [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            texto,
            style: TextStyle(
              color: esUsuario ? Colors.white : AppColors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.violetSoft,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Procesando...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
