import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../services/providers.dart';
import '../../models/public_profile_model.dart';
import 'friend_profile_screen.dart';

class HallOfFameScreen extends ConsumerStatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  ConsumerState<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends ConsumerState<HallOfFameScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openProfile(PublicProfile p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendProfileScreen(handle: p.handle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final results = ref.watch(searchProfilesProvider(_query));
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
                  t('hall_of_fame_title'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: ProfileNeonCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('hall_of_fame_subtitle'),
                          style: GoogleFonts.manrope(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _ctrl,
                          style: GoogleFonts.manrope(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: t('hall_of_fame_search_hint'),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                sliver: results.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: ProfileNeonCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t('hall_of_fame_empty'),
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
                        final p = items[index];
                        return ProfileNeonCard(
                          padding: EdgeInsets.zero,
                          child: PromoSettingsTile(
                            icon: p.activeSystemId.icon,
                            title: p.handle,
                            subtitle:
                                '${t('level')} ${p.level} · ${t('rank')} ${p.rank}',
                            onTap: () => _openProfile(p),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: items.length,
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

