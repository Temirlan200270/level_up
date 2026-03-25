import 'public_profile_model.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.place,
    required this.profile,
    required this.score,
    required this.scoreLabel,
  });

  final int place;
  final PublicProfile profile;
  final int score;
  final String scoreLabel;
}

