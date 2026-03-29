import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' show ImageFilter;
import 'dart:io' show File;

import 'theme.dart';
import 'system_visuals_extension.dart';

class LockedFeatureScreen extends StatelessWidget {
  const LockedFeatureScreen({super.key, required this.title, required this.requiredLevel});

  final String title;
  final int requiredLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  title,
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ProfileNeonCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Раздел заблокирован',
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ваш сосуд недостаточно окреп.\n\nТребуется Уровень $requiredLevel.',
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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

/// Фон: сетка + мягкое свечение (профиль, настройки и др.).
class ProfileBackdrop extends StatefulWidget {
  const ProfileBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<ProfileBackdrop> createState() => _ProfileBackdropState();
}

class _ProfileBackdropState extends State<ProfileBackdrop> {
  double _parallax = 0.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<SystemVisuals>() ??
        const SystemVisuals(
          backgroundKind: SystemBackgroundKind.grid,
          backgroundAssetPath: '',
          particlesKind: SystemParticlesKind.none,
          panelRadius: 12,
          panelBorderWidth: 1,
          panelBlur: 0,
          titleLetterSpacing: 2.2,
          surfaceKind: SystemSurfaceKind.digital,
          glowIntensity: 0.35,
          borderRadiusScale: 1.0,
          shadowProfile: SystemShadowProfile.soft,
          lowFxMode: false,
        );

    final backgroundKey =
        '${visuals.backgroundKind.name}|${visuals.backgroundAssetPath}|${scheme.primary.toARGB32()}|${scheme.secondary.toARGB32()}';

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Лёгкий параллакс: фон “отстаёт” от скролла.
        final pixels = n.metrics.pixels;
        final next = (pixels / 2200.0).clamp(-1.0, 1.0);
        if ((next - _parallax).abs() > 0.003) {
          setState(() => _parallax = next);
        }
        return false;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),

          // Фон: процедурный слой + (опционально) арт.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Stack(
                key: ValueKey(backgroundKey),
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: switch (visuals.backgroundKind) {
                      SystemBackgroundKind.grid => _PromoGridPainter(
                          lineColor: scheme.primary.withValues(alpha: 0.055),
                        ),
                      SystemBackgroundKind.parchment => _ParchmentPainter(
                          tint: scheme.secondary.withValues(alpha: 0.10),
                          ink: scheme.primary.withValues(alpha: 0.055),
                        ),
                      SystemBackgroundKind.mist => _MistPainter(
                          glowA: scheme.primary.withValues(alpha: 0.10),
                          glowB: scheme.secondary.withValues(alpha: 0.08),
                        ),
                    },
                  ),
                  if (visuals.backgroundAssetPath.trim().isNotEmpty)
                    Transform.translate(
                      offset: Offset(
                        0,
                        visuals.lowFxMode ? 0 : -_parallax * 22,
                      ),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.42,
                          child: visuals.lowFxMode
                              ? ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    scheme.primary.withValues(alpha: 0.92),
                                    BlendMode.srcIn,
                                  ),
                                  child: _BackgroundArt(
                                    pathOrUrl: visuals.backgroundAssetPath,
                                  ),
                                )
                              : ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 2.4,
                                    sigmaY: 2.4,
                                  ),
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      scheme.primary.withValues(alpha: 0.92),
                                      BlendMode.srcIn,
                                    ),
                                    child: _BackgroundArt(
                                      pathOrUrl: visuals.backgroundAssetPath,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  // Smart overlay: читаемость всегда на месте.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.80),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),

          // Локальный “неоновый ореол” — остаётся поверх.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 1.15,
                colors: [
                  scheme.primary.withValues(alpha: 0.10),
                  scheme.secondary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),

          if (visuals.particlesKind != SystemParticlesKind.none)
            Positioned.fill(
              child: IgnorePointer(
                child: _ParticlesLayer(kind: visuals.particlesKind),
              ),
            ),

          widget.child,
        ],
      ),
    );
  }
}

class _BackgroundArt extends StatelessWidget {
  const _BackgroundArt({required this.pathOrUrl});
  final String pathOrUrl;

