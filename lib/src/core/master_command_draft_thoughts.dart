/// Ключ l10n для [MasterThoughts] по черновику командной строки (observer effect).
String? masterCommandDraftThoughtKey(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;

  if (s.contains('бег') ||
      s.contains('run') ||
      s.contains('кардио') ||
      s.contains('cardio') ||
      s.contains('тренир') ||
      s.contains('зал') ||
      s.contains('йог') ||
      s.contains('yoga') ||
      s.contains('sport') ||
      s.contains('спорт') ||
      s.contains('плаван')) {
    return 'master_thought_typing_physical';
  }
  if (s.contains('изуч') ||
      s.contains('learn') ||
      s.contains('study') ||
      s.contains('книг') ||
      s.contains('book') ||
      s.contains('read') ||
      s.contains('учеб') ||
      s.contains('курс') ||
      s.contains('course')) {
    return 'master_thought_typing_mind';
  }
  if (s.contains('код') ||
      s.contains('code') ||
      s.contains('dev') ||
      s.contains('програм') ||
      s.contains('debug') ||
      s.contains('git')) {
    return 'master_thought_typing_code';
  }
  return null;
}
