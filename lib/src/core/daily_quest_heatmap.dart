import '../models/quest_model.dart';

/// Ключ дня для мапы завершённых ежедневок (локальная дата).
String questDayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Сколько **завершённых** ежедневных квестов пришлось на каждый день.
Map<String, int> aggregateCompletedDailyQuestsByDay(Iterable<Quest> quests) {
  final m = <String, int>{};
  for (final q in quests) {
    if (q.type != QuestType.daily) continue;
    if (q.status != QuestStatus.completed) continue;
    final c = q.completedAt;
    if (c == null) continue;
    final k = questDayKey(DateTime(c.year, c.month, c.day));
    m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

/// Сетка «как GitHub»: колонки — недели слева направо, строка = день недели.
/// Индекс строки: `DateTime.weekday % 7` → 0 = воскресенье … 6 = суббота.
/// Значение `-1`: день вне окна [startDay, endDay].
List<List<int>> buildHeatmapYearColumns({
  required Map<String, int> countsByDay,
  DateTime? referenceDate,
}) {
  final ref = referenceDate ?? DateTime.now();
  final endDay = DateTime(ref.year, ref.month, ref.day);
  final startDay = endDay.subtract(const Duration(days: 364));

  var cursor = startDay;
  while (cursor.weekday != DateTime.sunday) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final columns = <List<int>>[];
  while (!cursor.isAfter(endDay)) {
    final week = <int>[];
    for (var i = 0; i < 7; i++) {
      final d = cursor.add(Duration(days: i));
      if (d.isBefore(startDay) || d.isAfter(endDay)) {
        week.add(-1);
      } else {
        week.add(countsByDay[questDayKey(d)] ?? 0);
      }
    }
    columns.add(week);
    cursor = cursor.add(const Duration(days: 7));
  }
  return columns;
}
