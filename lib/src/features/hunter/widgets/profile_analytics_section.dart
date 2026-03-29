import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/daily_quest_heatmap.dart';
import '../../../core/promo_ui.dart';
import '../../../core/system_visuals_extension.dart';
import '../../../core/widgets/world_material_chrome.dart';
import '../../../core/translations.dart';
import '../../../models/hunter_model.dart';
import '../../../services/database_service.dart';
import '../../../services/providers.dart';

/// Радар характеристик и тепловая карта ежедневных квестов (год).
class ProfileAnalyticsSection extends ConsumerWidget {
  const ProfileAnalyticsSection({
    super.key,
    required this.hunter,
  });

  final Hunter hunter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    ref.watch(questsProvider);
    final scheme = Theme.of(context).colorScheme;
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
    final glow = visuals.glowIntensity.clamp(0.0, 1.0);
    final counts = aggregateCompletedDailyQuestsByDay(
      DatabaseService.getAllQuests(),
    );
    final heatColumns = buildHeatmapYearColumns(countsByDay: counts);

    final labelStyle = GoogleFonts.manrope(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      letterSpacing: (visuals.titleLetterSpacing * 0.18).clamp(0.2, 0.9),
    );

    final d = hunter.displayStats;
    final mx = math.max(
      1,
      math.max(
        math.max(d.strength, d.agility),
        math.max(d.intelligence, d.vitality),
      ),
    );
    final labels = [
      DatabaseService.getStatLabelOverrides()['strength'] ?? t('strength'),
      DatabaseService.getStatLabelOverrides()['agility'] ?? t('agility'),
      DatabaseService.getStatLabelOverrides()['intelligence'] ??
          t('intelligence'),
      DatabaseService.getStatLabelOverrides()['vitality'] ?? t('vitality'),
    ];
    final vals = [
      d.strength / mx * 100,
      d.agility / mx * 100,
      d.intelligence / mx * 100,
      d.vitality / mx * 100,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        profileSectionTitle(context, t('profile_analytics_radar')),
        const SizedBox(height: 10),
        ProfileNeonCard(
          padding: EdgeInsets.zero,
          child: WorldMaterialChrome(
            visuals: visuals,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  radarBackgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.38),
                  radarBorderData: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.32 + 0.12 * glow),
                  ),
                  gridBorderData: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.38),
                  ),
                  tickBorderData: BorderSide(
                    color: scheme.secondary.withValues(alpha: 0.28 + 0.1 * glow),
                  ),
                  tickCount: 4,
                  ticksTextStyle: labelStyle.copyWith(fontSize: 9),
                  titleTextStyle: labelStyle,
                  titlePositionPercentageOffset: 0.12,
                  getTitle: (index, _) {
                    if (index >= 0 && index < labels.length) {
                      return RadarChartTitle(text: labels[index]);
                    }
                    return const RadarChartTitle(text: '');
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: scheme.primary.withValues(
                        alpha: 0.16 + 0.12 * glow,
                      ),
                      borderColor: scheme.primary,
                      borderWidth: 2,
                      entryRadius: 3,
                      dataEntries: vals
                          .map((v) => RadarEntry(value: v))
                          .toList(),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
        const SizedBox(height: 24),
        profileSectionTitle(context, t('profile_analytics_heatmap')),
        const SizedBox(height: 10),
        ProfileNeonCard(
          padding: EdgeInsets.zero,
          child: WorldMaterialChrome(
            visuals: visuals,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              SizedBox(
                height: 7 * 10.0 + 6 * 2 + 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: heatColumns.map((week) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(7, (row) {
                            final v = week[row];
                            return _HeatCell(
                              scheme: scheme,
                              glow: glow,
                              count: v,
                              rowHeight: 10,
                              rowGap: 2,
                            );
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    t('heatmap_legend_low'),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._legendSamples(scheme, glow),
                  const SizedBox(width: 8),
                  Text(
                    t('heatmap_legend_high'),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration: 440.ms,
              delay: 90.ms,
              curve: Curves.easeOutCubic,
            )
            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
      ],
    );
  }

  static List<Widget> _legendSamples(ColorScheme scheme, double glow) {
    final empty = scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final low = scheme.primary.withValues(alpha: 0.38 + 0.08 * glow);
    final high = scheme.primary.withValues(alpha: 0.82 + 0.1 * glow);
    final border = scheme.outline.withValues(alpha: 0.22);
    return [
      _legendBox(empty, border),
      _legendBox(low, border),
      _legendBox(high, border),
    ];
  }

  static Widget _legendBox(Color fill, Color border) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.scheme,
    required this.glow,
    required this.count,
    required this.rowHeight,
    required this.rowGap,
  });

  final ColorScheme scheme;
  final double glow;
  final int count;
  final double rowHeight;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    if (count < 0) {
      fill = Colors.transparent;
    } else if (count == 0) {
      fill = scheme.surfaceContainerHighest.withValues(alpha: 0.48);
    } else if (count == 1) {
      fill = scheme.primary.withValues(alpha: 0.38 + 0.08 * glow);
    } else {
      fill = scheme.primary.withValues(alpha: 0.82 + 0.1 * glow);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: rowGap),
      child: Container(
        width: 10,
        height: rowHeight,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(2),
          border: count >= 0
              ? Border.all(
                  color: scheme.outline.withValues(alpha: 0.14),
                )
              : null,
        ),
      ),
    );
  }
}
