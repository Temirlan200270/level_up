import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

/// Визуальные токены уровня “мира/философии”.
///
/// Важно: не завязываемся на захардкоженные цвета — основной цвет берём из
/// `Theme.of(context).colorScheme`, а здесь храним “атмосферу”: фон, частицы,
/// формы и типографические коэффициенты.
class SystemVisuals extends ThemeExtension<SystemVisuals> {
  const SystemVisuals({
    required this.backgroundKind,
    required this.backgroundAssetPath,
    required this.particlesKind,
    required this.panelRadius,
    required this.panelBorderWidth,
    required this.titleLetterSpacing,
  });

  /// Тип бэкдропа: процедурный или (в будущем) ассетный.
  final SystemBackgroundKind backgroundKind;

  /// Путь до ассета фона (если появится). Может быть пустым.
  final String backgroundAssetPath;

  /// Тип частиц: выбираем характер (искра/руны/лепестки).
  final SystemParticlesKind particlesKind;

  /// Формы/бордеры: радиус “панелей/карточек” уровня мира.
  final double panelRadius;

  /// Толщина декоративной рамки (если нужна).
  final double panelBorderWidth;

  /// Типографика: трекинг заголовков (Manrope остаётся базой по дизайн-системе).
  final double titleLetterSpacing;

  @override
  SystemVisuals copyWith({
    SystemBackgroundKind? backgroundKind,
    String? backgroundAssetPath,
    SystemParticlesKind? particlesKind,
    double? panelRadius,
    double? panelBorderWidth,
    double? titleLetterSpacing,
  }) {
    return SystemVisuals(
      backgroundKind: backgroundKind ?? this.backgroundKind,
      backgroundAssetPath: backgroundAssetPath ?? this.backgroundAssetPath,
      particlesKind: particlesKind ?? this.particlesKind,
      panelRadius: panelRadius ?? this.panelRadius,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      titleLetterSpacing: titleLetterSpacing ?? this.titleLetterSpacing,
    );
  }

  @override
  SystemVisuals lerp(ThemeExtension<SystemVisuals>? other, double t) {
    if (other is! SystemVisuals) return this;
    return SystemVisuals(
      backgroundKind: t < 0.5 ? backgroundKind : other.backgroundKind,
      backgroundAssetPath: t < 0.5 ? backgroundAssetPath : other.backgroundAssetPath,
      particlesKind: t < 0.5 ? particlesKind : other.particlesKind,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t) ?? panelRadius,
      panelBorderWidth:
          lerpDouble(panelBorderWidth, other.panelBorderWidth, t) ?? panelBorderWidth,
      titleLetterSpacing:
          lerpDouble(titleLetterSpacing, other.titleLetterSpacing, t) ??
              titleLetterSpacing,
    );
  }
}

enum SystemBackgroundKind {
  grid,
  parchment,
  mist,
}

enum SystemParticlesKind {
  sparkles,
  runes,
  petals,
  none,
}

