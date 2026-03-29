import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/system_visuals_extension.dart';
import '../../../core/systems/system_dictionary.dart';
import '../../../core/translations.dart';
import '../../../core/world_journal_axis_tags.dart';
import '../../../models/quest_model.dart';
import '../../../services/database_service.dart';
import '../../../services/providers.dart';
import '../../../services/translation_service.dart';

/// Сводка завершённых квестов по «оси мира» + многоуровневый лор (Фаза 7.7).
void showWorldJournalSheet(BuildContext context, WidgetRef ref) {
  final t = useTranslations(ref);
  final systemId = ref.read(activeSystemIdProvider);
  final rules = ref.read(activeSystemRulesProvider);
  final navId = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
  final loreSuffix = navId.name;

  final done = DatabaseService.getAllQuests()
      .where((q) => q.status == QuestStatus.completed)
      .toList();

  int countAxis(Set<String> keys) {
    var n = 0;
    for (final q in done) {
      final hit = q.tags.any(
        (tag) => keys.contains(tag.toLowerCase().trim()),
      );
      if (hit) n++;
    }
    return n;
  }

  final bodyN = countAxis(WorldJournalAxisTags.body);
  final mindN = countAxis(WorldJournalAxisTags.mind);
  final focusN = countAxis(WorldJournalAxisTags.focus);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.82;
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(ctx).bottom + 16,
        ),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('world_journal_title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),
                  _JournalSection(
                    axisId: 'body',
                    label: t('world_journal_body_axis'),
                    count: bodyN,
                    navSuffix: loreSuffix,
                    scheme: scheme,
                    t: t,
                    staggerIndex: 0,
                  ),
                  const SizedBox(height: 14),
                  _JournalSection(
                    axisId: 'mind',
                    label: t('world_journal_mind_axis'),
                    count: mindN,
                    navSuffix: loreSuffix,
                    scheme: scheme,
                    t: t,
                    staggerIndex: 1,
                  ),
                  const SizedBox(height: 14),
                  _JournalSection(
                    axisId: 'focus',
                    label: t('world_journal_focus_axis'),
                    count: focusN,
                    navSuffix: loreSuffix,
                    scheme: scheme,
                    t: t,
                    staggerIndex: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('world_journal_hint'),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 420.ms,
                        delay: 280.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _JournalSection extends StatelessWidget {
  const _JournalSection({
    required this.axisId,
    required this.label,
    required this.count,
    required this.navSuffix,
    required this.scheme,
    required this.t,
    required this.staggerIndex,
  });

  final String axisId;
  final String label;
  final int count;
  final String navSuffix;
  final ColorScheme scheme;
  final String Function(String, {Map<String, String>? params}) t;
  final int staggerIndex;

  static const int whisperMin = 3;
  static const int loreThreshold = 10;
  static const int codexThreshold = 25;

  String _key(String tier) =>
      'world_journal_${tier}_${axisId}_$navSuffix';

  @override
  Widget build(BuildContext context) {
    final showWhisper =
        count >= whisperMin && count < loreThreshold;
    final showLore = count >= loreThreshold;
    final showCodex = count >= codexThreshold;

    final delay = (60 + staggerIndex * 100).ms;

    Widget section = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              showLore
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 22,
              color: showLore ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t(
                  'world_journal_milestone_line',
                  params: {
                    'label': label,
                    'count': '$count',
                    'threshold': '$loreThreshold',
                  },
                ),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.35,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TierProgressBar(
          count: count,
          scheme: scheme,
        ),
        if (showWhisper) ...[
          const SizedBox(height: 10),
          _LoreCallout(
            scheme: scheme,
            label: t('world_journal_whisper_label'),
            body: t(_key('whisper')),
            borderAlpha: 0.18,
            fillAlpha: 0.05,
          ),
        ],
        if (showLore) ...[
          const SizedBox(height: 10),
          _LoreCallout(
            scheme: scheme,
            label: t('world_journal_seal_label'),
            body: t(_key('lore')),
            borderAlpha: 0.22,
            fillAlpha: 0.07,
          ),
        ],
        if (showCodex) ...[
          const SizedBox(height: 10),
          _LoreCallout(
            scheme: scheme,
            label: t('world_journal_codex_label'),
            body: t(_key('codex')),
            borderAlpha: 0.28,
            fillAlpha: 0.08,
            accent: scheme.tertiary,
          ),
        ],
      ],
    );

    return section
        .animate()
        .fadeIn(duration: 420.ms, delay: delay, curve: Curves.easeOutCubic)
        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }
}

/// Прогресс к печати (10) и к кодексу (25).
class _TierProgressBar extends StatelessWidget {
  const _TierProgressBar({
    required this.count,
    required this.scheme,
  });

  final int count;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    double value;
    String captionKey;
    const seal = _JournalSection.loreThreshold;
    const codex = _JournalSection.codexThreshold;

    if (count < seal) {
      value = (count / seal).clamp(0.0, 1.0);
      captionKey = 'world_journal_progress_seal';
    } else if (count < codex) {
      value = ((count - seal) / (codex - seal)).clamp(0.0, 1.0);
      captionKey = 'world_journal_progress_codex';
    } else {
      value = 1.0;
      captionKey = 'world_journal_progress_complete';
    }

    final caption = TranslationService.translate(
      captionKey,
      params: {
        'current': '$count',
        'next': count < seal ? '$seal' : '$codex',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            color: count >= codex
                ? scheme.tertiary
                : scheme.primary.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: GoogleFonts.manrope(
            fontSize: 11,
            height: 1.25,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _LoreCallout extends StatelessWidget {
  const _LoreCallout({
    required this.scheme,
    required this.label,
    required this.body,
    required this.borderAlpha,
    required this.fillAlpha,
    this.accent,
  });

  final ColorScheme scheme;
  final String label;
  final String body;
  final double borderAlpha;
  final double fillAlpha;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? scheme.primary;
    final visuals = Theme.of(context).extension<SystemVisuals>();
    final loreRadius = ((visuals?.panelRadius ?? 12) *
            (visuals?.borderRadiusScale ?? 1.0))
        .clamp(8.0, 26.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.withValues(alpha: fillAlpha),
        borderRadius: BorderRadius.circular(loreRadius),
        border: Border.all(
          color: c.withValues(alpha: borderAlpha),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: c.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: scheme.onSurface.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
