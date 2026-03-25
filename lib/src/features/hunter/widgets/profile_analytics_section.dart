import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/daily_quest_heatmap.dart';
import '../../../core/promo_ui.dart';
import '../../../core/theme.dart';
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
    final counts = aggregateCompletedDailyQuestsByDay(
      DatabaseService.getAllQuests(),
    );
    final heatColumns = buildHeatmapYearColumns(countsByDay: counts);

    final labelStyle = GoogleFonts.manrope(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: SoloLevelingColors.textSecondary,
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBackgroundColor: SoloLevelingColors.surfaceLight
                    .withValues(alpha: 0.25),
                radarBorderData: BorderSide(
                  color: SoloLevelingColors.neonBlue.withValues(alpha: 0.35),
                ),
                gridBorderData: BorderSide(
                  color: SoloLevelingColors.textTertiary.withValues(alpha: 0.35),
                ),
                tickBorderData: BorderSide(
                  color: SoloLevelingColors.neonPurple.withValues(alpha: 0.25),
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
                    fillColor: SoloLevelingColors.neonBlue.withValues(
                      alpha: 0.22,
                    ),
                    borderColor: SoloLevelingColors.neonBlue,
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
        const SizedBox(height: 24),
        profileSectionTitle(context, t('profile_analytics_heatmap')),
        const SizedBox(height: 10),
        ProfileNeonCard(
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
                      color: SoloLevelingColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _legendSample(0),
                  _legendSample(1),
                  _legendSample(2),
                  const SizedBox(width: 8),
                  Text(
                    t('heatmap_legend_high'),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: SoloLevelingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _legendSample(int level) {
    Color c;
    switch (level) {
      case 0:
        c = SoloLevelingColors.surfaceLight.withValues(alpha: 0.45);
        break;
      case 1:
        c = SoloLevelingColors.neonGreen.withValues(alpha: 0.45);
        break;
      default:
        c = SoloLevelingColors.neonGreen.withValues(alpha: 0.9);
    }
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: SoloLevelingColors.neonBlue.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.count,
    required this.rowHeight,
    required this.rowGap,
  });

  final int count;
  final double rowHeight;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    if (count < 0) {
      fill = Colors.transparent;
    } else if (count == 0) {
      fill = SoloLevelingColors.surfaceLight.withValues(alpha: 0.4);
    } else if (count == 1) {
      fill = SoloLevelingColors.neonGreen.withValues(alpha: 0.42);
    } else {
      fill = SoloLevelingColors.neonGreen.withValues(alpha: 0.9);
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
                  color: SoloLevelingColors.neonBlue.withValues(alpha: 0.12),
                )
              : null,
        ),
      ),
    );
  }
}
