import 'package:expense_tracker_flutter/src/core/monarch_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MonarchMode открывается на 50 уровне', () {
    expect(MonarchMode.isUnlocked(49), isFalse);
    expect(MonarchMode.isUnlocked(50), isTrue);
    expect(MonarchMode.isUnlocked(80), isTrue);
  });
}
