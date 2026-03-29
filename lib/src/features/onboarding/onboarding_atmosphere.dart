import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/system_visuals_extension.dart';
import '../../core/systems/system_id.dart';
/// Параллакс и «пыль» для кат-сцены портала лора.
class OnboardingLoreAtmosphere extends StatefulWidget {
  const OnboardingLoreAtmosphere({super.key});

  @override
  State<OnboardingLoreAtmosphere> createState() =>
      _OnboardingLoreAtmosphereState();
}

class _OnboardingLoreAtmosphereState extends State<OnboardingLoreAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowFx =
        Theme.of(context).extension<SystemVisuals>()?.lowFxMode ?? false;
    if (lowFx) {
      return const ColoredBox(color: Colors.transparent);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 2) * 16;
        final dy = math.cos(t * math.pi * 2 * 0.73) * 12;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(dx, dy),
              child: CustomPaint(
                painter: _VoidDriftPainter(
                  progress: t,
                  accent: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            CustomPaint(
              painter: _ParticleFieldPainter(progress: t, seed: 2026),
            ),
          ],
        );
      },
    );
  }
}

class _VoidDriftPainter extends CustomPainter {
  _VoidDriftPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    for (var row = 0; row < 8; row++) {
      final y = size.height * (0.08 + row * 0.11) +
          math.sin(progress * math.pi * 2 + row * 0.4) * 8;
      final x1 = size.width * 0.05;
      final x2 = size.width * 0.95;
      canvas.drawLine(
        Offset(x1, y),
        Offset(x2, y + math.sin(progress * 4 + row) * 4),
        base,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoidDriftPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    for (var i = 0; i < 96; i++) {
      final bx = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final drift = (progress * 0.85 + i * 0.019) % 1.0;
      final y = (baseY + drift * size.height * 0.35) % size.height;
      final o = 0.06 + rnd.nextDouble() * 0.42;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: o)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(bx, y),
        0.6 + rnd.nextDouble() * 1.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Аватар Мастера — появляется над диалогом (тон зависит от философии).
class OnboardingMasterAvatar extends StatelessWidget {
  const OnboardingMasterAvatar({super.key, required this.systemId});

  final SystemId systemId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, List<Color> ring) = switch (systemId) {
      SystemId.mage => (
          Icons.auto_fix_high_rounded,
          <Color>[scheme.primary, scheme.secondary],
        ),
      SystemId.cultivator => (
          Icons.spa_rounded,
          <Color>[scheme.primary, const Color(0xFFE8D5A3)],
        ),
      SystemId.custom => (
          Icons.tune_rounded,
          <Color>[scheme.secondary, scheme.primary],
        ),
      SystemId.solo => (
          Icons.psychology_alt_rounded,
          <Color>[scheme.primary, scheme.tertiary],
        ),
    };

    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ring.first.withValues(alpha: 0.42),
              blurRadius: 26,
              spreadRadius: 1,
            ),
          ],
          gradient: RadialGradient(
            colors: [
              ring.first.withValues(alpha: 0.55),
              ring.last.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.28),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 52,
          color: scheme.onSurface.withValues(alpha: 0.92),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 550.ms, curve: Curves.easeOutCubic)
        .scale(
          begin: const Offset(0.78, 0.78),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }
}
