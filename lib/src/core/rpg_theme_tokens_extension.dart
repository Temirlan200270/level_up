import 'package:flutter/material.dart';

/// ThemeExtension с токенами “RPG-визуала”, чтобы UI мог
/// менять палитру под философию, не завязываясь на захардкоженные цвета.
class RpgThemeTokens extends ThemeExtension<RpgThemeTokens> {
  final Color rarityCommon;
  final Color rarityRare;
  final Color rarityEpic;
  final Color rarityLegendary;
  final Color rarityMythic;

  const RpgThemeTokens({
    required this.rarityCommon,
    required this.rarityRare,
    required this.rarityEpic,
    required this.rarityLegendary,
    required this.rarityMythic,
  });

  @override
  RpgThemeTokens copyWith({
    Color? rarityCommon,
    Color? rarityRare,
    Color? rarityEpic,
    Color? rarityLegendary,
    Color? rarityMythic,
  }) {
    return RpgThemeTokens(
      rarityCommon: rarityCommon ?? this.rarityCommon,
      rarityRare: rarityRare ?? this.rarityRare,
      rarityEpic: rarityEpic ?? this.rarityEpic,
      rarityLegendary: rarityLegendary ?? this.rarityLegendary,
      rarityMythic: rarityMythic ?? this.rarityMythic,
    );
  }

  @override
  RpgThemeTokens lerp(ThemeExtension<RpgThemeTokens>? other, double t) {
    if (other is! RpgThemeTokens) return this;
    return RpgThemeTokens(
      rarityCommon: Color.lerp(rarityCommon, other.rarityCommon, t)!,
      rarityRare: Color.lerp(rarityRare, other.rarityRare, t)!,
      rarityEpic: Color.lerp(rarityEpic, other.rarityEpic, t)!,
      rarityLegendary: Color.lerp(rarityLegendary, other.rarityLegendary, t)!,
      rarityMythic: Color.lerp(rarityMythic, other.rarityMythic, t)!,
    );
  }
}

