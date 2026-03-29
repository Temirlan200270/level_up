class OnboardingPersona {
  const OnboardingPersona({
    required this.name,
    required this.strengths,
    required this.weaknesses,
    required this.selfRole,
    required this.interests,
    required this.goal,
  });

  final String name;
  final String strengths;
  final String weaknesses;
  final String selfRole;
  final List<String> interests;
  final String goal;

  Map<String, dynamic> toMap() => {
        'name': name,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'selfRole': selfRole,
        'interests': interests,
        'goal': goal,
      };

  static OnboardingPersona? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final name = (m['name'] as String?)?.trim() ?? '';
    final strengths = (m['strengths'] as String?)?.trim() ?? '';
    final weaknesses = (m['weaknesses'] as String?)?.trim() ?? '';
    final selfRole = (m['selfRole'] as String?)?.trim() ?? '';
    final goal = (m['goal'] as String?)?.trim() ?? '';
    final interestsRaw = m['interests'];
    final interests = interestsRaw is List
        ? interestsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    if (name.isEmpty &&
        strengths.isEmpty &&
        weaknesses.isEmpty &&
        selfRole.isEmpty &&
        goal.isEmpty &&
        interests.isEmpty) {
      return null;
    }
    return OnboardingPersona(
      name: name,
      strengths: strengths,
      weaknesses: weaknesses,
      selfRole: selfRole.isNotEmpty ? selfRole : name,
      interests: interests,
      goal: goal,
    );
  }
}

class OnboardingQuestSeed {
  const OnboardingQuestSeed({
    required this.title,
    required this.description,
    required this.tags,
    required this.difficulty,
    required this.exp,
    required this.gold,
    required this.statPoints,
    required this.mandatory,
  });

  final String title;
  final String description;
  final List<String> tags;
  final int difficulty;
  final int exp;
  final int gold;
  final int statPoints;
  final bool mandatory;

  static OnboardingQuestSeed fromMap(Map<String, dynamic> map) {
    String s(String k, {String fallback = ''}) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return fallback;
    }

    int i(String k, {int fallback = 0}) {
      final v = map[k];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? fallback;
      return fallback;
    }

    bool b(String k, {bool fallback = false}) {
      final v = map[k];
      if (v is bool) return v;
      if (v is String) return v.trim().toLowerCase() == 'true';
      return fallback;
    }

    final tagsRaw = map['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];

    return OnboardingQuestSeed(
      title: s('title'),
      description: s('description'),
      tags: tags,
      difficulty: i('difficulty', fallback: 2).clamp(1, 5),
      exp: i('exp', fallback: 20).clamp(1, 9999),
      gold: i('gold', fallback: 10).clamp(0, 999999),
      statPoints: i('stat_points', fallback: 0).clamp(0, 50),
      mandatory: b('mandatory', fallback: false),
    );
  }
}

class OnboardingAiResult {
  const OnboardingAiResult({
    required this.hiddenClass,
    required this.hiddenClassReason,
    required this.quests,
  });

  final String hiddenClass;
  final String hiddenClassReason;
  final List<OnboardingQuestSeed> quests;
}

