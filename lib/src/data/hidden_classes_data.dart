class HiddenClass {
  final String id;
  final String name;
  final String description;
  final List<String> requiredTags;
  final int threshold;

  const HiddenClass({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredTags,
    this.threshold = 10,
  });
}

const List<HiddenClass> allHiddenClasses = [
  HiddenClass(
    id: 'coder',
    name: 'Теневой Архитектор (Кодер)',
    description: 'Мастер кода, способный переписать правила реальности.',
    requiredTags: ['coding', 'programming', 'dev', 'it', 'software'],
    threshold: 10,
  ),
  HiddenClass(
    id: 'athlete',
    name: 'Стальной Сосуд (Атлет)',
    description: 'Охотник, чей дух закален в бесконечных тренировках тела.',
    requiredTags: ['sport', 'workout', 'gym', 'training', 'body'],
    threshold: 10,
  ),
  HiddenClass(
    id: 'scholar',
    name: 'Искатель Истины (Ученый)',
    description: 'Ваш разум — острейшее оружие. Вы видите суть вещей.',
    requiredTags: ['study', 'learning', 'reading', 'science', 'research'],
    threshold: 10,
  ),
  HiddenClass(
    id: 'monk',
    name: 'Безмолвный (Медитатор)',
    description: 'Вам ведомо спокойствие в центре бури.',
    requiredTags: ['meditation', 'focus', 'mental', 'mindfulness'],
    threshold: 10,
  ),
];

HiddenClass? getHiddenClassById(String? id) {
  if (id == null) return null;
  try {
    return allHiddenClasses.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
