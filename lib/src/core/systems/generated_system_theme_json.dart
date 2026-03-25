import 'package:flutter/material.dart';

/// Модель “JSON-схемы системы/темы” для AI-конструктора.
/// Важно: приложение пока использует терминологию (dictionary) и rules preset,
/// а цвета/токены будут применяться на следующем шаге (ThemeExtension).
class GeneratedSystemThemeJson {
  final String systemId;
  final String themeName;
  final GeneratedTerminology terminology;
  final GeneratedColors colors;
  final String aiPrompt;
  final String rulesPreset;

  const GeneratedSystemThemeJson({
    required this.systemId,
    required this.themeName,
    required this.terminology,
    required this.colors,
    required this.aiPrompt,
    required this.rulesPreset,
  });

  static GeneratedSystemThemeJson fromMap(Map<String, dynamic> map) {
    String getString(String key, {String fallback = ''}) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return fallback;
    }

    final terminologyRaw = map['terminology'];
    if (terminologyRaw is! Map) {
      throw FormatException('terminology must be an object');
    }
    final terminology = GeneratedTerminology.fromMap(
      Map<String, dynamic>.from(terminologyRaw),
    );

    final colorsRaw = map['colors'];
    if (colorsRaw is! Map) {
      throw FormatException('colors must be an object');
    }
    final colors = GeneratedColors.fromMap(
      Map<String, dynamic>.from(colorsRaw),
    );

    return GeneratedSystemThemeJson(
      systemId: getString('system_id', fallback: 'custom_unknown'),
      themeName: getString('theme_name', fallback: 'Untitled'),
      terminology: terminology,
      colors: colors,
      aiPrompt: getString('ai_prompt'),
      rulesPreset: getString('rules_preset', fallback: 'balanced'),
    );
  }
}

class GeneratedTerminology {
  final String expName;
  final String levelName;
  final String currencyName;
  final String spName;
  final String systemName;

  const GeneratedTerminology({
    required this.expName,
    required this.levelName,
    required this.currencyName,
    required this.spName,
    required this.systemName,
  });

  static GeneratedTerminology fromMap(Map<String, dynamic> map) {
    String pick(String key, {String fallback = ''}) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return fallback;
    }

    return GeneratedTerminology(
      expName: pick('exp', fallback: 'Опыт'),
      levelName: pick('level', fallback: 'Уровень'),
      currencyName: pick('currency', fallback: 'Золото'),
      spName: pick('sp', fallback: 'Очки навыков'),
      systemName: pick('system', fallback: 'Система'),
    );
  }
}

class GeneratedColors {
  final Color background;
  final Color primary;
  final Color surface;
  final Color glow;

  const GeneratedColors({
    required this.background,
    required this.primary,
    required this.surface,
    required this.glow,
  });

  static Color _parseHex(String raw) {
    var v = raw.trim();
    if (v.startsWith('#')) v = v.substring(1);
    if (v.length == 6) v = 'FF$v';
    if (v.length != 8) {
      throw FormatException('Invalid hex color: $raw');
    }
    return Color(int.parse(v, radix: 16));
  }

  static GeneratedColors fromMap(Map<String, dynamic> map) {
    final bg = map['background_hex'];
    final primary = map['primary_hex'];
    final surface = map['surface_hex'];
    final glow = map['glow_hex'] ?? map['accent_hex'];

    if (bg is! String || primary is! String || surface is! String || glow is! String) {
      throw FormatException('colors.*_hex must be strings');
    }

    return GeneratedColors(
      background: _parseHex(bg),
      primary: _parseHex(primary),
      surface: _parseHex(surface),
      glow: _parseHex(glow),
    );
  }
}

