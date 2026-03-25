import 'dart:async';
import 'dart:math';

import '../core/systems/system_id.dart';
import '../models/hunter_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/public_profile_model.dart';
import 'database_service.dart';

/// Каркас социалки.
///
/// Сейчас это локальные/мок-данные, чтобы UI уже жил.
/// Далее этот контракт будет подключён к Supabase (`public_profiles`, лидерборды, друзья).
class SocialService {
  const SocialService();

  Future<PublicProfile> getMyPublicProfile({Hunter? hunter}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
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
    final q = query.trim().toLowerCase();
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final me = await getMyPublicProfile(hunter: hunter);
    final pool = <PublicProfile>[
      me,
      ..._mockProfiles(seed: (me.handle.hashCode ^ q.hashCode).abs()),
    ];

    if (q.isEmpty) return pool.take(12).toList();
    return pool
        .where(
          (p) =>
              p.handle.toLowerCase().contains(q) ||
              p.displayName.toLowerCase().contains(q),
        )
        .take(20)
        .toList();
  }

  Future<PublicProfile?> getProfileByHandle(String handle, {Hunter? hunter}) async {
    final q = handle.trim();
    if (q.isEmpty) return null;
    final items = await searchProfiles(q, hunter: hunter);
    return items.firstWhere((p) => p.handle.toLowerCase() == q.toLowerCase(), orElse: () => items.first);
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    required SocialLeaderboardKind kind,
    Hunter? hunter,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final me = await getMyPublicProfile(hunter: hunter);
    final list = <PublicProfile>[
      ..._mockProfiles(seed: me.handle.hashCode ^ kind.index),
      me,
    ];

    int scoreOf(PublicProfile p) {
      return switch (kind) {
        SocialLeaderboardKind.level => p.level,
        SocialLeaderboardKind.questWins => (p.level * 11) + (p.discriminator4.hashCode % 37).abs(),
      };
    }

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    final out = <LeaderboardEntry>[];
    for (var i = 0; i < min(25, list.length); i++) {
      out.add(
        LeaderboardEntry(
          place: i + 1,
          profile: list[i],
          score: scoreOf(list[i]),
          scoreLabel: kind == SocialLeaderboardKind.level ? 'LVL' : 'WINS',
        ),
      );
    }
    return out;
  }

  String _rankForLevel(int level) {
    if (level >= 50) return 'S';
    if (level >= 35) return 'A';
    if (level >= 25) return 'B';
    if (level >= 15) return 'C';
    if (level >= 8) return 'D';
    return 'E';
  }

  List<PublicProfile> _mockProfiles({required int seed}) {
    final r = Random(seed);
    final names = <String>[
      'Shadow',
      'RuneSmith',
      'Lotus',
      'Monarch',
      'Archivist',
      'Wanderer',
      'Cipher',
      'Ascendant',
      'Ember',
      'IronWill',
      'SilentStep',
    ];
    final systems = SystemId.values;
    final out = <PublicProfile>[];
    for (var i = 0; i < 18; i++) {
      final name = names[r.nextInt(names.length)];
      final disc = r.nextInt(10000).toString().padLeft(4, '0');
      final lvl = 1 + r.nextInt(55);
      final sys = systems[r.nextInt(systems.length)];
      out.add(
        PublicProfile(
          handle: '$name#$disc',
          displayName: name,
          discriminator4: disc,
          activeSystemId: sys,
          level: lvl,
          rank: _rankForLevel(lvl),
        ),
      );
    }
    return out;
  }
}

enum SocialLeaderboardKind { level, questWins }

