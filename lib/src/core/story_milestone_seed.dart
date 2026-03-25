import '../models/quest_model.dart';

/// Сюжетные вехи на порогах уровней (ворота ранга).
abstract final class StoryMilestoneSeed {
  static const milestoneLevels = [10, 25, 50];

  static Quest questForGate(int gateLevel, String language) {
    final isEn = language == 'en';
    final tagGate = 'story_gate_$gateLevel';
    final now = DateTime.now();
    final deadline = now.add(const Duration(hours: 168));

    switch (gateLevel) {
      case 10:
        return Quest(
          title: isEn ? 'D-Rank Gate' : 'Врата ранга D',
          description: isEn
              ? 'You have reached a new tier. Complete a challenging real task (45+ min) '
                  'or finish 3 quests this week. The System marks your progress.'
              : 'Ты вышел на новый ярус. Выполни сложную реальную задачу (45+ мин) '
                  'или заверши 3 квеста за неделю. Система отмечает твой прогресс.',
          type: QuestType.story,
          experienceReward: 40,
          statPointsReward: 1,
          goldReward: 28,
          tags: ['story_milestone', tagGate, 'rank_gate'],
          difficulty: 3,
          mandatory: false,
          expiresAt: deadline,
        );
      case 25:
        return Quest(
          title: isEn ? 'B-Rank Trial' : 'Испытание ранга B',
          description: isEn
              ? 'Pressure rises. Complete one major project step or a 2-hour deep work block. '
                  'Show the discipline of a high-rank Hunter.'
              : 'Давление растёт. Заверши крупный шаг проекта или 2 часа глубокой работы. '
                  'Покажи дисциплину охотника высокого ранга.',
          type: QuestType.story,
          experienceReward: 70,
          statPointsReward: 2,
          goldReward: 55,
          tags: ['story_milestone', tagGate, 'rank_gate'],
          difficulty: 4,
          mandatory: false,
          expiresAt: deadline,
        );
      case 50:
        return Quest(
          title: isEn ? 'S-Rank Threshold' : 'Порог S-ранга',
          description: isEn
              ? 'Legends are forged slowly. Commit to a week-long streak of meaningful quests '
                  'or one exceptional achievement. The Monarch watches silently.'
              : 'Легенды куются медленно. Выполни недельную серию значимых квестов '
                  'или одно выдающееся достижение. Монарх молча наблюдает.',
          type: QuestType.story,
          experienceReward: 120,
          statPointsReward: 3,
          goldReward: 100,
          tags: ['story_milestone', tagGate, 'rank_gate', 'monarch_hint'],
          difficulty: 5,
          mandatory: false,
          expiresAt: deadline,
        );
      default:
        return Quest(
          title: isEn ? 'System milestone' : 'Веха Системы',
          description: isEn
              ? 'A story gate opened. Complete a worthy real-life challenge.'
              : 'Открылись сюжетные врата. Справься с достойным вызовом из реальной жизни.',
          type: QuestType.story,
          experienceReward: 30,
          goldReward: 20,
          tags: ['story_milestone', tagGate],
          difficulty: 3,
          expiresAt: deadline,
        );
    }
  }
}
