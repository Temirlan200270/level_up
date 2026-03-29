import '../services/translation_service.dart';
import 'systems/system_id.dart';

/// Реплика Мастера после успеха/провала квеста (ключи `quest_success_*` / `quest_fail_*` в JSON).
String pickMasterQuestReactionLine({
  required SystemId systemId,
  required bool success,
  required String seed,
}) {
  final variant = 1 + (seed.hashCode.abs() % 3);
  final sys = switch (systemId) {
    SystemId.solo => 'solo',
    SystemId.mage => 'mage',
    SystemId.cultivator => 'cultivator',
    SystemId.custom => 'solo',
  };
  final prefix = success ? 'quest_success' : 'quest_fail';
  final key = '${prefix}_${sys}_$variant';
  return TranslationService.translate(key);
}
