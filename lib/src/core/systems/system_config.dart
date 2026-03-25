import 'system_dictionary.dart';
import 'system_id.dart';

class SystemConfig {
  const SystemConfig({
    required this.id,
    required this.dictionary,
    required this.aiVoiceName,
    required this.aiToneHint,
  });

  final SystemId id;
  final SystemDictionary dictionary;

  /// Отображаемое имя “голоса” (для UI/будущих промптов).
  final String aiVoiceName;

  /// Короткая подсказка по тону (будет использоваться в AIService позже).
  final String aiToneHint;
}

