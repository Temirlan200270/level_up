/// Определяет цвет рамки и редкость выпадения.
enum ItemRarity { common, rare, epic, legendary, mythic }

/// Определяет поведение предмета (можно использовать, надеть или только продать).
enum ItemType { consumable, equipment, material, runestone }

/// Активные требуют нажатия, пассивные работают всегда.
enum SkillType { active, passive }
