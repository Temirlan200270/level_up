import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';

/// Расширение для удобного использования переводов в виджетах
extension TranslationsExtension on WidgetRef {
  /// Получает функцию перевода
  String Function(String, {Map<String, String>? params}) get t {
    watch(translationsProvider); // Следим за изменениями переводов
    return (String key, {Map<String, String>? params}) {
      return TranslationService.translate(key, params: params);
    };
  }
}

/// Расширение для ConsumerWidget/ConsumerStatefulWidget
String Function(String, {Map<String, String>? params}) useTranslations(WidgetRef ref) {
  ref.watch(translationsProvider); // Следим за изменениями переводов
  return (String key, {Map<String, String>? params}) {
    return TranslationService.translate(key, params: params);
  };
}

