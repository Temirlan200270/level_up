import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/systems/system_id.dart';
import '../models/hunter_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/public_profile_model.dart';
import 'database_service.dart';

/// Сервис социалки.
///
/// Интегрирован с Supabase для глобальных лидербордов и поиска профилей.
class SocialService {
  const SocialService();

  Future<PublicProfile> getMyPublicProfile({Hunter? hunter}) async {
    final handle = DatabaseService.getSocialHandle(fallbackHunter: hunter);
    final parts = handle.split('#');
    final name = parts.isNotEmpty ? parts.first : 'Player';
    final disc = parts.length >= 2 ? parts.last : DatabaseService.getOrCreateSocialDiscriminator();
    return PublicProfile(
      handle: '$name#$disc',
      displayName: name,
      discriminator4: disc,
      activeSystemId: SystemId.fromValue(DatabaseService.getActiveSystemId()),
      level: hunter?.level ?? (DatabaseService.getHunter()?.level ?? 1),
      rank: _rankForLevel(hunter?.level ?? (DatabaseService.getHunter()?.level ?? 1)),
    );
  }

  Future<List<PublicProfile>> searchProfiles(String query, {Hunter? hunter}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final response = await Supabase.instance.client
          .from('public_profiles')
          .select()
          .ilike('handle', '%$q%')
          .limit(20);

      final profiles = (response as List).map((row) {
        final handle = row['handle'] as String;
        final parts = handle.split('#');
        return PublicProfile(
          handle: handle,
          displayName: row['display_name'] ?? parts.first,
          discriminator4: parts.length > 1 ? parts.last : '0000',
          activeSystemId: SystemId.fromValue(row['active_system_id'] as String? ?? 'solo'),
          level: (row['level'] as num?)?.toInt() ?? 1,
          rank: _rankForLevel((row['level'] as num?)?.toInt() ?? 1),
        );
      }).toList();

      return profiles;
    } catch (e) {
      // Фолбэк при отсутствии сети
      final me = await getMyPublicProfile(hunter: hunter);
      if (me.handle.toLowerCase().contains(q.toLowerCase())) {
        return [me];
      }
      return [];
    }
  }

  Future<PublicProfile?> getProfileByHandle(String handle, {Hunter? hunter}) async {
    final q = handle.trim();
    if (q.isEmpty) return null;
    
    try {
      final response = await Supabase.instance.client
          .from('public_profiles')
          .select()
          .eq('handle', q)
          .maybeSingle();
          
      if (response == null) return null;
      
      final parts = q.split('#');
      return PublicProfile(
        handle: response['handle'] as String,
        displayName: response['display_name'] ?? parts.first,
        discriminator4: parts.length > 1 ? parts.last : '0000',
        activeSystemId: SystemId.fromValue(response['active_system_id'] as String? ?? 'solo'),
        level: (response['level'] as num?)?.toInt() ?? 1,
        rank: _rankForLevel((response['level'] as num?)?.toInt() ?? 1),
      );
    } catch (e) {
      // Фолбэк при отсутствии сети
      final me = await getMyPublicProfile(hunter: hunter);
      if (me.handle == q) return me;
      return null;
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    required SocialLeaderboardKind kind,
    Hunter? hunter,
  }) async {
    switch (kind) {
      case SocialLeaderboardKind.level:
        try {
          final response = await Supabase.instance.client
              .from('public_profiles')
              .select()
              .order('level', ascending: false)
              .limit(50);
          final rows = response as List;
          if (rows.isNotEmpty) {
            return _leaderboardEntriesFromSupabaseLevel(rows);
          }
        } catch (_) {}
        return _buildLocalIndividualLeaderboard(kind, hunter);
      case SocialLeaderboardKind.storyQuests:
      case SocialLeaderboardKind.questWins:
      case SocialLeaderboardKind.dailyStreak:
        return _buildLocalIndividualLeaderboard(kind, hunter);
      case SocialLeaderboardKind.guildXp:
      case SocialLeaderboardKind.guildSeason:
        return _buildLocalGuildLeaderboard(kind, hunter);
    }
  }

  List<LeaderboardEntry> _leaderboardEntriesFromSupabaseLevel(List<dynamic> rows) {
    final out = <LeaderboardEntry>[];
    var place = 1;
    for (final row in rows) {
      final m = Map<String, dynamic>.from(row as Map);
      final handle = m['handle'] as String;
      final parts = handle.split('#');
      final level = (m['level'] as num?)?.toInt() ?? 1;
      final p = PublicProfile(
        handle: handle,
        displayName: (m['display_name'] as String?) ?? parts.first,
        discriminator4: parts.length > 1 ? parts.last : '0000',
        activeSystemId:
            SystemId.fromValue(m['active_system_id'] as String? ?? 'solo'),
        level: level,
        rank: _rankForLevel(level),
      );
      out.add(
        LeaderboardEntry(
          place: place++,
          profile: p,
          score: level,
          scoreLabelKey: 'leaderboards_score_label_level',
        ),
      );
    }
    return out;
  }

  Future<List<LeaderboardEntry>> _buildLocalIndividualLeaderboard(
    SocialLeaderboardKind kind,
    Hunter? hunter,
  ) async {
    final me = await getMyPublicProfile(hunter: hunter);
    final stats = DatabaseService.getLeaderboardLocalStats();
    final seed = '${me.handle}_${hunter?.id ?? me.handle}_${kind.name}';

    int scoreForMe() {
      switch (kind) {
        case SocialLeaderboardKind.level:
          return me.level;
        case SocialLeaderboardKind.storyQuests:
          return stats.storyCompleted;
        case SocialLeaderboardKind.questWins:
          return stats.nonPenaltyCompleted;
        case SocialLeaderboardKind.dailyStreak:
          return stats.dailyStreak;
        case SocialLeaderboardKind.guildXp:
        case SocialLeaderboardKind.guildSeason:
          return 0;
      }
    }

    final labelKey = switch (kind) {
      SocialLeaderboardKind.level => 'leaderboards_score_label_level',
      SocialLeaderboardKind.storyQuests => 'leaderboards_score_label_story',
      SocialLeaderboardKind.questWins => 'leaderboards_score_label_wins',
      SocialLeaderboardKind.dailyStreak => 'leaderboards_score_label_streak',
      SocialLeaderboardKind.guildXp => 'leaderboards_score_label_guild_xp',
      SocialLeaderboardKind.guildSeason =>
        'leaderboards_score_label_season_pts',
    };

    final npcs = _mockNpcLeaderboardRows(
      kind: kind,
      seed: seed,
      scoreLabelKey: labelKey,
    );

    final myScore = scoreForMe();
    final mine = LeaderboardEntry(
      place: 0,
      profile: me,
      score: myScore,
      scoreLabelKey: labelKey,
    );

    final sorted = [...npcs, mine]..sort((a, b) => b.score.compareTo(a.score));
    final top = sorted.take(20).toList();
    return [
      for (var i = 0; i < top.length; i++)
        LeaderboardEntry(
          place: i + 1,
          profile: top[i].profile,
          score: top[i].score,
          scoreLabelKey: top[i].scoreLabelKey,
          opensFriendProfile: top[i].opensFriendProfile,
        ),
    ];
  }

  List<LeaderboardEntry> _mockNpcLeaderboardRows({
    required SocialLeaderboardKind kind,
    required String seed,
    required String scoreLabelKey,
  }) {
    const names = [
      'Lyra',
      'Kael',
      'Mira',
      'Orin',
      'Sera',
      'Dax',
      'Nyx',
      'Vorin',
      'Cael',
      'Iris',
      'Juno',
    ];
    return [
      for (var i = 0; i < names.length; i++)
        _npcRow(
          name: names[i],
          seed: seed,
          index: i,
          kind: kind,
          scoreLabelKey: scoreLabelKey,
        ),
    ];
  }

  LeaderboardEntry _npcRow({
    required String name,
    required String seed,
    required int index,
    required SocialLeaderboardKind kind,
    required String scoreLabelKey,
  }) {
    final disc = (Object.hash(seed, index + 99).abs() % 9000) + 1000;
    final level = 4 + (Object.hash(seed, index + 11).abs() % 44);
    final score = _npcScore(kind, seed, index);
    final sys =
        SystemId.values[Object.hash(seed, index).abs() % SystemId.values.length];
    final p = PublicProfile(
      handle: '$name#$disc',
      displayName: name,
      discriminator4: disc.toString(),
      activeSystemId: sys,
      level: level,
      rank: _rankForLevel(level),
    );
    return LeaderboardEntry(
      place: 0,
      profile: p,
      score: score,
      scoreLabelKey: scoreLabelKey,
    );
  }

  int _npcScore(SocialLeaderboardKind kind, String seed, int i) {
    final h = Object.hash(seed, i).abs();
    switch (kind) {
      case SocialLeaderboardKind.level:
        return 4 + (h % 44);
      case SocialLeaderboardKind.storyQuests:
        return h % 65;
      case SocialLeaderboardKind.questWins:
        return 5 + (h % 320);
      case SocialLeaderboardKind.dailyStreak:
        return h % 120;
      case SocialLeaderboardKind.guildXp:
      case SocialLeaderboardKind.guildSeason:
        return 0;
    }
  }

  Future<List<LeaderboardEntry>> _buildLocalGuildLeaderboard(
    SocialLeaderboardKind kind,
    Hunter? hunter,
  ) async {
    final snap = await DatabaseService.getGuildFocusRaidSnapshot();
    final rawName = DatabaseService.getGuildName();
    final myGuildName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'Гильдия охотника';

    final seed = 'guild_${hunter?.id ?? 'x'}_${kind.name}';

    final labelKey = kind == SocialLeaderboardKind.guildSeason
        ? 'leaderboards_score_label_season_pts'
        : 'leaderboards_score_label_guild_xp';
    final myScore = kind == SocialLeaderboardKind.guildSeason
        ? 800 +
            (snap.guildXp ~/ 5) +
            (Object.hash(seed, 1).abs() % 400)
        : snap.guildXp;

    const mockGuilds = [
      'Iron Vanguard',
      'Shadow Pact',
      'Solar Accord',
      'Crystal Watch',
      'Storm Assembly',
      'Void Choir',
      'Ember Circle',
    ];

    final rows = <LeaderboardEntry>[];
    for (var i = 0; i < mockGuilds.length; i++) {
      final gName = mockGuilds[i];
      final h0 = Object.hash(seed, gName, i).abs();
      final gLevel = 2 + (h0 % 28);
      final gScore = kind == SocialLeaderboardKind.guildXp
          ? 200 + (h0 % 12000)
          : 500 + (h0 % 9000);
      final disc = 2100 + (h0 % 7000);
      rows.add(
        LeaderboardEntry(
          place: 0,
          profile: PublicProfile(
            handle: '$gName#$disc',
            displayName: gName,
            discriminator4: disc.toString(),
            activeSystemId: SystemId.solo,
            level: gLevel,
            rank: 'G',
          ),
          score: gScore,
          scoreLabelKey: labelKey,
          opensFriendProfile: false,
        ),
      );
    }

    rows.add(
      LeaderboardEntry(
        place: 0,
        profile: PublicProfile(
          handle: '$myGuildName#0001',
          displayName: myGuildName,
          discriminator4: '0001',
          activeSystemId: SystemId.solo,
          level: snap.guildLevel,
          rank: 'G',
        ),
        score: myScore,
        scoreLabelKey: labelKey,
        opensFriendProfile: false,
      ),
    );

    rows.sort((a, b) => b.score.compareTo(a.score));
    final top = rows.take(12).toList();
    return [
      for (var i = 0; i < top.length; i++)
        LeaderboardEntry(
          place: i + 1,
          profile: top[i].profile,
          score: top[i].score,
          scoreLabelKey: top[i].scoreLabelKey,
          opensFriendProfile: false,
        ),
    ];
  }

  String _rankForLevel(int level) {
    if (level >= 50) return 'S';
    if (level >= 35) return 'A';
    if (level >= 25) return 'B';
    if (level >= 15) return 'C';
    if (level >= 8) return 'D';
    return 'E';
  }
}

/// Вкладки лидербордов: индивиды (локально + уровень из Supabase) и гильдии (локальный MVP).
enum SocialLeaderboardKind {
  level,
  storyQuests,
  questWins,
  dailyStreak,
  guildXp,
  guildSeason,
}

