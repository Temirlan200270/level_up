/// Пороги доступа к фичам по уровню охотника.
abstract final class ProgressionGates {
  /// Инвентарь
  static const int inventoryMinLevel = 3;
  
  /// Навыки
  static const int skillsMinLevel = 5;
  
  /// Подземелья
  static const int dungeonsMinLevel = 7;

  /// Регистрация / редактирование названия гильдии в настройках.
  static const int guildMinLevel = 15;

  /// Лаборатория кастом-миров / AI-токены (Фаза 7.6 progressive disclosure).
  static const int laboratoryMinLevel = 10;

  /// Доступ к «Лаборатории» вне первого выбора философии: уровень или веха `story_gate_10`.
  static bool canOpenLaboratory({
    required int hunterLevel,
    required bool philosophyPickerIsFirstRun,
    bool completedStoryGate10 = false,
  }) {
    if (philosophyPickerIsFirstRun) return true;
    if (hunterLevel >= laboratoryMinLevel) return true;
    return completedStoryGate10;
  }
}
