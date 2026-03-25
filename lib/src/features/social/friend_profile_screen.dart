import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/providers.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final data = ref.watch(profileByHandleProvider(handle));

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
                  t('friend_profile_title'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: data.when(
                  data: (p) {
                    if (p == null) {
                      return SliverToBoxAdapter(
                        child: ProfileNeonCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t('friend_profile_not_found'),
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textTertiary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileNeonCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  p.handle,
                                  style: GoogleFonts.manrope(
                                    color: SoloLevelingColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ProfilePillBadge(
                                      label:
                                          '${t('rank')} ${p.rank} · ${t('level')} ${p.level}',
                                    ),
                                    const SizedBox(width: 8),
                                    ProfilePillBadge(
                                      label: t('system_${p.activeSystemId.value}'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ProfileNeonCard(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              t('friend_profile_stub_body'),
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
}

