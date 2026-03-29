import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/models/dungeon_model.dart';

void main() {
  test('Dungeon.fromMap читает награды этапов из ИИ', () {
    final d = Dungeon.fromMap({
      'title': 'T',
      'description': 'D',
      'stageTitles': ['a', 'b'],
      'stageDescriptions': ['1', '2'],
      'stageDifficulties': [3, 7],
      'stageExpRewards': [40, 50],
      'stageGoldRewards': [20, 30],
      'currentStageIndex': 0,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    });

    expect(d.stageDifficulties, [3, 7]);
    expect(d.stageExpRewards, [40, 50]);
    expect(d.stageGoldRewards, [20, 30]);
  });

  test('Dungeon.fromMap без новых полей — пустые списки', () {
    final d = Dungeon.fromMap({
      'title': 'T',
      'description': 'D',
      'stageTitles': ['a'],
      'stageDescriptions': ['1'],
      'currentStageIndex': 0,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    });

    expect(d.stageDifficulties, isEmpty);
    expect(d.stageExpRewards, isEmpty);
    expect(d.stageGoldRewards, isEmpty);
  });
}
