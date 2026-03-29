import 'dart:async';

import 'package:flutter/services.dart';

import '../services/sound_service.dart';

/// Локальная обратная связь: тактильно всегда (если поддерживается), звук — по настройке SFX.
class GameFeedback {
  GameFeedback._();

  /// Несколько уровней подряд — несколько коротких ударов + системный сигнал.
  static void onLevelUp({int levelsGained = 1}) {
    final n = levelsGained.clamp(1, 5);
    for (var i = 0; i < n; i++) {
      HapticFeedback.heavyImpact();
    }
    unawaited(SoundService.playLevelUp());
  }

  /// Дроп золота или предмета после квеста.
  static void onLootDrop() {
    HapticFeedback.mediumImpact();
    unawaited(SoundService.playClick());
  }

  /// Квест завершён, но отдельного дропа нет.
  static void onQuestComplete() {
    HapticFeedback.mediumImpact();
    unawaited(SoundService.playQuestComplete());
  }

  /// Провал квеста (в т.ч. со штрафами).
  static void onQuestFail() {
    HapticFeedback.heavyImpact();
    unawaited(SoundService.playQuestFail());
  }

  /// Покупка в магазине.
  static void onPurchase() {
    HapticFeedback.selectionClick();
    unawaited(SoundService.playClick());
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
    unawaited(SoundService.playClick());
  }

  /// Активация активного навыка (успешно).
  static void onSkillActivate() {
    HapticFeedback.mediumImpact();
  }

  /// Изучение навыка или улучшение за SP.
  static void onSkillProgress() {
    HapticFeedback.selectionClick();
  }

  /// Разблокировка класса или титула.
  static void onUnlock() {
    HapticFeedback.heavyImpact();
    unawaited(SoundService.playAlert());
  }
}
