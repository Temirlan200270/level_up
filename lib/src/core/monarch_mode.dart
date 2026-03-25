/// Базовые правила эндгейма «Режим Монарха».
abstract final class MonarchMode {
  /// Минимальный уровень для входа в эндгейм.
  static const int minLevel = 50;

  static bool isUnlocked(int level) => level >= minLevel;
}
