import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
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
    final data = ref.watch(leaderboardProvider(_kind));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ProfileNeonCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<SocialLeaderboardKind>(
                            segments: [
                              ButtonSegment(
                                value: SocialLeaderboardKind.level,
                                label: Text(t('leaderboards_kind_level')),
                                icon: const Icon(Icons.trending_up_rounded),
                              ),
                              ButtonSegment(
                                value: SocialLeaderboardKind.questWins,
                                label: Text(t('leaderboards_kind_wins')),
                                icon: const Icon(Icons.check_circle_outline),
                              ),
                            ],
                            selected: {_kind},
                            onSelectionChanged: (s) => setState(() {
                              _kind = s.first;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: data.when(
                  data: (items) => _buildList(t, items),
                  error: (e, _) => SliverToBoxAdapter(
                    child: ProfileNeonCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${t('error')}: $e',
                        style: GoogleFonts.manrope(
                          color: SoloLevelingColors.warning,
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
                          color: SoloLevelingColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    String Function(String, {Map<String, String>? params}) t,
    List<LeaderboardEntry> items,
  ) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: ProfileNeonCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            t('leaderboards_empty'),
            style: GoogleFonts.manrope(
              color: SoloLevelingColors.textTertiary,
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
            onTap: () => _openProfile(e.profile.handle),
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
              e.profile.handle,
              style: GoogleFonts.manrope(
                color: SoloLevelingColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${t('rank')} ${e.profile.rank} · ${t('level')} ${e.profile.level}',
              style: GoogleFonts.manrope(color: SoloLevelingColors.textSecondary),
            ),
            trailing: Text(
              '${e.score} ${e.scoreLabel}',
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

