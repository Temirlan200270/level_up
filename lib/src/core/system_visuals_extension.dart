import 'dart:math' as math;

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
    this.backgroundAssetPath = '',
    required this.particlesKind,
    required this.panelRadius,
    this.panelBorderWidth = 1.0,
    this.panelBlur = 0.0,
    required this.titleLetterSpacing,
    this.surfaceKind = SystemSurfaceKind.digital,
    this.glowIntensity = 0.35,
    this.borderRadiusScale = 1.0,
    this.shadowProfile = SystemShadowProfile.soft,
    this.grainOpacity = 0.0,
    this.lowFxMode = false,
  });

  /// Единый fallback, если в [ThemeData.extensions] нет [SystemVisuals].
  static const SystemVisuals fallback = SystemVisuals(
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

  /// Тип бэкдропа: процедурный или (в будущем) ассетный.
  final SystemBackgroundKind backgroundKind;

  /// Путь до ассета фона (если появится). Может быть пустым.
  final String backgroundAssetPath;

  /// Тип частиц: выбираем характер (искра/руны/лепестки).
  final SystemParticlesKind particlesKind;

  /// Угол закругления панелей/карточек.
  final double panelRadius;

  /// Толщина рамки карточек (например, 1px для Solo, 0px для Cultivator).
  final double panelBorderWidth;

  /// Blur для фона карточек (Glassmorphism).
  final double panelBlur;

  /// Материал поверхности карточек/панелей: цифровой неон / стекло / пергамент.
  final SystemSurfaceKind surfaceKind;

  /// Интенсивность свечения теней/ореола (0…1).
  final double glowIntensity;

  /// Множитель радиуса панелей относительно [panelRadius].
  final double borderRadiusScale;

  /// Профиль тени для карточек и акцентов.
  final SystemShadowProfile shadowProfile;

  /// Letter-spacing для ключевых заголовков (например, в профиле).
  final double titleLetterSpacing;

  /// Лёгкий «зерно»/шум поверх панели (0…~0.08), опционально для perf.
  final double grainOpacity;

  /// Режим энергосбережения (блюр арта фона, упрощение при [applyLowFxMerge]).
  final bool lowFxMode;

  /// Снимает тяжёлые эффекты: зерно, частицы, блюр стекла, агрессивное свечение.
  SystemVisuals applyLowFxMerge() {
    return copyWith(
      grainOpacity: 0,
      particlesKind: SystemParticlesKind.none,
      panelBlur: 0,
      surfaceKind: surfaceKind == SystemSurfaceKind.glass
          ? SystemSurfaceKind.digital
          : surfaceKind,
      glowIntensity: math.min(glowIntensity, 0.32),
      shadowProfile: shadowProfile == SystemShadowProfile.glow
          ? SystemShadowProfile.soft
          : shadowProfile,
      lowFxMode: true,
    );
  }

  @override
  SystemVisuals copyWith({
    SystemBackgroundKind? backgroundKind,
    String? backgroundAssetPath,
    SystemParticlesKind? particlesKind,
    double? panelRadius,
    double? panelBorderWidth,
    double? panelBlur,
    double? titleLetterSpacing,
    SystemSurfaceKind? surfaceKind,
    double? glowIntensity,
    double? borderRadiusScale,
    SystemShadowProfile? shadowProfile,
    double? grainOpacity,
    bool? lowFxMode,
  }) {
    return SystemVisuals(
      backgroundKind: backgroundKind ?? this.backgroundKind,
      backgroundAssetPath: backgroundAssetPath ?? this.backgroundAssetPath,
      particlesKind: particlesKind ?? this.particlesKind,
      panelRadius: panelRadius ?? this.panelRadius,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      panelBlur: panelBlur ?? this.panelBlur,
      titleLetterSpacing: titleLetterSpacing ?? this.titleLetterSpacing,
      surfaceKind: surfaceKind ?? this.surfaceKind,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      borderRadiusScale: borderRadiusScale ?? this.borderRadiusScale,
      shadowProfile: shadowProfile ?? this.shadowProfile,
      grainOpacity: grainOpacity ?? this.grainOpacity,
      lowFxMode: lowFxMode ?? this.lowFxMode,
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
      panelBlur: lerpDouble(panelBlur, other.panelBlur, t) ?? panelBlur,
      titleLetterSpacing:
          lerpDouble(titleLetterSpacing, other.titleLetterSpacing, t) ??
              titleLetterSpacing,
      surfaceKind: t < 0.5 ? surfaceKind : other.surfaceKind,
      glowIntensity:
          lerpDouble(glowIntensity, other.glowIntensity, t) ?? glowIntensity,
      borderRadiusScale:
          lerpDouble(borderRadiusScale, other.borderRadiusScale, t) ??
              borderRadiusScale,
      shadowProfile: t < 0.5 ? shadowProfile : other.shadowProfile,
      grainOpacity:
          lerpDouble(grainOpacity, other.grainOpacity, t) ?? grainOpacity,
      lowFxMode: t < 0.5 ? lowFxMode : other.lowFxMode,
    );
  }
}

/// Профиль тени для мира (Фаза 7.6).
enum SystemShadowProfile {
  /// Почти без диффузной тени (акцент на плоскости).
  none,

  /// Мягкая диффузия.
  soft,

  /// Неоновое свечение (Solo).
  glow,
}

/// Вид поверхности UI-карточек под «материю мира» (Фаза 7.6).
enum SystemSurfaceKind {
  /// Solo: резкие неоновые рамки, «панель Системы».
  digital,

  /// Mage: стекло, полупрозрачность, blur.
  glass,

  /// Cultivator: мягкий пергамент, без жёстких теней.
  parchment,
}

enum SystemBackgroundKind {
  grid,
  parchment,
  mist;

  /// Значение из Hive / бэкапа кастомной системы.
  static SystemBackgroundKind fromCustomStored(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'parchment':
        return SystemBackgroundKind.parchment;
      case 'mist':
        return SystemBackgroundKind.mist;
      case 'grid':
      default:
        return SystemBackgroundKind.grid;
    }
  }
}

enum SystemParticlesKind {
  sparkles,
  runes,
  petals,
  none;

  static SystemParticlesKind fromCustomStored(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'runes':
        return SystemParticlesKind.runes;
      case 'petals':
        return SystemParticlesKind.petals;
      case 'none':
        return SystemParticlesKind.none;
      case 'sparkles':
      default:
        return SystemParticlesKind.sparkles;
    }
  }
}

/// Удобные геттеры для UI, завязанного на [SystemVisuals].
extension SystemVisualsBuildContextX on BuildContext {
  /// Текущие визуалы мира ([SystemVisuals.fallback], если extension не задан).
  SystemVisuals get systemVisuals =>
      Theme.of(this).extension<SystemVisuals>() ?? SystemVisuals.fallback;

  /// Короткий синоним [systemVisuals] для экранов.
  SystemVisuals get visuals => systemVisuals;

  /// Радиус карточек слотов/витрины под текущий мир.
  double get worldCardRadius {
    final v = systemVisuals;
    return (v.panelRadius * v.borderRadiusScale).clamp(8.0, 28.0);
  }
}

