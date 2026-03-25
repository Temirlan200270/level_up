/// Определение достижения (локально, без сервера).
class AchievementDef {
  final String id;
  final String titleRu;
  final String titleEn;
  final String descRu;
  final String descEn;

  const AchievementDef({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.descRu,
    required this.descEn,
  });
}

/// Каталог достижений приложения.
const List<AchievementDef> kAllAchievements = [
  AchievementDef(
    id: 'first_quest',
    titleRu: 'Первый шаг',
    titleEn: 'First step',
    descRu: 'Завершите первый квест.',
    descEn: 'Complete your first quest.',
  ),
  AchievementDef(
    id: 'level_5',
    titleRu: 'Рост силы',
    titleEn: 'Growing power',
    descRu: 'Достигните 5 уровня.',
    descEn: 'Reach level 5.',
  ),
  AchievementDef(
    id: 'level_10',
    titleRu: 'Опытный охотник',
    titleEn: 'Seasoned hunter',
    descRu: 'Достигните 10 уровня.',
    descEn: 'Reach level 10.',
  ),
  AchievementDef(
    id: 'gold_1000',
    titleRu: 'Копилка',
    titleEn: 'Coin purse',
    descRu: 'Накопите 1000 золота.',
    descEn: 'Accumulate 1000 gold.',
  ),
  AchievementDef(
    id: 'streak_7',
    titleRu: 'Непрерывность',
    titleEn: 'Consistency',
    descRu: '7 ежедневных квестов подряд.',
    descEn: '7 daily quests in a row.',
  ),
  AchievementDef(
    id: 'urgent_hero',
    titleRu: 'Реакция на угрозу',
    titleEn: 'Urgent response',
    descRu: 'Завершите срочный квест.',
    descEn: 'Complete an urgent quest.',
  ),
  AchievementDef(
    id: 'class_coder',
    titleRu: 'Скрытый класс: Кодер',
    titleEn: 'Hidden class: Coder',
    descRu: 'Много задач с тегом «код».',
    descEn: 'Many quests tagged «code».',
  ),
  AchievementDef(
    id: 'monarch_mode',
    titleRu: 'Порог Монарха',
    titleEn: 'Monarch threshold',
    descRu: 'Достигните 50 уровня и войдите в эндгейм.',
    descEn: 'Reach level 50 and enter endgame.',
  ),
  AchievementDef(
    id: 'mage_combo',
    titleRu: 'Комбинатор рун',
    titleEn: 'Rune combiner',
    descRu: 'Завершите квест с несколькими рунами (тегами) и получите комбо-усиление.',
    descEn: 'Complete a quest with multiple runes (tags) and earn a combo boost.',
  ),
  AchievementDef(
    id: 'mage_entropy',
    titleRu: 'Следы энтропии',
    titleEn: 'Traces of entropy',
    descRu: 'Почувствуйте затухание: завершите квест после долгого перерыва по рунам.',
    descEn: 'Feel the fading: complete a quest after a long rune break.',
  ),
];
