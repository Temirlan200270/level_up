import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'theme.dart';
import 'rpg_theme_tokens_extension.dart';

/// Цвета и свечение редкости в стиле темы приложения.
class ItemRarityStyle {
  ItemRarityStyle._();

  static Color color(
    ItemRarity rarity, {
    ThemeData? theme,
  }) {
    final ext = theme?.extension<RpgThemeTokens>();
    if (ext != null) {
      switch (rarity) {
        case ItemRarity.common:
          return ext.rarityCommon;
        case ItemRarity.rare:
          return ext.rarityRare;
        case ItemRarity.epic:
          return ext.rarityEpic;
        case ItemRarity.legendary:
          return ext.rarityLegendary;
        case ItemRarity.mythic:
          return ext.rarityMythic;
      }
    }

    switch (rarity) {
      case ItemRarity.common:
        return SoloLevelingColors.textTertiary;
      case ItemRarity.rare:
        return SoloLevelingColors.neonBlue;
      case ItemRarity.epic:
        return SoloLevelingColors.neonPurple;
      case ItemRarity.legendary:
        return SoloLevelingColors.warning;
      case ItemRarity.mythic:
        return SoloLevelingColors.neonPink;
    }
  }

  /// Мягкое свечение; для common — пусто.
  static List<BoxShadow> glow(
    ItemRarity rarity, {
    ThemeData? theme,
  }) {
    final c = color(rarity, theme: theme);
    switch (rarity) {
      case ItemRarity.common:
        return [];
      case ItemRarity.rare:
        return [
          BoxShadow(
            color: c.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ];
      case ItemRarity.epic:
        return [
          BoxShadow(
            color: c.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ];
      case ItemRarity.legendary:
        return [
          BoxShadow(
            color: c.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: SoloLevelingColors.warning.withValues(alpha: 0.2),
            blurRadius: 22,
          ),
        ];
      case ItemRarity.mythic:
        return [
          BoxShadow(
            color: c.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: SoloLevelingColors.neonPink.withValues(alpha: 0.25),
            blurRadius: 26,
          ),
        ];
    }
  }

  /// Подогнан под строки из `_getRarityName` (квесты / дроп).
  static Color colorFromLabel(String? label) {
    if (label == null || label.isEmpty) {
      return SoloLevelingColors.neonBlue;
    }
    final l = label.toLowerCase();
    if (l.contains('обыч')) return color(ItemRarity.common);
    if (l.contains('редк')) return color(ItemRarity.rare);
    if (l.contains('эпич')) return color(ItemRarity.epic);
    if (l.contains('леген')) return color(ItemRarity.legendary);
    if (l.contains('миф')) return color(ItemRarity.mythic);
    return SoloLevelingColors.neonBlue;
  }
}
