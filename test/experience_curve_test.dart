import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_flutter/src/core/experience_curve.dart';

void main() {
  group('ExperienceCurve', () {
    test('уровень 1 совпадает с MVP (100)', () {
      expect(ExperienceCurve.maxExperienceForLevel(1), 100.0);
    });

    test('рост экспоненциальный: уровень 2 > 100', () {
      expect(ExperienceCurve.maxExperienceForLevel(2), greaterThan(100.0));
    });

    test('legacyLinearMaxForLevel соответствует level * 100', () {
      expect(ExperienceCurve.legacyLinearMaxForLevel(5), 500.0);
    });

    test('matchesLegacyLinear узнаёт старый порог', () {
      expect(ExperienceCurve.matchesLegacyLinear(500, 5), isTrue);
      expect(ExperienceCurve.matchesLegacyLinear(400, 5), isFalse);
    });
  });
}
