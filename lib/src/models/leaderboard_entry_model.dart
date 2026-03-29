import 'public_profile_model.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.place,
    required this.profile,
    required this.score,
    required this.scoreLabelKey,
    this.opensFriendProfile = true,
  });

  final int place;
  final PublicProfile profile;
  final int score;

  /// Ключ строки перевода для подписи к счёту (например `leaderboards_score_label_level`).
  final String scoreLabelKey;

  /// Ложь для строк «гильдия» — не открываем профиль друга.
  final bool opensFriendProfile;
}

