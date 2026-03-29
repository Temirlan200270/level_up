import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../services/database_service.dart';

/// Экран ивента «Мировые врата»: общая цель недели (локальный MVP + симуляция прогресса).
class WorldGatesScreen extends ConsumerStatefulWidget {
  const WorldGatesScreen({super.key});

  @override
  ConsumerState<WorldGatesScreen> createState() => _WorldGatesScreenState();
}

class _WorldGatesScreenState extends ConsumerState<WorldGatesScreen> {
  Future<WorldGateSnapshot>? _load;

  @override
  void initState() {
    super.initState();
    _load = DatabaseService.getWorldGateSnapshot();
  }

  Future<void> _reload() async {
    setState(() {
      _load = DatabaseService.getWorldGateSnapshot();
    });
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final guildVisuals = Theme.of(context).extension<SystemVisuals>() ??
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
          child: RefreshIndicator(
            color: scheme.primary,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    t('world_gates_title'),
                    style: promoAppBarTitleStyle(context),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
                    child: FutureBuilder<WorldGateSnapshot>(
                      future: _load,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final s = snap.data!;
                        return WorldSurfacePanel(
                          visuals: guildVisuals,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ProfileNeonCard(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  scheme.tertiary,
                                                  scheme.primary,
                                                ],
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.public_rounded,
                                              color: scheme.onPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t('world_gates_raid_title'),
                                                  style: GoogleFonts.manrope(
                                                    color: scheme.onSurface,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  t('world_gates_week_hint'),
                                                  style: GoogleFonts.manrope(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                    fontSize: 12,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: LinearProgressIndicator(
                                          value: s.progressFraction,
                                          minHeight: 10,
                                          backgroundColor:
                                              scheme.surfaceContainerHighest,
                                          color: scheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        t(
                                          'world_gates_progress_line',
                                          params: {
                                            'current':
                                                '${s.communityProgressTotal}',
                                            'goal': '${s.goal}',
                                          },
                                        ),
                                        style: GoogleFonts.manrope(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        t(
                                          'world_gates_personal_line',
                                          params: {
                                            'pts': '${s.personalContribution}',
                                          },
                                        ),
                                        style: GoogleFonts.manrope(
                                          color: scheme.secondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 280.ms)
                                    .slideY(
                                      begin: 0.06,
                                      curve: Curves.easeOut,
                                    ),
                                const SizedBox(height: 14),
                                ProfileNeonCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    t('world_gates_mvp_note'),
                                    style: GoogleFonts.manrope(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                                    .animate(delay: 60.ms)
                                    .fadeIn(duration: 280.ms)
                                    .slideY(
                                      begin: 0.06,
                                      curve: Curves.easeOut,
                                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
