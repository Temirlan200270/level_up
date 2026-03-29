import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../services/providers.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(profileByHandleProvider(handle));
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
                  t('friend_profile_title'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                sliver: data.when(
                  data: (p) {
                    if (p == null) {
                      return SliverToBoxAdapter(
                        child: ProfileNeonCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t('friend_profile_not_found'),
                            style: GoogleFonts.manrope(
                              color: scheme.outline,
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
                                Row(
                                  children: [
                                    Icon(
                                      p.activeSystemId.icon,
                                      color: scheme.onSurface,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        p.handle,
                                        style: GoogleFonts.manrope(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                color: scheme.onSurfaceVariant,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

