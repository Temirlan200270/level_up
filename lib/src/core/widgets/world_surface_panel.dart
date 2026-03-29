import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../system_visuals_extension.dart';

/// Панель-оболочка для целых секций экрана (инвентарь, лавка) в стиле [SystemVisuals].
class WorldSurfacePanel extends StatelessWidget {
  const WorldSurfacePanel({
    super.key,
    required this.visuals,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 12),
  });

  final SystemVisuals visuals;
  final Widget child;
  final EdgeInsets margin;

  double get _glowK => (visuals.glowIntensity / 0.35).clamp(0.2, 1.55);

  BorderRadius get _r =>
      BorderRadius.circular(visuals.panelRadius * visuals.borderRadiusScale);

  static const int _grainSeed = 0x5f3759df;

  Widget _maybeGrainOverlay(SystemVisuals visuals, ColorScheme scheme, Widget child) {
    final g = visuals.grainOpacity;
    if (g <= 0.001) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: _r,
              child: CustomPaint(
                painter: _PanelGrainPainter(
                  opacity: g.clamp(0.0, 0.12),
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _alpha(ColorScheme scheme, double base, {bool forSoft = false}) {
    var a = base * _glowK;
    if (visuals.shadowProfile == SystemShadowProfile.soft) {
      a *= forSoft ? 0.55 : 0.72;
    } else if (visuals.shadowProfile == SystemShadowProfile.none) {
      a *= 0.35;
    }
    return a.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (visuals.surfaceKind) {
      case SystemSurfaceKind.glass:
        return Padding(
          padding: margin,
          child: ClipRRect(
            borderRadius: _r,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: visuals.panelBlur.clamp(6.0, 22.0),
                sigmaY: visuals.panelBlur.clamp(6.0, 22.0),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _r,
                  color: scheme.surface.withValues(alpha: 0.28),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    if (visuals.shadowProfile != SystemShadowProfile.none)
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: _alpha(scheme, 0.08, forSoft: true),
                        ),
                        blurRadius: 12,
                      ),
                  ],
                ),
                child: _maybeGrainOverlay(visuals, scheme, child),
              ),
            ),
          ),
        );
      case SystemSurfaceKind.parchment:
        final parchmentTint = Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.07),
          scheme.surfaceContainerHighest,
        );
        return Padding(
          padding: margin,
          child: ClipRRect(
            borderRadius: _r,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _r,
                color: parchmentTint,
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.2),
                  width: visuals.panelBorderWidth.clamp(0.5, 1.5),
                ),
                boxShadow: [
                  if (visuals.shadowProfile != SystemShadowProfile.none)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: _maybeGrainOverlay(visuals, scheme, child),
            ),
          ),
        );
      case SystemSurfaceKind.digital:
        final shadows = <BoxShadow>[];
        if (visuals.shadowProfile != SystemShadowProfile.none) {
          shadows.add(
            BoxShadow(
              color: scheme.primary.withValues(
                alpha: _alpha(scheme, 0.2, forSoft: true),
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          );
        }
        return Padding(
          padding: margin,
          child: ClipRRect(
            borderRadius: _r,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _r,
                color: scheme.surface,
                border: Border.all(
                  color: scheme.primary,
                  width: visuals.panelBorderWidth.clamp(1.0, 3.0),
                ),
                boxShadow: shadows,
              ),
              child: _maybeGrainOverlay(visuals, scheme, child),
            ),
          ),
        );
    }
  }
}

/// Лёгкое зерно поверх панели (низкая нагрузка: фиксированные точки).
class _PanelGrainPainter extends CustomPainter {
  _PanelGrainPainter({required this.opacity, required this.color});

  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(WorldSurfacePanel._grainSeed);
    final n = (size.shortestSide * 1.8).round().clamp(48, 220);
    for (var i = 0; i < n; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = opacity * (0.15 + rnd.nextDouble() * 0.85);
      canvas.drawCircle(
        Offset(x, y),
        0.35 + rnd.nextDouble() * 0.95,
        Paint()..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PanelGrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}
