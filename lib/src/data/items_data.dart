import '../models/item_model.dart';
import '../models/enums.dart';

// Список всех предметов, доступных в игре, на основе плана разработки
final List<Item> allGameItems = [
  // === МАТЕРИАЛЫ ===
  Item(
    id: 'mat_wolf_fang',
    name: 'Клык Волка',
    description: 'Острый клык. Можно продать в магазин.',
    type: ItemType.material,
    rarity: ItemRarity.common,
    buyPrice: 0, // Не покупается, только дроп
    iconPath: 'assets/icons/icon_wolf_fang.png',
    slot: null,
    effects: {'sellPrice': 10},
  ),

  // === РАСХОДНИКИ ===
  Item(
    id: 'pot_heal_streak',
    name: 'Зелье Восстановления Статуса',
    description: 'Восстанавливает потерянный стрик задач.',
    type: ItemType.consumable,
    rarity: ItemRarity.rare,
    buyPrice: 500,
    iconPath: 'assets/icons/icon_potion.png',
    slot: null,
    effects: {'restore_streak': true},
  ),
  Item(
    id: 'scroll_double_xp',
    name: 'Свиток Мудрости',
    description: 'Удваивает опыт на следующий час.',
    type: ItemType.consumable,
    rarity: ItemRarity.epic,
    buyPrice: 2000,
    iconPath: 'assets/icons/icon_potion.png',
    slot: null,
    effects: {'xp_multiplier_2x': 2.0, 'duration': 3600},
  ),

  // === ЭКИПИРОВКА ===
  Item(
    id: 'wep_dagger_c',
    name: 'Убийца Рыцарей',
    description: '+10% к опыту за сложные задачи.',
    type: ItemType.equipment,
    rarity: ItemRarity.epic,
    buyPrice: 5000,
    iconPath: 'assets/icons/icon_dagger.png',
    slot: 'weapon',
    effects: {'xp_hard_quest': 0.1},
  ),
  Item(
    id: 'potion_heal',
    name: 'Зелье Исцеления',
    description: 'Восстанавливает стрик задач.',
    type: ItemType.consumable,
    rarity: ItemRarity.common,
    buyPrice: 500,
    iconPath: 'assets/icons/icon_potion.png',
    slot: null,
    effects: {'restore_streak': true},
  ),
  Item(
    id: 'dagger_basic',
    name: 'Кинжал Е-ранга',
    description: '+5% к опыту.',
    type: ItemType.equipment,
    rarity: ItemRarity.rare,
    buyPrice: 2000,
    iconPath: 'assets/icons/icon_dagger.png',
    slot: 'weapon',
    effects: {'xp_bonus': 0.05},
  ),
  Item(
    id: 'acc_scholar_ring',
    name: 'Кольцо учёного',
    description: '+3 к интеллекту (отображается в сумме статов).',
    type: ItemType.equipment,
    rarity: ItemRarity.epic,
    buyPrice: 3500,
    iconPath: 'assets/icons/icon_dagger.png',
    slot: 'accessory',
    effects: {'stat_intelligence': 3},
  ),
];
