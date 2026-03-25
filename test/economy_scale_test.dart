import 'package:expense_tracker_flutter/src/core/economy_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scaledQuestGoldReward растёт с уровнем', () {
    expect(EconomyScale.scaledQuestGoldReward(100, 1), 100);
    expect(EconomyScale.scaledQuestGoldReward(100, 10), greaterThan(100));
  });

  test('scaleLootGold не опускается ниже 1 при малых базах', () {
    expect(EconomyScale.scaleLootGold(1, 99), greaterThanOrEqualTo(1));
  });

  test('scaledShopBuyPrice растёт с уровнем', () {
    expect(EconomyScale.scaledShopBuyPrice(100, 1), 100);
    expect(EconomyScale.scaledShopBuyPrice(100, 20), greaterThan(100));
  });

  test('scaledShopSellUnitPrice растёт слабее покупки', () {
    expect(EconomyScale.scaledShopSellUnitPrice(50, 1), 50);
    expect(EconomyScale.scaledShopSellUnitPrice(50, 20), greaterThan(50));
    expect(
      EconomyScale.scaledShopSellUnitPrice(100, 10),
      lessThan(EconomyScale.scaledShopBuyPrice(100, 10)),
    );
  });
}
