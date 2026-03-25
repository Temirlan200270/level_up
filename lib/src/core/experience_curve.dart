import 'dart:math' as math;

/// Экспоненциальная кривая опыта до следующего уровня (долгосрочный баланс).
///
/// Уровень 1: как в MVP (100 XP). Дальше — рост с коэффициентом [_growth].
abstract final class ExperienceCurve {
  static const double _base = 100;
  /// Множитель на шаг уровня (~+27%/уровень к требуемому XP на баре).
  static const double _growth = 1.27;

  /// Опыт, необходимый на текущем [level], чтобы перейти на level+1.
  static double maxExperienceForLevel(int level) {
    if (level < 1) return _base;
    return _base * math.pow(_growth, level - 1);
  }

  /// Линейная формула MVP: `level * 100`.
  static double legacyLinearMaxForLevel(int level) =>
      (level < 1 ? 1 : level) * 100.0;

  /// Сохранение с дефолтным maxExp из старой сборки (линейная кривая).
  static bool matchesLegacyLinear(double maxExp, int level) {
    final linear = legacyLinearMaxForLevel(level);
    return (maxExp - linear).abs() <= 1.0;
  }
}
