import 'package:flutter/services.dart';

import 'database_service.dart';

/// Короткая звуковая обратная связь (системные сигналы ОС, без тяжёлых ассетов).
///
/// Все вызовы уважают [DatabaseService.isSoundEffectsEnabled] (переключатель в настройках).
abstract final class SoundService {
  static Future<void> playClick() async {
    if (!DatabaseService.isSoundEffectsEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static Future<void> playAlert() async {
    if (!DatabaseService.isSoundEffectsEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Лёгкий отклик UI (оверлеи, мелкие действия).
  static Future<void> playUiTap() => playClick();

  /// Завершение квеста, лут, покупка.
  static Future<void> playQuestComplete() => playClick();

  /// Провал квеста / предупреждение.
  static Future<void> playQuestFail() => playAlert();

  /// Level up, крупный анлок.
  static Future<void> playLevelUp() => playAlert();

  /// Отправка команды в командной строке квестов.
  static Future<void> playCommandSubmit() => playClick();

  /// Высокий ранг / «тяжёлая» задача из командной строки.
  static Future<void> playCommandHighRank() => playAlert();
}
