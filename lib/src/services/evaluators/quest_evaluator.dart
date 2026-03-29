import '../../models/quest_model.dart';
import '../../models/hunter_model.dart';

class QuestEvaluationResult {
  final int suggestedExp;
  final int suggestedGold;
  final int difficultyRank; // 1 - E, 2 - D, 3 - C, 4 - B, 5 - A, 6 - S
  final List<String> tags;
  final String? systemComment;
  final bool isApproved;

  /// Локальная эвристика (нет ключа ИИ, сеть или парсинг не удались).
  final bool usedLocalHeuristics;

  const QuestEvaluationResult({
    required this.suggestedExp,
    required this.suggestedGold,
    required this.difficultyRank,
    required this.tags,
    this.systemComment,
    this.isApproved = true,
    this.usedLocalHeuristics = false,
  });
}

abstract class QuestEvaluator {
  Future<QuestEvaluationResult> evaluateQuest({
    required String title,
    required String description,
    required Hunter hunter,
    required QuestType type,
  });
}
