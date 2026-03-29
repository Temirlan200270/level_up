import 'dart:math';

import 'package:level_up/src/core/loot_drop_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lootTierForRoll', () {
    test('границы диапазонов', () {
      expect(lootTierForRoll(0), LootDropTier.goldBand);
      expect(lootTierForRoll(70), LootDropTier.goldBand);
      expect(lootTierForRoll(71), LootDropTier.materialBand);
      expect(lootTierForRoll(90), LootDropTier.materialBand);
      expect(lootTierForRoll(91), LootDropTier.consumableBand);
      expect(lootTierForRoll(98), LootDropTier.consumableBand);
      expect(lootTierForRoll(99), LootDropTier.equipmentOrFallbackGold);
      expect(lootTierForRoll(100), LootDropTier.equipmentOrFallbackGold);
    });
  });

  group('rollLootGoldSmall', () {
    test('диапазон 10–50', () {
      final r = Random(42);
      for (var i = 0; i < 200; i++) {
        final g = rollLootGoldSmall(r);
        expect(g, inInclusiveRange(10, 50));
      }
    });
  });

  group('rollLootGoldLarge', () {
    test('диапазон 50–100', () {
      final r = Random(7);
      for (var i = 0; i < 200; i++) {
        final g = rollLootGoldLarge(r);
        expect(g, inInclusiveRange(50, 100));
      }
    });
  });

  group('rollLootWithBonus', () {
    test('бонус сдвигает вверх и не превышает 100', () {
      final r = Random(1);
      for (var i = 0; i < 500; i++) {
        final v = rollLootWithBonus(r, 8);
        expect(v, inInclusiveRange(0, 100));
      }
    });

    test('большой бонус даёт верхний тир', () {
      expect(lootTierForRoll(rollLootWithBonus(Random(0), 100)),
          LootDropTier.equipmentOrFallbackGold);
    });
  });
}
