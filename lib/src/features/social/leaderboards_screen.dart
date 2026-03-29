import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../services/providers.dart';
import '../../services/social_service.dart';
import '../../models/leaderboard_entry_model.dart';
import 'friend_profile_screen.dart';

class LeaderboardsScreen extends ConsumerStatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  ConsumerState<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends ConsumerState<LeaderboardsScreen> {
  SocialLeaderboardKind _kind = SocialLeaderboardKind.level;

  static const _playerKinds = <SocialLeaderboardKind>[
    SocialLeaderboardKind.level,
    SocialLeaderboardKind.storyQuests,
    SocialLeaderboardKind.dailyStreak,
    SocialLeaderboardKind.questWins,
  ];

  static const _guildKinds = <SocialLeaderboardKind>[
    SocialLeaderboardKind.guildXp,
    SocialLeaderboardKind.guildSeason,
  ];

  String _kindTitle(
    String Function(String, {Map<String, String>? params}) t,
    SocialLeaderboardKind k,
  ) {
    return switch (k) {
      SocialLeaderboardKind.level => t('leaderboards_kind_level'),
      SocialLeaderboardKind.storyQuests => t('leaderboards_kind_story'),
      SocialLeaderboardKind.questWins => t('leaderboards_kind_wins'),
      SocialLeaderboardKind.dailyStreak => t('leaderboards_kind_streak'),
      SocialLeaderboardKind.guildXp => t('leaderboards_kind_guild_xp'),
      SocialLeaderboardKind.guildSeason => t('leaderboards_kind_guild_season'),
    };
  }

  void _openProfile(String handle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendProfileScreen(handle: handle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(leaderboardProvider(_kind));
    final visuals = Theme.of(context).extension<SystemVisuals>() ??
        const SystemVisuals(
          backgroundKind: SystemBackgroundKind.grid,
          backgroundAssetPath: '',
          particlesKind: SystemParticlesKind.none,
          panelRadius: 12,
          panelBorderWidth: 1,
          panelBlur: 0,
          titleLetterSpacing: 2.2,
          surfaceKind: SystemSurfaceKind.digital,
          glowIntensity: 0.35,
          borderRadiusScale: 1.0,
          shadowProfile: SystemShadowProfile.soft,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: WorldSurfacePanel(
              visuals: visuals,
              margin: EdgeInsets.zero,
              child: CustomScrollView(
                slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  t('leaderboards_title'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: ProfileNeonCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('leaderboards_section_players'),
                          style: GoogleFonts.manrope(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final k in _playerKinds)
                              FilterChip(
                                selected: _kind == k,
                                showCheckmark: false,
                                label: Text(_kindTitle(t, k)),
                                onSelected: (_) =>
                                    setState(() => _kind = k),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          t('leaderboards_section_guilds'),
                          style: GoogleFonts.manrope(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final k in _guildKinds)
                              FilterChip(
                                selected: _kind == k,
                                showCheckmark: false,
                                label: Text(_kindTitle(t, k)),
                                onSelected: (_) =>
                                    setState(() => _kind = k),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                sliver: data.when(
                  data: (items) => _buildList(context, t, items),
                  error: (e, _) => SliverToBoxAdapter(
                    child: ProfileNeonCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${t('error')}: $e',
                        style: GoogleFonts.manrope(
                          color: scheme.error,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  loading: () => SliverToBoxAdapter(
                    child: ProfileNeonCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        t('loading'),
                        style: GoogleFonts.manrope(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
                  child: ProfileNeonCard(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      t('leaderboards_mvp_note'),
                      style: GoogleFonts.manrope(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    String Function(String, {Map<String, String>? params}) t,
    List<LeaderboardEntry> items,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: ProfileNeonCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            t('leaderboards_empty'),
            style: GoogleFonts.manrope(
              color: scheme.outline,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    return SliverList.separated(
      itemBuilder: (context, index) {
        final e = items[index];
        return ProfileNeonCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            onTap: e.opensFriendProfile
                ? () => _openProfile(e.profile.handle)
                : null,
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
              child: Text(
                '${e.place}',
                style: GoogleFonts.manrope(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: Text(
              e.opensFriendProfile
                  ? e.profile.handle
                  : e.profile.displayName,
              style: GoogleFonts.manrope(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              e.opensFriendProfile
                  ? '${t('rank')} ${e.profile.rank} · ${t('level')} ${e.profile.level}'
                  : t(
                      'leaderboards_guild_row_meta',
                      params: {
                        'guild_level': '${e.profile.level}',
                      },
                    ),
              style: GoogleFonts.manrope(color: scheme.onSurfaceVariant),
            ),
            trailing: Text(
              '${e.score} ${t(e.scoreLabelKey)}',
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: items.length,
    );
  }
}

