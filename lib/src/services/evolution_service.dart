import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hidden_classes_data.dart';
import '../models/hunter_model.dart';
import '../models/quest_model.dart';
import '../core/game_feedback.dart';
import '../core/feedback_overlay.dart';
import 'database_service.dart';
import 'providers.dart';

/// Сервис «Скрытой Эволюции».
/// Анализирует паттерны поведения игрока и разблокирует скрытые классы и титулы.
class EvolutionService {
  final Ref _ref;

  EvolutionService(this._ref);

  /// Главная точка входа для проверки эволюции после завершения квеста.
  Future<void> evaluateEvolution(Quest completedQuest) async {
    final hunter = _ref.read(hunterProvider);
    if (hunter == null) return;

    // 1. Проверка скрытых классов (на основе тегов)
    if (hunter.hiddenClassId == null) {
      await _checkHiddenClasses(hunter);
    }

    // 2. Проверка специальных титулов (кроме тех, что в ачивках)
    await _checkSpecialTitles(hunter, completedQuest);
  }

  /// Анализирует накопленные теги для выдачи скрытого класса.
  Future<void> _checkHiddenClasses(Hunter hunter) async {
    final tagCounts = DatabaseService.getTagCounts();

    for (final hClass in allHiddenClasses) {
      int score = 0;
      for (final tag in hClass.requiredTags) {
        score += tagCounts[tag.toLowerCase()] ?? 0;
      }

      if (score >= hClass.threshold) {
        // Ура! Класс открыт.
        final updatedHunter = hunter.copyWith(hiddenClassId: hClass.id);
        await _ref.read(hunterProvider.notifier).updateHunter(updatedHunter);

        // Опционально: уведомление или ачивка
        await DatabaseService.unlockAchievement('class_${hClass.id}');
        GameFeedback.onUnlock();
        _ref
            .read(feedbackOverlayProvider.notifier)
            .show(FeedbackOverlayKind.unlock);
        break; // Только один скрытый класс за раз (или вообще один)
      }
    }
  }

  /// Проверка специфических условий для титулов.
  Future<void> _checkSpecialTitles(Hunter hunter, Quest completedQuest) async {
    // Титул «Неутомимый» за стрик 7 дней (уже есть в ачивках, но дублируем логику тут для чистоты)
    if (hunter.dailyQuestStreak >= 7 &&
        !hunter.unlockedTitleIds.contains('title_relentless')) {
      await _ref.read(hunterProvider.notifier).unlockTitle('title_relentless');
      GameFeedback.onUnlock();
      _ref
          .read(feedbackOverlayProvider.notifier)
          .show(FeedbackOverlayKind.unlock);
    }

    // Титул «Выживший» за прохождение штрафного квеста
    if (completedQuest.type == QuestType.penalty &&
        !hunter.unlockedTitleIds.contains('title_survivor')) {
      await _ref.read(hunterProvider.notifier).unlockTitle('title_survivor');
      GameFeedback.onUnlock();
      _ref
          .read(feedbackOverlayProvider.notifier)
          .show(FeedbackOverlayKind.unlock);
    }

    // Скрытый титул «Любимец Системы» (например, за 100 квестов суммарно)
    // Можно добавить проверку общего кол-ва квестов в DatabaseService
  }
}

final evolutionServiceProvider = Provider<EvolutionService>((ref) {
  return EvolutionService(ref);
});
