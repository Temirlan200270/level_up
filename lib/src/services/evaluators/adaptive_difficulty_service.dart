import '../../core/systems/system_id.dart';
import '../../models/quest_model.dart';
import '../database_service.dart';

enum AdaptiveDifficultyStatus { tooEasy, tooHard, balanced }

class AdaptiveDifficultyEvaluation {
  final AdaptiveDifficultyStatus status;
  final double completionRate;
  final double averageDifficulty;
  final int totalAnalyzed;

  const AdaptiveDifficultyEvaluation({
    required this.status,
    required this.completionRate,
    required this.averageDifficulty,
    required this.totalAnalyzed,
  });
}

abstract final class AdaptiveDifficultyService {
  static const int _maxSampleSize = 60;

  /// Момент исхода квеста для фильтра по времени (мультивселенная — только [systemId]).
  static DateTime? _outcomeTimestamp(Quest q) {
    switch (q.status) {
      case QuestStatus.completed:
        return q.completedAt;
      case QuestStatus.failed:
        return q.failedAt;
      case QuestStatus.expired:
        return q.failedAt ?? q.expiresAt ?? q.createdAt;
      case QuestStatus.active:
        return null;
    }
  }

  /// Анализ исходов квестов за последние [daysToAnalyze] дней в рамках одной системы.
  static AdaptiveDifficultyEvaluation evaluate(
    int daysToAnalyze, {
    SystemId? systemId,
  }) {
    final id = systemId ?? SystemId.fromValue(DatabaseService.getActiveSystemId());
    final allQuests = DatabaseService.getAllQuests(systemId: id);
    final cutoff = DateTime.now().subtract(Duration(days: daysToAnalyze));

    final candidates = <Quest>[];
    for (final q in allQuests) {
      if (q.status == QuestStatus.active) continue;
      final at = _outcomeTimestamp(q);
      if (at == null) continue;
      if (at.isBefore(cutoff)) continue;
      candidates.add(q);
    }

    candidates.sort((a, b) {
      final ta = _outcomeTimestamp(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = _outcomeTimestamp(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    final targetQuests = candidates.take(_maxSampleSize).toList();

    if (targetQuests.length < 5) {
      return AdaptiveDifficultyEvaluation(
        status: AdaptiveDifficultyStatus.balanced,
        completionRate: 1.0,
        averageDifficulty: 1.0,
        totalAnalyzed: targetQuests.length,
      );
    }

    var completed = 0;
    var failed = 0;
    var totalDifficulty = 0;

    for (final q in targetQuests) {
      if (q.status == QuestStatus.completed) {
        completed++;
      } else if (q.status == QuestStatus.failed ||
          q.status == QuestStatus.expired) {
        failed++;
      }
      totalDifficulty += q.difficulty;
    }

    final total = completed + failed;
    if (total == 0) {
      return const AdaptiveDifficultyEvaluation(
        status: AdaptiveDifficultyStatus.balanced,
        completionRate: 1.0,
        averageDifficulty: 1.0,
        totalAnalyzed: 0,
      );
    }

    final completionRate = completed / total;
    final averageDifficulty = total > 0 ? totalDifficulty / total : 1.0;

    AdaptiveDifficultyStatus status = AdaptiveDifficultyStatus.balanced;

    if (completionRate >= 0.9 && averageDifficulty <= 2.5 && total >= 5) {
      status = AdaptiveDifficultyStatus.tooEasy;
    } else if (completionRate <= 0.6 && total >= 5) {
      status = AdaptiveDifficultyStatus.tooHard;
    }

    return AdaptiveDifficultyEvaluation(
      status: status,
      completionRate: completionRate,
      averageDifficulty: averageDifficulty,
      totalAnalyzed: total,
    );
  }

  static bool shouldPromptCalibration() {
    final lastPromptIso = DatabaseService.getAdaptiveCalibrationLastPrompt();
    if (lastPromptIso == null) return true;
    final lastPrompt = DateTime.tryParse(lastPromptIso);
    if (lastPrompt == null) return true;

    return DateTime.now().difference(lastPrompt).inDays >= 3;
  }

  static Future<void> markPromptShown() async {
    await DatabaseService.setAdaptiveCalibrationLastPrompt(
      DateTime.now().toIso8601String(),
    );
  }
}