  @override
  Widget build(BuildContext context) {
    final path = pathOrUrl.trim();
    if (path.isEmpty) return const SizedBox.shrink();

    final lower = path.toLowerCase();
    final isHttp = lower.startsWith('http://') || lower.startsWith('https://');
    final isFile = lower.startsWith('file://') || File(path).existsSync();

    if (lower.endsWith('.svg')) {
      if (isHttp) {
        return SvgPicture.network(
          path,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          placeholderBuilder: (_) => const SizedBox.shrink(),
        );
      }
      return SvgPicture.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }

    if (isHttp) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, _, __) => const SizedBox.shrink(),
      );
    }
    if (isFile && !lower.startsWith('assets/')) {
      final realPath = lower.startsWith('file://') ? path.substring(7) : path;
      return Image.file(
        File(realPath),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, _, __) => const SizedBox.shrink(),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, _, __) => const SizedBox.shrink(),
    );
  }
}

class _PromoGridPainter extends CustomPainter {
  const _PromoGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 36.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter({required this.tint, required this.ink});

  final Color tint;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = tint;
    canvas.drawRect(Offset.zero & size, bg);

    // “Волокна пергамента” — мягкие диагональные штрихи.
    final p = Paint()
      ..color = ink
      ..strokeWidth = 1;
    const step = 28.0;
    for (var i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        p,
      );
    }

    // Лёгкая виньетка.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          ink.withValues(alpha: 0.06),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MistPainter extends CustomPainter {
  const _MistPainter({required this.glowA, required this.glowB});

  final Color glowA;
  final Color glowB;

  @override
  void paint(Canvas canvas, Size size) {
    // Небольшие “туманные” пятна.
    final paintA = Paint()..color = glowA;
    final paintB = Paint()..color = glowB;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.25),
        size.shortestSide * 0.35, paintA);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35),
        size.shortestSide * 0.28, paintB);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.78),
        size.shortestSide * 0.40, paintA..color = glowA.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticlesLayer extends StatefulWidget {
  const _ParticlesLayer({required this.kind});
  final SystemParticlesKind kind;

  @override
  State<_ParticlesLayer> createState() => _ParticlesLayerState();
}

class _ParticlesLayerState extends State<_ParticlesLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlesPainter(
            t: _c.value,
            kind: widget.kind,
            a: scheme.primary.withValues(alpha: 0.10),
            b: scheme.secondary.withValues(alpha: 0.08),
          ),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  const _ParticlesPainter({
    required this.t,
    required this.kind,
    required this.a,
    required this.b,
  });

  final double t;
  final SystemParticlesKind kind;
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    // Детерминированные “частицы” без Random: всё считается через sin/cos.
    final n = switch (kind) {
      SystemParticlesKind.sparkles => 18,
      SystemParticlesKind.runes => 14,
      SystemParticlesKind.petals => 16,
      SystemParticlesKind.none => 0,
    };
    if (n <= 0) return;

    for (var i = 0; i < n; i++) {
      final fi = i.toDouble();
      final phase = (t + fi * 0.07) % 1.0;

      final x = (0.5 + 0.45 * _sin(fi * 1.7 + phase * 6.28)) * size.width;
      final y = (0.5 + 0.45 * _cos(fi * 1.3 + phase * 6.28)) * size.height;

      final baseR = switch (kind) {
        SystemParticlesKind.sparkles => 1.6,
        SystemParticlesKind.runes => 1.2,
        SystemParticlesKind.petals => 2.2,
        SystemParticlesKind.none => 0.0,
      };
      final r = baseR + (1.0 + _sin(fi + phase * 6.28)) * 0.8;
      final color = (i % 2 == 0 ? a : b).withValues(
        alpha: (0.18 + 0.10 * _sin(phase * 6.28 + fi)).clamp(0.06, 0.28),
      );
      final p = Paint()..color = color;

      switch (kind) {
        case SystemParticlesKind.sparkles:
          canvas.drawCircle(Offset(x, y), r, p);
          break;
        case SystemParticlesKind.runes:
          // Маленькие “рунические” штрихи.
          p.strokeWidth = 1;
          canvas.drawLine(
            Offset(x - r, y - r),
            Offset(x + r, y + r),
            p,
          );
          canvas.drawLine(
            Offset(x - r, y + r),
            Offset(x + r, y - r),
            p,
          );
          break;
        case SystemParticlesKind.petals:
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: r * 2.2, height: r * 1.4),
            p,
          );
          break;
        case SystemParticlesKind.none:
          break;
      }
    }
  }

  double _sin(double v) => math.sin(v);
  double _cos(double v) => math.cos(v);

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.kind != kind || oldDelegate.a != a || oldDelegate.b != b;
  }
}

