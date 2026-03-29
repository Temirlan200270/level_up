import '../../core/systems/system_id.dart';
import '../../core/systems/system_rules.dart';
import '../../core/systems/systems_catalog.dart';
import '../database_service.dart';

/// Системные промпты для генерации данжей (EN — стабильнее для логики и JSON).
abstract final class DungeonGenerationPrompts {
  /// Правила активной системы без Riverpod (диалог данжа).
  static SystemRules resolveActiveSystemRules() {
    final id = SystemId.fromValue(DatabaseService.getActiveSystemId());
    if (id != SystemId.custom) {
      return SystemsCatalog.rulesForId(id);
    }
    final slug = DatabaseService.getActiveCustomSystemSlug();
    final presetRaw = DatabaseService.getCustomSystemRulesPresetForSlug(slug);
    final base = switch (presetRaw) {
      'solo' => const SoloRules(),
      'mage' => const MageRules(),
      'cultivator' => const CultivatorRules(),
      _ => const SoloRules(),
    };
    return CustomRules(
      base: base,
      userPrompt: DatabaseService.getCustomSystemAiUserPromptForSlug(slug),
    );
  }

  /// Короткая метка философии для поля Role (навигационная ветка).
  static String philosophyRoleLabel(SystemId navId) {
    return switch (navId) {
      SystemId.solo => 'Solo',
      SystemId.mage => 'Mage',
      SystemId.cultivator => 'Cultivator',
      SystemId.custom => 'Solo',
    };
  }

  /// Атмосфера для `{philosophy_tone}` (EN, как в спецификации).
  static String philosophyTone(SystemId navId) {
    return switch (navId) {
      SystemId.solo =>
        'Cold, digital, monarch style, urgent.',
      SystemId.mage =>
        'Ancient, arcane, mysterious, academic.',
      SystemId.cultivator =>
        'Poetic, stoic, dao-focused, spiritual.',
      SystemId.custom =>
        'Cold, digital, monarch style, urgent.',
    };
  }

  static String _responseLanguageName(String code) {
    switch (code.trim().toLowerCase()) {
      case 'ru':
        return 'Russian';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  /// System prompt: жёсткая схема JSON, без лишней прозы.
  static String systemPrompt({
    required int stagesCount,
    required int difficultyTier,
    required String philosophy,
    required String philosophyToneLine,
    required String languageCode,
    required int hunterLevel,
  }) {
    final lang = _responseLanguageName(languageCode);
    final diff = difficultyTier.clamp(1, 10);
    return '''
Role: $philosophy RPG Game Master.
Task: Generate a $stagesCount-stage Dungeon JSON for the goal the user will send next.
Difficulty: $diff/10.
Rules: Strict JSON only. No prose before or after. No markdown. Tone: $philosophyToneLine
Response Language: $lang (all strings in JSON values must be in $lang).
Schema:
{"title":"str","description":"str","stages":[{"title":"str","desc":"str","difficulty":int,"exp":int,"gold":int}]}

Hard constraints:
- "stages" must have exactly $stagesCount objects.
- Each stage: difficulty integer 1-10; exp and gold positive integers scaled to hunter level ~$hunterLevel and stage order (later stages may be slightly harder/richer).
- Content: real-life achievable steps toward the goal; failing any stage closes the Gates (the whole dungeon chain).
'''.trim();
  }

  /// Короткое пользовательское сообщение (цель + контекст).
  static String userPrompt({
    required String goal,
    required int hunterLevel,
  }) {
    return 'Goal: "$goal"\nHunter level: $hunterLevel\nOutput JSON only.';
  }
}
