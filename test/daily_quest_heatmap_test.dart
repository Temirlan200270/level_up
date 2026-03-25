import 'package:expense_tracker_flutter/src/core/daily_quest_heatmap.dart';
import 'package:expense_tracker_flutter/src/models/quest_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aggregateCompletedDailyQuestsByDay', () {
    test('учитывает только завершённые daily', () {
      final d = DateTime(2025, 3, 15, 18, 30);
      final quests = [
        Quest(
          title: 'a',
          description: '',
          type: QuestType.daily,
          status: QuestStatus.completed,
          completedAt: d,
        ),
        Quest(
          title: 'b',
          description: '',
          type: QuestType.daily,
          status: QuestStatus.active,
          completedAt: d,
        ),
        Quest(
          title: 'c',
          description: '',
          type: QuestType.weekly,
          status: QuestStatus.completed,
          completedAt: d,
        ),
      ];
      final m = aggregateCompletedDailyQuestsByDay(quests);
      expect(m.length, 1);
      expect(m['2025-03-15'], 1);
    });

    test('несколько квестов в один день суммируются', () {
      final day = DateTime(2025, 1, 1);
      final quests = List.generate(
        3,
        (i) => Quest(
          title: 'q$i',
          description: '',
          type: QuestType.daily,
          status: QuestStatus.completed,
          completedAt: day.add(Duration(hours: i)),
        ),
      );
      final m = aggregateCompletedDailyQuestsByDay(quests);
      expect(m['2025-01-01'], 3);
    });
  });

  group('buildHeatmapYearColumns', () {
    test('возвращает непустой список колонок', () {
      final cols = buildHeatmapYearColumns(
        countsByDay: const {},
        referenceDate: DateTime(2025, 6, 1),
      );
      expect(cols, isNotEmpty);
      for (final w in cols) {
        expect(w.length, 7);
      }
    });
  });
}
