import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/features/quests/quest_section_grouping.dart';
import 'package:level_up/src/models/quest_model.dart';

Quest _q(QuestType type) => Quest(
      id: '${type.name}_id',
      title: 't',
      description: 'd',
      type: type,
      status: QuestStatus.active,
      experienceReward: 1,
      statPointsReward: 0,
      goldReward: 0,
      tags: const [],
      difficulty: 1,
      mandatory: false,
      createdAt: DateTime.utc(2026),
    );

void main() {
  test('QuestSectionGrouping раскладывает типы по секциям', () {
    final all = [
      _q(QuestType.penalty),
      _q(QuestType.story),
      _q(QuestType.daily),
      _q(QuestType.weekly),
      _q(QuestType.special),
      _q(QuestType.urgent),
    ];

    expect(QuestSectionGrouping.penalty(all), hasLength(1));
    expect(QuestSectionGrouping.story(all), hasLength(1));
    expect(QuestSectionGrouping.daily(all), hasLength(1));
    expect(QuestSectionGrouping.misc(all), hasLength(3));
  });
}
