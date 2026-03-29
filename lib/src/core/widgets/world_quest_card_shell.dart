import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../system_visuals_extension.dart';
import 'world_material_chrome.dart';

/// Оболочка карточки квеста по [SystemVisuals] («материя мира», Фаза 7.6).
class WorldQuestCardShell extends StatelessWidget {
  const WorldQuestCardShell({
    super.key,
    required this.visuals,
    required this.child,
    this.onTap,
    this.isStoryGlow = false,
    this.isActive = true,
  });

  final SystemVisuals visuals;
  final Widget child;
  final VoidCallback? onTap;
  final bool isStoryGlow;
  final bool isActive;

  /// Нормализованный множитель свечения относительно базы 0.35.
  double get _glowK => (visuals.glowIntensity / 0.35).clamp(0.2, 1.55);

  BorderRadius get _r =>
      BorderRadius.circular(visuals.panelRadius * visuals.borderRadiusScale);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glow = isStoryGlow && isActive;

    switch (visuals.surfaceKind) {
      case SystemSurfaceKind.glass:
        return _glassCard(context, scheme, glow);
      case SystemSurfaceKind.parchment:
        return _parchmentCard(context, scheme, glow);
      case SystemSurfaceKind.digital:
        return _digitalCard(context, scheme, glow);
    }
  }

  double _alpha(double base, {bool forSoft = false}) {
    var a = base * _glowK;
    if (visuals.shadowProfile == SystemShadowProfile.soft) {
      a *= forSoft ? 0.55 : 0.72;
    } else if (visuals.shadowProfile == SystemShadowProfile.none) {
      a *= 0.35;
    }
    return a.clamp(0.0, 1.0);
  }

  List<BoxShadow> _storyExtra(ColorScheme scheme, bool glow) {
    if (!glow) return const [];
    return [
      BoxShadow(
        color: scheme.primary.withValues(alpha: _alpha(0.38)),
        blurRadius: 18,
        spreadRadius: 0,
      ),
    ];
  }

  Widget _digitalCard(
    BuildContext context,
    ColorScheme scheme,
    bool glow,
  ) {
    final useHeavyGlow = visuals.shadowProfile == SystemShadowProfile.glow;
    final shadows = <BoxShadow>[];
    if (visuals.shadowProfile != SystemShadowProfile.none || glow) {
      if (useHeavyGlow) {
        shadows.addAll([
          BoxShadow(
            color: scheme.primary.withValues(
              alpha: _alpha(glow ? 0.48 : 0.30),
            ),
            blurRadius: glow ? 16 : 10,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: scheme.secondary.withValues(
              alpha: _alpha(glow ? 0.24 : 0.14),
            ),
            blurRadius: glow ? 22 : 14,
            spreadRadius: -1,
          ),
        ]);
      } else {
        shadows.add(
          BoxShadow(
            color: scheme.primary.withValues(alpha: _alpha(0.2, forSoft: true)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        );
      }
      shadows.addAll(_storyExtra(scheme, glow));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: _r,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _r,
            color: scheme.surface,
            border: Border.all(
              color: scheme.primary,
              width: visuals.panelBorderWidth.clamp(1.0, 3.0),
            ),
            boxShadow: shadows,
          ),
          child: WorldMaterialChrome(visuals: visuals, child: child),
        ),
      ),
    );
  }

  Widget _glassCard(
    BuildContext context,
    ColorScheme scheme,
    bool glow,
  ) {
    final sigma = visuals.panelBlur.clamp(6.0, 22.0);
    final shadows = <BoxShadow>[
      if (visuals.shadowProfile != SystemShadowProfile.none)
        BoxShadow(
          color: scheme.primary.withValues(
            alpha: _alpha(glow ? 0.18 : 0.08, forSoft: true),
          ),
          blurRadius: glow ? 18 : 12,
        ),
      ..._storyExtra(scheme, glow),
    ];

    return ClipRRect(
      borderRadius: _r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: _r,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: _r,
                color: scheme.surface.withValues(alpha: 0.28),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: glow ? 0.22 : 0.14),
                  width: 1,
                ),
                boxShadow: shadows,
              ),
              child: WorldMaterialChrome(visuals: visuals, child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _parchmentCard(
    BuildContext context,
    ColorScheme scheme,
    bool glow,
  ) {
    final parchmentTint = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.07),
      scheme.surfaceContainerHighest,
    );
    final shadows = <BoxShadow>[];
    if (visuals.shadowProfile != SystemShadowProfile.none) {
      shadows.add(
        BoxShadow(
          color: Colors.black.withValues(
            alpha: 0.12 + 0.10 * _glowK * (glow ? 1.15 : 1.0),
          ),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      );
      if (glow) {
        shadows.add(
          BoxShadow(
            color: scheme.primary.withValues(alpha: _alpha(0.14, forSoft: true)),
            blurRadius: 18,
          ),
        );
      }
    }
    shadows.addAll(_storyExtra(scheme, glow));

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: _r,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _r,
            color: parchmentTint,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.2),
              width: visuals.panelBorderWidth.clamp(0.5, 1.5),
            ),
            boxShadow: shadows,
          ),
          child: WorldMaterialChrome(visuals: visuals, child: child),
        ),
      ),
    );
  }
}
