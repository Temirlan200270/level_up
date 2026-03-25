
import 'package:flutter/material.dart';

// Цветовая палитра в стиле Solo Leveling
class SoloLevelingColors {
  // Основные цвета
  static const Color background = Color(0xFF0A0A0F);        // Тёмный фон
  static const Color surface = Color(0xFF1A1A2E);           // Поверхности
  static const Color surfaceLight = Color(0xFF2A2A3E);     // Светлые поверхности
  
  // Неоновые акценты
  static const Color neonBlue = Color(0xFF00D9FF);         // Голубой неон
  static const Color neonPurple = Color(0xFF9D00FF);       // Фиолетовый неон
  static const Color neonPink = Color(0xFFFF00D9);        // Розовый неон
  static const Color neonGreen = Color(0xFF00FF9D);        // Зелёный неон
  
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
        side: const BorderSide(
          color: SoloLevelingColors.neonBlue,
          width: 1,
        ),
      ),
    ),
    
    // Кнопки
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SoloLevelingColors.neonBlue,
        foregroundColor: SoloLevelingColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
    iconTheme: const IconThemeData(
      color: SoloLevelingColors.neonBlue,
    ),
  );
}
