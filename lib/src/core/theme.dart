import 'package:flutter/material.dart';
import 'rpg_theme_tokens_extension.dart';
import 'system_visuals_extension.dart';

// Цветовая палитра в стиле Solo Leveling
class SoloLevelingColors {
  // Основные цвета
  static const Color background = Color(0xFF0A0A0F); // Тёмный фон
  static const Color surface = Color(0xFF1A1A2E); // Поверхности
  static const Color surfaceLight = Color(0xFF2A2A3E); // Светлые поверхности

  // Неоновые акценты
  static const Color neonBlue = Color(0xFF00D9FF); // Голубой неон
  static const Color neonPurple = Color(0xFF9D00FF); // Фиолетовый неон
  static const Color neonPink = Color(0xFFFF00D9); // Розовый неон
  static const Color neonGreen = Color(0xFF00FF9D); // Зелёный неон

  // Статусы
  static const Color success = neonGreen;
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF0044);

  // Текст
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
}

class AppTheme {
  // Только тёмная тема для Solo Leveling
  static final dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    // Цветовая схема
    colorScheme: const ColorScheme.dark(
      primary: SoloLevelingColors.neonBlue,
      secondary: SoloLevelingColors.neonPurple,
      tertiary: SoloLevelingColors.neonPink,
      surface: SoloLevelingColors.surface,
      error: SoloLevelingColors.error,
    ),

    // Фон приложения
    scaffoldBackgroundColor: SoloLevelingColors.background,

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: SoloLevelingColors.surface,
      foregroundColor: SoloLevelingColors.textPrimary,
      titleTextStyle: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Карточки
    cardTheme: CardThemeData(
      color: SoloLevelingColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SoloLevelingColors.neonBlue, width: 1),
      ),
    ),

    // Кнопки
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SoloLevelingColors.neonBlue,
        foregroundColor: SoloLevelingColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Текст
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: SoloLevelingColors.textSecondary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: SoloLevelingColors.textSecondary,
        fontSize: 14,
      ),
    ),

    // Иконки
    iconTheme: const IconThemeData(color: SoloLevelingColors.neonBlue),

    // RPG-визуальные токены (используются для свечения редкости).
    extensions: const <ThemeExtension<dynamic>>[
      RpgThemeTokens(
        rarityCommon: SoloLevelingColors.textTertiary,
        rarityRare: SoloLevelingColors.neonBlue,
        rarityEpic: SoloLevelingColors.neonPurple,
        rarityLegendary: SoloLevelingColors.warning,
        rarityMythic: SoloLevelingColors.neonPink,
      ),
      SystemVisuals(
        backgroundKind: SystemBackgroundKind.grid,
        backgroundAssetPath: 'assets/backgrounds/solo_bg.svg',
        particlesKind: SystemParticlesKind.sparkles,
        panelRadius: 12,
        panelBorderWidth: 1,
        titleLetterSpacing: 2.2,
      ),
    ],
  );

  /// Тёплая «культивационная» палитра.
  static const Color _cultGold = Color(0xFFC9A227);
  static const Color _cultBrown = Color(0xFF8B5A2B);
  static const Color _cultBg = Color(0xFF1C1810);
  static const Color _cultSurface = Color(0xFF2A2418);

  static final cultivation = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _cultGold,
      secondary: _cultBrown,
      tertiary: Color(0xFFE8D5A3),
      surface: _cultSurface,
      error: SoloLevelingColors.error,
    ),
    scaffoldBackgroundColor: _cultBg,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _cultSurface,
      foregroundColor: SoloLevelingColors.textPrimary,
      titleTextStyle: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: _cultSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _cultGold, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _cultGold,
        foregroundColor: _cultBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: dark.textTheme,
    iconTheme: const IconThemeData(color: _cultGold),

    extensions: const <ThemeExtension<dynamic>>[
      RpgThemeTokens(
        rarityCommon: SoloLevelingColors.textTertiary,
        rarityRare: _cultGold,
        rarityEpic: _cultBrown,
        rarityLegendary: Color(0xFFE8D5A3),
        rarityMythic: SoloLevelingColors.neonPink,
      ),
      SystemVisuals(
        backgroundKind: SystemBackgroundKind.mist,
        backgroundAssetPath: 'assets/backgrounds/cultivation_bg.svg',
        particlesKind: SystemParticlesKind.petals,
        panelRadius: 16,
        panelBorderWidth: 1,
        titleLetterSpacing: 1.8,
      ),
    ],
  );

  /// Фиолетовая тема «архимага».
  static const Color _archPrimary = Color(0xFFB388FF);
  static const Color _archSecondary = Color(0xFF7C4DFF);
  static const Color _archBg = Color(0xFF0D0A14);
  static const Color _archSurface = Color(0xFF1A1524);

  static final archmage = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _archPrimary,
      secondary: _archSecondary,
      tertiary: Color(0xFFEA80FC),
      surface: _archSurface,
      error: SoloLevelingColors.error,
    ),
    scaffoldBackgroundColor: _archBg,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _archSurface,
      foregroundColor: SoloLevelingColors.textPrimary,
      titleTextStyle: TextStyle(
        color: SoloLevelingColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: _archSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _archPrimary, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _archPrimary,
        foregroundColor: _archBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: dark.textTheme,
    iconTheme: const IconThemeData(color: _archPrimary),

    extensions: const <ThemeExtension<dynamic>>[
      RpgThemeTokens(
        rarityCommon: SoloLevelingColors.textTertiary,
        rarityRare: _archPrimary,
        rarityEpic: _archSecondary,
        rarityLegendary: Color(0xFFEA80FC),
        rarityMythic: SoloLevelingColors.neonPink,
      ),
      SystemVisuals(
        backgroundKind: SystemBackgroundKind.parchment,
        backgroundAssetPath: 'assets/backgrounds/archmage_bg.svg',
        particlesKind: SystemParticlesKind.runes,
        panelRadius: 14,
        panelBorderWidth: 1,
        titleLetterSpacing: 2.0,
      ),
    ],
  );

  /// Тема по идентификатору скина (совпадает с `assets/themes/*.json`).
  static ThemeData forSkinId(String id) {
    switch (id) {
      case 'cultivation':
        return cultivation;
      case 'archmage':
        return archmage;
      case 'solo':
      default:
        return dark;
    }
  }
}
