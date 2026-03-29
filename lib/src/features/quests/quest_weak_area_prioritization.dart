import '../../core/systems/system_id.dart';
import '../../models/hunter_model.dart';
import '../../models/quest_model.dart';
import '../../services/evaluators/adaptive_difficulty_service.dart';
import '../onboarding/onboarding_models.dart';

/// Сортировка активных квестов: вверху то, что ближе к «слабым зонам» онбординга и низким статам;
/// учитывается локальная калибровка сложности ([AdaptiveDifficultyService]).
abstract final class QuestWeakAreaPrioritization {
  static const int _adaptiveLookbackDays = 14;

  static final RegExp _splitRe =
      RegExp(r'[^0-9a-zA-Zа-яА-ЯёЁ_]+', unicode: true);

  /// Ключевые подстроки по стата́м (RU/EN) — пересечение с текстом квеста.
  static const Map<String, List<String>> _statHints = {
    'strength': [
      'сила',
      'силу',
      'желез',
      'спорт',
      'тело',
      'качал',
      'гиря',
      'штанг',
      'отжим',
      'присед',
      'physical',
      'strength',
      'gym',
      'muscle',
      'lift',
    ],
    'agility': [
      'ловкость',
      'бег',
      'cardio',
      'гибкост',
      'скорост',
      'растяж',
      'agility',
      'run',
      'jog',
      'yoga',
      'stretch',
    ],
    'intelligence': [
      'интеллект',
      'книг',
      'учёб',
      'учеб',
      'код',
      'code',
      'алгоритм',
      'study',
      'learn',
      'read',
      'course',
    ],
    'vitality': [
      'живучест',
      'сон',
      'отдых',
      'здоров',
      'вода',
      'дыхан',
      'vitality',
      'sleep',
      'meditat',
      'walk',
      'recovery',
    ],
  };

  static List<Quest> sort(
    List<Quest> quests, {
    Hunter? hunter,
    OnboardingPersona? persona,
    AdaptiveDifficultyEvaluation? adaptive,
    SystemId? systemId,
  }) {
    if (quests.length <= 1) return List<Quest>.from(quests);
    final eval = adaptive ??
        AdaptiveDifficultyService.evaluate(
          _adaptiveLookbackDays,
          systemId: systemId,
        );
    final personaTokens = _personaSearchTerms(persona);
    final statTerms = _lowStatTerms(hunter);
    final sorted = List<Quest>.from(quests);
    sorted.sort((a, b) => _compare(a, b, personaTokens, statTerms, eval));
    return sorted;
  }

  static int _compare(
    Quest a,
    Quest b,
    Set<String> personaTerms,
    Set<String> statTerms,
    AdaptiveDifficultyEvaluation eval,
  ) {
    final sa = _scoreQuest(a, personaTerms, statTerms);
    final sb = _scoreQuest(b, personaTerms, statTerms);
    if (sa != sb) return sb.compareTo(sa);

    // Калибровка сложности (как в плане — через AdaptiveDifficulty).
    switch (eval.status) {
      case AdaptiveDifficultyStatus.tooEasy:
        final cEasy = b.difficulty.compareTo(a.difficulty);
        if (cEasy != 0) return cEasy;
        break;
      case AdaptiveDifficultyStatus.tooHard:
        final cHard = a.difficulty.compareTo(b.difficulty);
        if (cHard != 0) return cHard;
        break;
      case AdaptiveDifficultyStatus.balanced:
        break;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  static int _scoreQuest(
    Quest q,
    Set<String> personaTerms,
    Set<String> statTerms,
  ) {
    final blob = _questBlob(q);
    var s = 0;
    for (final t in personaTerms) {
      if (blob.contains(t)) s += 3;
    }
    for (final t in statTerms) {
      if (blob.contains(t)) s += 2;
    }
    // Намёк на целевой стат из тегов/описаний движка.
    for (final tag in q.tags) {
      final low = tag.toLowerCase();
      if (low.contains('stat_strength') || low.contains('str_')) s += 2;
      if (low.contains('stat_agility') || low.contains('agi_')) s += 2;
      if (low.contains('stat_intelligence') || low.contains('int_')) s += 2;
      if (low.contains('stat_vitality') || low.contains('vit_')) s += 2;
    }
    return s;
  }

  static String _questBlob(Quest q) {
    final parts = <String>[
      q.title,
      q.description,
      ...q.tags,
    ];
    return parts.join(' ').toLowerCase();
  }

  static Set<String> _personaSearchTerms(OnboardingPersona? p) {
    if (p == null) return {};
    final buf = StringBuffer()
      ..write(p.weaknesses)
      ..write(' ')
      ..write(p.goal)
      ..write(' ')
      ..write(p.selfRole)
      ..write(' ')
      ..write(p.strengths);
    for (final i in p.interests) {
      buf.write(' ');
      buf.write(i);
    }
    return _tokens(buf.toString());
  }

  static Set<String> _tokens(String raw) {
    final out = <String>{};
    for (final part in raw.toLowerCase().split(_splitRe)) {
      final t = part.trim();
      if (t.length >= 3) out.add(t);
    }
    return out;
  }

  static Set<String> _lowStatTerms(Hunter? h) {
    if (h == null) return {};
    final s = h.stats;
    final values = {
      'strength': s.strength,
      'agility': s.agility,
      'intelligence': s.intelligence,
      'vitality': s.vitality,
    };
    final minV = values.values.reduce((a, b) => a < b ? a : b);
    final out = <String>{};
    for (final e in values.entries) {
      if (e.value <= minV + 1) {
        final hints = _statHints[e.key];
        if (hints != null) out.addAll(hints);
      }
    }
    return out;
  }
}
