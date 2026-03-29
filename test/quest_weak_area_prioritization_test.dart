import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/features/onboarding/onboarding_models.dart';
import 'package:level_up/src/features/quests/quest_weak_area_prioritization.dart';
import 'package:level_up/src/models/hunter_model.dart';
import 'package:level_up/src/models/quest_model.dart';
import 'package:level_up/src/models/stats_model.dart';
import 'package:level_up/src/services/evaluators/adaptive_difficulty_service.dart';

void main() {
  const balanced = AdaptiveDifficultyEvaluation(
    status: AdaptiveDifficultyStatus.balanced,
    completionRate: 0.8,
    averageDifficulty: 2.5,
    totalAnalyzed: 10,
  );

  test('persona weaknesses boost matching quests to the top', () {
    final persona = OnboardingPersona(
      name: 't',
      strengths: '',
      weaknesses: 'мало спорта и силы',
      selfRole: '',
      interests: const [],
      goal: '',
    );
    final hunter = Hunter(
      name: 'H',
      level: 3,
      currentExp: 0,
      stats: const Stats(
        strength: 1,
        agility: 4,
        intelligence: 4,
        vitality: 4,
      ),
    );
    final read = Quest(
      title: 'Почитать лекцию',
      description: 'теория',
      type: QuestType.daily,
      createdAt: DateTime(2024, 6, 1),
    );
    final gym = Quest(
      title: 'Зал и спорт',
      description: 'силовая',
      type: QuestType.daily,
      createdAt: DateTime(2024, 6, 2),
    );
    final sorted = QuestWeakAreaPrioritization.sort(
      [read, gym],
      hunter: hunter,
      persona: persona,
      adaptive: balanced,
    );
    expect(sorted.first.title, gym.title);
  });

  test('tooEasy tie-break prefers higher difficulty', () {
    final a = Quest(
      title: 'same',
      description: '',
      type: QuestType.daily,
      difficulty: 1,
      createdAt: DateTime(2024, 6, 2),
    );
    final b = Quest(
      title: 'same',
      description: '',
      type: QuestType.daily,
      difficulty: 5,
      createdAt: DateTime(2024, 6, 1),
    );
    final sorted = QuestWeakAreaPrioritization.sort(
      [a, b],
      adaptive: const AdaptiveDifficultyEvaluation(
        status: AdaptiveDifficultyStatus.tooEasy,
        completionRate: 0.95,
        averageDifficulty: 2,
        totalAnalyzed: 8,
      ),
    );
    expect(sorted.first.difficulty, 5);
  });

  test('tooHard tie-break prefers lower difficulty', () {
    final a = Quest(
      title: 'same',
      description: '',
      type: QuestType.daily,
      difficulty: 1,
      createdAt: DateTime(2024, 6, 1),
    );
    final b = Quest(
      title: 'same',
      description: '',
      type: QuestType.daily,
      difficulty: 5,
      createdAt: DateTime(2024, 6, 2),
    );
    final sorted = QuestWeakAreaPrioritization.sort(
      [a, b],
      adaptive: const AdaptiveDifficultyEvaluation(
        status: AdaptiveDifficultyStatus.tooHard,
        completionRate: 0.5,
        averageDifficulty: 3,
        totalAnalyzed: 8,
      ),
    );
    expect(sorted.first.difficulty, 1);
  });
}
