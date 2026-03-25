import 'dart:math';

import '../models/item_model.dart';
import '../models/enums.dart';

/// Диапазон основного броска дропа (0–100 включительно, см. `Random.nextInt(101)`).
enum LootDropTier {
  /// 0–70: компактное золото.
  goldBand,

  /// 71–90: случайный материал.
  materialBand,

  /// 91–98: расходник.
  consumableBand,

  /// 99–100: экипировка / руна либо крупное золото при пустом пуле.
  equipmentOrFallbackGold,
}

/// Классификация броска для RNG-дропа после квеста (детерминированно от [roll]).
LootDropTier lootTierForRoll(int roll) {
  if (roll <= 70) return LootDropTier.goldBand;
  if (roll <= 90) return LootDropTier.materialBand;
  if (roll <= 98) return LootDropTier.consumableBand;
  return LootDropTier.equipmentOrFallbackGold;
}

/// Бросок 0–100 с бонусом ивента (сдвиг к более редким тирам), не выше 100.
int rollLootWithBonus(Random random, int bonus) {
  final raw = random.nextInt(101) + bonus;
  return raw.clamp(0, 100);
}

/// Золото 10–50 (основная ветка).
int rollLootGoldSmall(Random random) => 10 + random.nextInt(41);

/// Золото 50–100 (запасная ветка при отсутствии экипировки в пуле).
int rollLootGoldLarge(Random random) => 50 + random.nextInt(51);

/// Случайный предмет из списка; для пустого списка — `null`.
Item? pickRandomItem(List<Item> pool, Random random) {
  if (pool.isEmpty) return null;
  return pool[random.nextInt(pool.length)];
}

/// Материалы из каталога.
List<Item> filterMaterials(List<Item> catalog) =>
    catalog.where((i) => i.type == ItemType.material).toList();

/// Расходники из каталога.
List<Item> filterConsumables(List<Item> catalog) =>
    catalog.where((i) => i.type == ItemType.consumable).toList();

/// Экипировка и руны из каталога.
List<Item> filterEquipmentLike(List<Item> catalog) => catalog
    .where(
      (i) =>
          i.type == ItemType.equipment || i.type == ItemType.runestone,
    )
    .toList();
