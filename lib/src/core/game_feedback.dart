import 'package:flutter/services.dart';

/// Локальная обратная связь без внешних аудио-ассетов (соответствует фазе 5 плана).
class GameFeedback {
  GameFeedback._();

  /// Несколько уровней подряд — несколько коротких ударов + системный сигнал.
  static void onLevelUp({int levelsGained = 1}) {
    final n = levelsGained.clamp(1, 5);
    for (var i = 0; i < n; i++) {
      HapticFeedback.heavyImpact();
    }
    SystemSound.play(SystemSoundType.alert);
  }

  /// Дроп золота или предмета после квеста.
  static void onLootDrop() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Квест завершён, но отдельного дропа нет.
  static void onQuestComplete() {
    HapticFeedback.mediumImpact();
  }

  /// Провал квеста (в т.ч. со штрафами).
  static void onQuestFail() {
    HapticFeedback.heavyImpact();
  }

  /// Покупка в магазине.
  static void onPurchase() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  /// Продажа предмета.
  static void onSell() {
    HapticFeedback.lightImpact();
  }

  /// Надеть / снять экипировку.
  static void onEquip() {
    HapticFeedback.mediumImpact();
  }

  static void onUnequip() {
    HapticFeedback.lightImpact();
  }

  /// Использование расходника.
  static void onConsumable() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Активация активного навыка (успешно).
  static void onSkillActivate() {
    HapticFeedback.mediumImpact();
  }

  /// Изучение навыка или улучшение за SP.
  static void onSkillProgress() {
    HapticFeedback.selectionClick();
  }
}
