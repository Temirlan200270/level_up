import '../../models/quest_model.dart';

/// Группировка активных квестов для ленты (Фаза 7.7).
abstract final class QuestSectionGrouping {
  static List<Quest> penalty(Iterable<Quest> active) =>
      active.where((q) => q.type == QuestType.penalty).toList();

  static List<Quest> story(Iterable<Quest> active) =>
      active.where((q) => q.type == QuestType.story).toList();

  static List<Quest> daily(Iterable<Quest> active) =>
      active.where((q) => q.type == QuestType.daily).toList();

  static List<Quest> misc(Iterable<Quest> active) => active
      .where(
        (q) =>
            q.type == QuestType.weekly ||
            q.type == QuestType.special ||
            q.type == QuestType.urgent,
      )
      .toList();
}
