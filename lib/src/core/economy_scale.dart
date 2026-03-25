import 'dart:math' as math;

/// Динамическое масштабирование золота от уровня охотника (мягкий антиинфляционный рост наград).
abstract final class EconomyScale {
  /// Награда золотом с квеста (после завершения).
  static int scaledQuestGoldReward(int base, int level) {
    if (base <= 0) return 0;
    final lv = math.max(1, level);
    final m = 1.0 + (lv - 1) * 0.035;
    return math.max(1, (base * m).round());
  }

  /// Золото из RNG-дропа после квеста.
  static int scaleLootGold(int base, int level) {
    if (base <= 0) return 0;
    final lv = math.max(1, level);
    final m = 1.0 + (lv - 1) * 0.025;
    return math.max(1, (base * m).round());
  }

  /// Цена покупки в лавке (мягкий рост с уровнем охотника).
  static int scaledShopBuyPrice(int base, int level) {
    if (base <= 0) return 0;
    final lv = math.max(1, level);
    final m = 1.0 + (lv - 1) * 0.04;
    return math.max(1, (base * m).round());
  }

  /// Цена единицы при продаже (база из `sellPrice` в эффектах или половина `buyPrice`).
  /// Рост слабее покупки, чтобы экономика не разгонялась от фарма продаж.
  static int scaledShopSellUnitPrice(int baseUnit, int level) {
    if (baseUnit <= 0) return 0;
    final lv = math.max(1, level);
    final m = 1.0 + (lv - 1) * 0.025;
    return math.max(1, (baseUnit * m).round());
  }
}
