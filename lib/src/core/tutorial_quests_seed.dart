import '../models/quest_model.dart';

/// Три стартовых квеста «Пробуждение» (онбординг Solo Leveling).
abstract final class TutorialQuestsSeed {
  static List<Quest> build(String language) {
    final isEn = language == 'en';
    final baseTags = <String>['awakening', 'tutorial'];
    final now = DateTime.now();
    final d72 = now.add(const Duration(hours: 72));

    if (isEn) {
      return [
        Quest(
          title: 'First Awakening',
          description:
              'The System has noticed you. Complete any small real-life task '
              'and acknowledge your resolve: write down one concrete goal for today.',
          type: QuestType.story,
          experienceReward: 12,
          goldReward: 6,
          tags: baseTags,
          difficulty: 1,
          mandatory: false,
          expiresAt: d72,
        ),
        Quest(
          title: 'Status Window',
          description:
              'Open the app daily for three days in a row or complete two daily quests. '
              'Track your habits like stats in a game.',
          type: QuestType.story,
          experienceReward: 18,
          goldReward: 10,
          tags: [...baseTags, 'daily'],
          difficulty: 2,
          mandatory: false,
          expiresAt: d72,
        ),
        Quest(
          title: 'Shadow Training',
          description:
              'Do 15 minutes of physical activity or focused learning. '
              'Growth demands repetition — even Hunters level from the basics.',
          type: QuestType.story,
          experienceReward: 22,
          goldReward: 12,
          tags: [...baseTags, 'sport'],
          difficulty: 2,
          mandatory: false,
          expiresAt: d72,
        ),
      ];
    }

    return [
      Quest(
        title: 'Первое пробуждение',
        description:
            'Система заметила тебя. Выполни одну маленькую задачу из реальной жизни '
            'и зафиксируй решимость: запиши одну конкретную цель на сегодня.',
        type: QuestType.story,
        experienceReward: 12,
        goldReward: 6,
        tags: baseTags,
        difficulty: 1,
        mandatory: false,
        expiresAt: d72,
      ),
      Quest(
        title: 'Окно статуса',
        description:
            'Заходи в приложение три дня подряд или заверши два ежедневных квеста. '
            'Отслеживай привычки как характеристики в игре.',
        type: QuestType.story,
        experienceReward: 18,
        goldReward: 10,
        tags: [...baseTags, 'daily'],
        difficulty: 2,
        mandatory: false,
        expiresAt: d72,
      ),
      Quest(
        title: 'Тень тренировки',
        description:
            'Занимись физической активностью или учёбой 15 минут. '
            'Рост требует повторений — даже охотники качаются с основ.',
        type: QuestType.story,
        experienceReward: 22,
        goldReward: 12,
        tags: [...baseTags, 'sport'],
        difficulty: 2,
        mandatory: false,
        expiresAt: d72,
      ),
    ];
  }
}
