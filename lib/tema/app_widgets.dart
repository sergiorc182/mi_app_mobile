import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_text_styles.dart';

/// Animación de entrada suave: fade + desplazamiento vertical.
///
/// Pensada para animar elementos al montarse una pantalla. Con [delay] se
/// logra un efecto escalonado (stagger) cuando se anidan varios.
class EntryFade extends StatefulWidget {
  const EntryFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offset = 20,
    this.scaleFrom = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Desplazamiento vertical inicial (px) que se resuelve al aparecer.
  final double offset;

  /// Escala inicial. 1 = sin zoom; valores < 1 dan un leve zoom-in.
  final double scaleFrom;

  @override
  State<EntryFade> createState() => _EntryFadeState();
}

class _EntryFadeState extends State<EntryFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _total = widget.delay + widget.duration;
    _begin = _total.inMilliseconds == 0
        ? 0.0
        : widget.delay.inMilliseconds / _total.inMilliseconds;
    _controller = AnimationController(vsync: this, duration: _total)
      ..forward();
  }

  late final Duration _total;
  late final double _begin;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(_begin, 1, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final value = curve.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * widget.offset),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Apila varios hijos animándolos en cascada vertical.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.step = const Duration(milliseconds: 90),
    this.start = const Duration(milliseconds: 80),
    this.itemDuration = const Duration(milliseconds: 460),
    this.offset = 22,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration step;
  final Duration start;
  final Duration itemDuration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          EntryFade(
            delay: start + step * i,
            duration: itemDuration,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}

/// Fondo tecnológico: gradientes radiales sutiles, glow difusos y una
/// cuadrícula tenue. Pintado con [CustomPainter] para no impactar el
/// rendimiento.
class TechBackground extends StatelessWidget {
  const TechBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _TechPainter()),
          child,
        ],
      ),
    );
  }
}

class _TechPainter extends CustomPainter {
  const _TechPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF090E1C), Color(0xFF05070E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    _drawGlow(
      canvas,
      size,
      Offset(size.width * 0.10, size.height * 0.08),
      size.width * 0.60,
      const Color(0xFF6C3BFF),
      alpha: 0.16,
    );
    _drawGlow(
      canvas,
      size,
      Offset(size.width * 0.95, size.height * 0.90),
      size.width * 0.55,
      const Color(0xFF1E6BFF),
      alpha: 0.13,
    );
    _drawGlow(
      canvas,
      size,
      Offset(size.width * 0.85, size.height * 0.12),
      size.width * 0.40,
      const Color(0xFF38E1D4),
      alpha: 0.05,
    );

    final gridColor = const Color(0xFF8FA8E0).withValues(alpha: 0.035);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const double spacing = 56;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dotPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.08);
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _drawGlow(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color, {
    double alpha = 0.12,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _TechPainter oldDelegate) => false;
}

/// Contenedor centrado con scroll, pensado para pantallas de formularios.
class TechCentered extends StatelessWidget {
  const TechCentered({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = 420,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card oscura con borde sutil y glow discreto.
class TechCard extends StatelessWidget {
  const TechCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 48,
            offset: Offset(0, 20),
          ),
          BoxShadow(
            color: Color(0x128257F5),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Logo de aplicación: cuadrado con gradiente violeta/azul.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.icon = Icons.smart_toy_outlined,
  });

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryDiagonal,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: size * 0.5,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Texto con gradiente aplicado al glyph.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppGradients.primary,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: (style ?? AppTextStyles.heroTitle).copyWith(color: Colors.white),
        textAlign: textAlign,
      ),
    );
  }
}

/// Botón principal: gradiente violeta → azul, radius alto y glow sutil.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.gradient = AppGradients.primary,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, color: Colors.white, size: 20),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            loading ? 'Procesando...' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.buttonLabel,
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.5,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: expanded ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: enabled ? 0.28 : 0.10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de texto oscuro con focus glow violeta y estado visual claro.
class TechTextField extends StatefulWidget {
  const TechTextField({
    super.key,
    required this.controller,
    this.icon,
    this.trailing,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.allowObscureToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData? icon;
  final Widget? trailing;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final bool allowObscureToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<TechTextField> createState() => _TechTextFieldState();
}

class _TechTextFieldState extends State<TechTextField> {
  late final FocusNode _focusNode;
  late bool _obscure;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = _focused ? AppColors.violetSoft : AppColors.textSecondary;

    final trailing = widget.trailing ??
        (widget.allowObscureToggle
            ? Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(widget.labelText!),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused
                  ? AppColors.violet.withValues(alpha: 0.85)
                  : AppColors.border,
              width: _focused ? 1.4 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.18),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                const SizedBox(width: 16),
                Icon(
                  widget.icon,
                  size: 20,
                  color: _focused ? AppColors.violetSoft : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: _obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  style: AppTextStyles.inputText,
                  cursorColor: AppColors.violet,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.inputHint,
                  ),
                ),
              ),
              ?trailing,
              if (trailing == null) const SizedBox(width: 14),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip/pill de categoría con color de acento propio.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.accent,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.32),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x2E000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: selected ? Colors.white : accent,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFFCAD4E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Píldora informativa pequeña (ej: DNI del usuario).
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.text,
    this.icon,
    this.accent = AppColors.textSecondary,
  });

  final String text;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}