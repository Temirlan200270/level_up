import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'providers.dart';

/// Сервис для работы с переводами
class TranslationService {
  static Map<String, dynamic> translations = {};
  static String _currentLanguage = 'ru';

  /// Загружает переводы для указанного языка
  static Future<void> loadTranslations(String language) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/$language.json',
      );
      translations = json.decode(jsonString) as Map<String, dynamic>;
      _currentLanguage = language;
    } catch (e) {
      // Если не удалось загрузить, используем русский по умолчанию
      if (language != 'ru') {
        await loadTranslations('ru');
      } else {
        translations = {};
      }
    }
  }

  /// Получает перевод по ключу
  static String translate(String key, {Map<String, String>? params}) {
    final value = translations[key] as String?;
    if (value == null) {
      return key; // Возвращаем ключ, если перевод не найден
    }

    if (params != null) {
      String result = value;
      params.forEach((key, val) {
        result = result.replaceAll('{$key}', val);
      });
      return result;
    }

    return value;
  }

  /// Получает текущий язык
  static String get currentLanguage => _currentLanguage;

  /// Инициализирует переводы при старте приложения
  static Future<void> init() async {
    final language = DatabaseService.getLanguage();
    await loadTranslations(language);
  }
}

/// Провайдер для переводов
final translationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final language = ref.watch(languageProvider);
  await TranslationService.loadTranslations(language);
  return TranslationService.translations;
});

/// Провайдер для функции перевода
final translateProvider = Provider<String Function(String, {Map<String, String>? params})>((ref) {
  ref.watch(translationsProvider); // Следим за изменениями переводов
  return (String key, {Map<String, String>? params}) {
    return TranslationService.translate(key, params: params);
  };
});

