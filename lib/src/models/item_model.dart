import 'enums.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final int buyPrice;
  final String iconPath;
  final String? slot; // weapon, armor, accessory
  final Map<String, dynamic>? effects;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.buyPrice,
    required this.iconPath,
    this.slot,
    this.effects,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'rarity': rarity.index,
      'iconPath': iconPath,
      'buyPrice': buyPrice,
      'slot': slot,
      'effects': effects,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: ItemType.values[map['type']],
      rarity: ItemRarity.values[map['rarity']],
      iconPath: map['iconPath'],
      buyPrice: map['buyPrice'] ?? 0, // Добавлено для обратной совместимости
      slot: map['slot'],
      effects: Map<String, dynamic>.from(map['effects']),
    );
  }
}
