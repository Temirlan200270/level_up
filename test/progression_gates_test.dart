import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/core/progression_gates.dart';

void main() {
  group('ProgressionGates.canOpenLaboratory', () {
    test('первый выбор философии — доступ без уровня и без вехи', () {
      expect(
        ProgressionGates.canOpenLaboratory(
          hunterLevel: 1,
          philosophyPickerIsFirstRun: true,
          completedStoryGate10: false,
        ),
        isTrue,
      );
    });

    test('не первый запуск — нужен уровень 10+', () {
      expect(
        ProgressionGates.canOpenLaboratory(
          hunterLevel: 9,
          philosophyPickerIsFirstRun: false,
          completedStoryGate10: false,
        ),
        isFalse,
      );
      expect(
        ProgressionGates.canOpenLaboratory(
          hunterLevel: 10,
          philosophyPickerIsFirstRun: false,
          completedStoryGate10: false,
        ),
        isTrue,
      );
    });

    test('не первый запуск — альтернатива: выполнена story_gate_10', () {
      expect(
        ProgressionGates.canOpenLaboratory(
          hunterLevel: 5,
          philosophyPickerIsFirstRun: false,
          completedStoryGate10: true,
        ),
        isTrue,
      );
    });
  });
}