/// Карточка с градиентной обводкой cyan → purple.
class ProfileNeonCard extends StatelessWidget {
  const ProfileNeonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<SystemVisuals>();
    final outerR = (visuals?.panelRadius ?? 10).clamp(10.0, 24.0);
    final innerR = (outerR - 1).clamp(9.0, 23.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerR),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.9),
            scheme.secondary.withValues(alpha: 0.65),
            scheme.secondary.withValues(alpha: 0.45),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: scheme.secondary.withValues(alpha: 0.14),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(innerR),
        ),
        child: child,
      ),
    );
  }
}

/// Заголовок секции: капс, плотный трекинг.
Widget profileSectionTitle(BuildContext context, String text) {
  final visuals = Theme.of(context).extension<SystemVisuals>();
  final tracking = (visuals?.titleLetterSpacing ?? 2.2).clamp(1.0, 4.0);
  return Text(
    text.toUpperCase(),
    style: GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: tracking,
      color: SoloLevelingColors.textSecondary,
    ),
  );
}

/// Заголовок экрана / AppBar в стиле promo.
TextStyle promoAppBarTitleStyle(BuildContext context) {
  final visuals = Theme.of(context).extension<SystemVisuals>();
  final tracking = (visuals?.titleLetterSpacing ?? 0.0).clamp(0.0, 4.0);
  return GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: tracking,
    color: SoloLevelingColors.textPrimary,
  );
}

/// Текст с градиентом.
class ProfileGradientText extends StatelessWidget {
  const ProfileGradientText({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [scheme.primary, scheme.secondary],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// Горизонтальный прогресс с градиентом.
class ProfileGradientBar extends StatelessWidget {
  const ProfileGradientBar({
    super.key,
    required this.value,
    this.height = 12,
    this.radius = 8,
  });

  final double value;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surface),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.85),
                      scheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(
                        alpha: 0.45,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Плашка-бейдж.
class ProfilePillBadge extends StatelessWidget {
  const ProfilePillBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.45),
        ),
        color: scheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: scheme.primary.withValues(alpha: 0.95),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Разделитель внутри [ProfileNeonCard] (настройки, списки).
class PromoDivider extends StatelessWidget {
  const PromoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }
}

/// Строка настроек: иконка в «капсуле», Manrope, шеврон.
class PromoSettingsTile extends StatelessWidget {
  const PromoSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = iconColor ?? scheme.primary;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? SoloLevelingColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: SoloLevelingColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.65),
              size: 24,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }
    return content;
  }
}

/// Обводка полей ввода (настройки ИИ и т.п.).
InputDecoration promoInputDecoration({
  String? hintText,
  String? labelText,
  Widget? suffixIcon,
  Color borderAccent = SoloLevelingColors.neonBlue,
}) {
  return InputDecoration(
    filled: true,
    fillColor: SoloLevelingColors.surfaceLight.withValues(alpha: 0.45),
    hintText: hintText,
    labelText: labelText,
    hintStyle: GoogleFonts.manrope(
      color: SoloLevelingColors.textTertiary,
      fontSize: 14,
    ),
    labelStyle: GoogleFonts.manrope(
      color: SoloLevelingColors.textSecondary,
      fontSize: 14,
    ),
    floatingLabelStyle: GoogleFonts.manrope(
      color: borderAccent.withValues(alpha: 0.9),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderAccent.withValues(alpha: 0.35)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderAccent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
