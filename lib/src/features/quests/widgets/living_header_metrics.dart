import '../../../models/quest_model.dart';
import '../../../services/database_service.dart';

/// Снимок «жизненной силы»: физические ежедневные цели за сегодня.
class LivingHeaderVitalitySnapshot {
  const LivingHeaderVitalitySnapshot({
    required this.ratio,
    required this.completedCount,
    required this.totalCount,
  });

  /// 0..1; при отсутствии релевантных квестов — 1.0.
  final double ratio;
  final int completedCount;
  final int totalCount;
}

bool _sameLocalCalendarDay(DateTime a, DateTime now) =>
    a.year == now.year && a.month == now.month && a.day == now.day;

/// Доля закрытых сегодня физических ежедневных целей (как в мировых вратах).
LivingHeaderVitalitySnapshot computeLivingHeaderVitality(Iterable<Quest> quests) {
  final now = DateTime.now();
  var total = 0;
  var done = 0;
  for (final q in quests) {
    if (q.type != QuestType.daily) continue;
    if (!DatabaseService.questIsPhysicalForLivingHeader(q)) continue;

    final completedToday = q.status == QuestStatus.completed &&
        q.completedAt != null &&
        _sameLocalCalendarDay(q.completedAt!, now);
    final activePending = q.status == QuestStatus.active;

    if (!completedToday && !activePending) continue;
    total++;
    if (completedToday) done++;
  }

  if (total == 0) {
    return const LivingHeaderVitalitySnapshot(
      ratio: 1.0,
      completedCount: 0,
      totalCount: 0,
    );
  }
  return LivingHeaderVitalitySnapshot(
    ratio: (done / total).clamp(0.0, 1.0),
    completedCount: done,
    totalCount: total,
  );
}

/// Прогресс «фокуса» за день к дневной цели (0..1).
double livingHeaderFocusMpRatio(int minutesToday) {
  final g = DatabaseService.livingHeaderFocusDailyGoalMinutes;
  if (g <= 0) return 0;
  return (minutesToday / g).clamp(0.0, 1.0);
}
