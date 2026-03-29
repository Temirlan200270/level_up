import 'package:flutter/foundation.dart';

@immutable
class TitleDef {
  final String id;
  final String name;
  final String description;
  final String rarity; // 'common', 'rare', 'epic', 'legendary'
  
  /// Эффекты, аналогично item.effects
  /// Например: {'xp_bonus': 0.1, 'stat_strength': 5}
  final Map<String, dynamic> effects;
  
  /// Скрытый ли титул (не показывается в списке до получения)
  final bool isHidden;

  const TitleDef({
    required this.id,
    required this.name,
    required this.description,
    this.rarity = 'common',
    this.effects = const {},
    this.isHidden = false,
  });
}
