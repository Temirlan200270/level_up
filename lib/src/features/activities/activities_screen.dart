import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../models/dungeon_model.dart';
import '../../services/providers.dart';
import 'widgets/dungeon_generation_dialog.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dungeons = ref.watch(dungeonsProvider);
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final visuals = context.systemVisuals;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: WorldSurfacePanel(
              visuals: visuals,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('activities_gates_header'),
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing:
                            (visuals.titleLetterSpacing * 0.42).clamp(0.6, 1.4),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: scheme.primary,
                      ),
                      onPressed: () async {
                        final hunter = ref.read(hunterProvider);
                        if (hunter == null) return;
                        
                        await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              DungeonGenerationDialog(hunter: hunter),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (dungeons.isEmpty)
                  _buildEmptyState(context, t)
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: dungeons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        return _buildDungeonCard(
                          context,
                          t,
                          dungeons[i],
                          scheme,
                        );
                      },
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: ProfileNeonCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.door_sliding_outlined,
                size: 64,
                color: scheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                t('activities_empty_title'),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('activities_empty_body'),
                style: GoogleFonts.manrope(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDungeonCard(
    BuildContext context,
    String Function(String, {Map<String, String>? params}) t,
    Dungeon d,
    ColorScheme scheme,
  ) {
    final cardR = context.worldCardRadius;
    final innerR = (cardR * 0.5).clamp(6.0, 12.0);

    Color getStatusColor() {
      if (d.status == DungeonStatus.failed) return scheme.error;
      if (d.status == DungeonStatus.completed) return scheme.tertiary;
      if (d.isRedGate) return scheme.error;
      return scheme.primary;
    }

    String getStatusText() {
      switch (d.status) {
        case DungeonStatus.active:
          return d.isRedGate
              ? t('dungeon_status_blood_gates')
              : t('dungeon_status_active');
        case DungeonStatus.completed:
          return t('dungeon_status_cleared');
        case DungeonStatus.failed:
          return t('dungeon_status_failed');
      }
    }

    final isFailed = d.status == DungeonStatus.failed;
    final isCompleted = d.status == DungeonStatus.completed;
    final isRedGateActive = d.isRedGate && d.status == DungeonStatus.active;

    return Opacity(
      opacity: (isFailed || isCompleted) ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardR),
          border: Border.all(
            color: getStatusColor().withValues(alpha: isRedGateActive ? 0.8 : 0.5),
            width: isRedGateActive ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (!isFailed && !isCompleted)
              BoxShadow(
                color: getStatusColor().withValues(alpha: isRedGateActive ? 0.3 : 0.1),
                blurRadius: isRedGateActive ? 15 : 10,
                spreadRadius: isRedGateActive ? 4 : 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardR),
          child: Material(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        d.isRedGate ? Icons.warning_amber_rounded : Icons.door_sliding,
                        color: getStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d.title,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: d.isRedGate && !isFailed && !isCompleted
                                ? scheme.error
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getStatusColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(innerR),
                        ),
                        child: Text(
                          getStatusText(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: getStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    d.description,
                    style: GoogleFonts.manrope(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('dungeon_card_progress_label'),
                        style: GoogleFonts.manrope(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        t(
                          'dungeon_card_stages',
                          params: {
                            'current': '${d.currentStageIndex}',
                            'total': '${d.totalStages}',
                          },
                        ),
                        style: GoogleFonts.manrope(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: d.totalStages > 0 ? d.currentStageIndex / d.totalStages : 0,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: getStatusColor(),
                      minHeight: 6,
                    ),
                  ),
                  if (d.status == DungeonStatus.active && d.currentStageIndex < d.totalStages) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(innerR),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(
                              'dungeon_card_current_stage_title',
                              params: {
                                'title':
                                    d.stageTitles[d.currentStageIndex],
                              },
                            ),
                            style: GoogleFonts.manrope(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.stageDescriptions[d.currentStageIndex],
                            style: GoogleFonts.manrope(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

