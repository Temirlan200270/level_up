import '../core/world_journal_axis_tags.dart';
import '../models/quest_model.dart';
import 'database_service.dart';

/// Одноразовое уведомление о пороге дневника (3 / 10 / 25) после завершения квеста.
class WorldJournalSnackHit {
  const WorldJournalSnackHit({
    required this.tierTranslationKey,
    required this.axisLabelKey,
  });

  /// Ключ вида `world_journal_snack_tier_whisper` с плейсхолдером `{axis}`.
  final String tierTranslationKey;

  /// Ключ локализованного названия оси (`world_journal_body_axis` и т.д.).
  final String axisLabelKey;
}

abstract final class WorldJournalMilestoneNotifications {
  static int _countAxis(List<Quest> done, Set<String> keys) {
    var n = 0;
    for (final q in done) {
      final hit = q.tags.any(
        (tag) => keys.contains(tag.toLowerCase().trim()),
      );
      if (hit) n++;
    }
    return n;
  }

  /// Фиксирует первый подходящий порог и возвращает данные для SnackBar (не чаще одного за вызов).
  static Future<WorldJournalSnackHit?> consumeNextNotificationIfAny() async {
    final done = DatabaseService.getAllQuests()
        .where((q) => q.status == QuestStatus.completed)
        .toList();

    final bodyN = _countAxis(done, WorldJournalAxisTags.body);
    final mindN = _countAxis(done, WorldJournalAxisTags.mind);
    final focusN = _countAxis(done, WorldJournalAxisTags.focus);

    const tiers = <(String tier, int th)>[
      ('codex', 25),
      ('seal', 10),
      ('whisper', 3),
    ];

    final axes = <(String id, int count, String labelKey)>[
      ('body', bodyN, 'world_journal_body_axis'),
      ('mind', mindN, 'world_journal_mind_axis'),
      ('focus', focusN, 'world_journal_focus_axis'),
    ];

    for (final tier in tiers) {
      for (final axis in axes) {
        if (axis.$2 < tier.$2) continue;
        if (DatabaseService.isWorldJournalSnackShown(axis.$1, tier.$1)) {
          continue;
        }
        await DatabaseService.markWorldJournalSnackShown(axis.$1, tier.$1);
        return WorldJournalSnackHit(
          tierTranslationKey: 'world_journal_snack_tier_${tier.$1}',
          axisLabelKey: axis.$3,
        );
      }
    }
    return null;
  }
}
