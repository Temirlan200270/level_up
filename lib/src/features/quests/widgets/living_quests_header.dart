import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/hunter_display.dart';
import '../../../core/system_visuals_extension.dart';
import '../../../data/titles_data.dart';
import '../../../models/hunter_model.dart';

/// Фон [FlexibleSpaceBar]: развёрнутый профиль и свёрнутая неоновая полоска.
class LivingQuestsFlexibleHeader extends StatelessWidget {
  const LivingQuestsFlexibleHeader({
    super.key,
    required this.hunter,
    required this.vitalityRatio,
    required this.focusRatio,
    required this.focusMinutesToday,
    required this.focusGoalMinutes,
    required this.vitalityStressPulse,
    required this.focusStressPulse,
    required this.t,
    required this.neonColor,
  });

  final Hunter? hunter;
  final double vitalityRatio;
  final double focusRatio;
  final int focusMinutesToday;
  final int focusGoalMinutes;
  /// Вечер + доля физических дейликов за день ниже 20%.
  final bool vitalityStressPulse;
  /// Минут фокуса за день = 0 при ненулевой дневной цели (MP «пуст»).
  final bool focusStressPulse;
  final String Function(String, {Map<String, String>? params}) t;
  final Color neonColor;

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final cs = Theme.of(context).colorScheme;
    var expandT = 1.0;
    if (settings != null && settings.maxExtent > settings.minExtent + 0.5) {
      expandT = ((settings.currentExtent - settings.minExtent) /
              (settings.maxExtent - settings.minExtent))
          .clamp(0.0, 1.0);
    }
    expandT = Curves.easeOutCubic.transform(expandT);
    final collapseT = (1.0 - expandT).clamp(0.0, 1.0);

    final hasHunter = hunter != null;
    final level = hunter?.level ?? 1;
    final rank = hasHunter ? hunterRankCode(level) : '—';
    final expP = hunter?.levelProgress ?? 0.0;
    final sanctuaryActive = hunter?.isSanctuaryActive ?? false;
    final hunterDisplayName = hunter?.name;
    final equippedTitleLine = hunter?.equippedTitleId != null
        ? getTitleById(hunter!.equippedTitleId!)?.name
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.surface.withValues(alpha: 0.05),
                cs.surface.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Opacity(
          opacity: expandT,
          child: IgnorePointer(
            ignoring: expandT < 0.04,
            child: _ExpandedLivingBlock(
              rank: rank,
              level: level,
              expProgress: expP,
              vitalityRatio: vitalityRatio,
              focusRatio: focusRatio,
              focusMinutesToday: focusMinutesToday,
              focusGoalMinutes: focusGoalMinutes,
              vitalityStressPulse: vitalityStressPulse,
              focusStressPulse: focusStressPulse,
              hasHunter: hasHunter,
              sanctuaryActive: sanctuaryActive,
              hunterDisplayName: hunterDisplayName,
              equippedTitleLine: equippedTitleLine,
              t: t,
              neonColor: neonColor,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: collapseT,
            child: IgnorePointer(
              ignoring: collapseT < 0.04,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 148, 8),
                child: _CollapsedNeonStrip(
                  rank: rank,
                  level: level,
                  expProgress: expP,
                  sanctuaryActive: sanctuaryActive,
                  t: t,
                  neonColor: neonColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandedLivingBlock extends StatelessWidget {
  const _ExpandedLivingBlock({
    required this.rank,
    required this.level,
    required this.expProgress,
    required this.vitalityRatio,
    required this.focusRatio,
    required this.focusMinutesToday,
    required this.focusGoalMinutes,
    required this.vitalityStressPulse,
    required this.focusStressPulse,
    required this.hasHunter,
    required this.sanctuaryActive,
    this.hunterDisplayName,
    this.equippedTitleLine,
    required this.t,
    required this.neonColor,
  });

  final String rank;
  final int level;
  final double expProgress;
  final double vitalityRatio;
  final double focusRatio;
  final int focusMinutesToday;
  final int focusGoalMinutes;
  final bool vitalityStressPulse;
  final bool focusStressPulse;
  final bool hasHunter;
  final bool sanctuaryActive;
  final String? hunterDisplayName;
  final String? equippedTitleLine;
  final String Function(String, {Map<String, String>? params}) t;
  final Color neonColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rank,
                style: GoogleFonts.manrope(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: neonColor,
                  shadows: [
                    Shadow(
                      color: neonColor.withValues(alpha: 0.45),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              if (sanctuaryActive) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _LivingSanctuaryGlyph(
                    t: t,
                    accent: cs.tertiary,
                    size: 24,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasHunter)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      t('living_header_no_profile'),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (hasHunter &&
                    hunterDisplayName != null &&
                    hunterDisplayName!.trim().isNotEmpty) ...[
                  Text(
                    hunterDisplayName!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  if (equippedTitleLine != null &&
                      equippedTitleLine!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      equippedTitleLine!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                ],
                Text(
                  '${t('level')} $level',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                _LabeledBar(
                  label: t('experience'),
                  value: expProgress,
                  neonColor: neonColor,
                  trackColor: cs.onSurface.withValues(alpha: 0.12),
                  criticalStress: false,
                ),
                const SizedBox(height: 8),
                _LabeledBar(
                  label: sanctuaryActive
                      ? '${t('living_header_vessel_hp')} · ${t('vitality')} · ${t('living_header_sanctuary_short')}'
                      : '${t('living_header_vessel_hp')} · ${t('vitality')}',
                  value: vitalityRatio,
                  neonColor: cs.primary,
                  trackColor: cs.onSurface.withValues(alpha: 0.1),
                  criticalStress: vitalityStressPulse,
                ),
                const SizedBox(height: 6),
                _LabeledBar(
                  label:
                      '${t('living_header_vessel_mp')} · $focusMinutesToday/$focusGoalMinutes ${t('living_header_minutes_short')}',
                  value: focusRatio,
                  neonColor: cs.secondary,
                  trackColor: cs.onSurface.withValues(alpha: 0.1),
                  criticalStress: focusStressPulse,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledBar extends StatelessWidget {
  const _LabeledBar({
    required this.label,
    required this.value,
    required this.neonColor,
    required this.trackColor,
    this.criticalStress = false,
  });

  final String label;
  final double value;
  final Color neonColor;
  final Color trackColor;
  final bool criticalStress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowFx =
        Theme.of(context).extension<SystemVisuals>()?.lowFxMode ?? false;
    final v = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: criticalStress
                ? Color.lerp(cs.onSurfaceVariant, cs.error, 0.35)!
                : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 7,
                color: criticalStress
                    ? Color.lerp(
                        trackColor,
                        cs.error.withValues(alpha: 0.12),
                        0.55,
                      )!
                    : trackColor,
              ),
              FractionallySizedBox(
                widthFactor: v,
                child: criticalStress
                    ? _CriticalBarFill(lowFx: lowFx)
                    : Container(
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            colors: [
                              neonColor.withValues(alpha: 0.85),
                              neonColor,
                            ],
                          ),
                          boxShadow: lowFx
                              ? null
                              : [
                                  BoxShadow(
                                    color: neonColor.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    spreadRadius: 0.2,
                                  ),
                                ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Медленная пульсация «критического» заполнения (HP/MP) в живой шапке.
class _CriticalBarFill extends StatefulWidget {
  const _CriticalBarFill({required this.lowFx});

  final bool lowFx;

  @override
  State<_CriticalBarFill> createState() => _CriticalBarFillState();
}

class _CriticalBarFillState extends State<_CriticalBarFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!widget.lowFx) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_CriticalBarFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lowFx && !oldWidget.lowFx) {
      _controller.stop();
    } else if (!widget.lowFx && oldWidget.lowFx) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.lowFx) {
      return Container(
        height: 7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: cs.error.withValues(alpha: 0.72),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final bright = Color.lerp(
          cs.error,
          cs.error.withValues(alpha: 0.38),
          t,
        )!;
        final dim = Color.lerp(
          cs.error.withValues(alpha: 0.45),
          cs.onErrorContainer.withValues(alpha: 0.5),
          t,
        )!;
        return Container(
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(colors: [bright, dim]),
            boxShadow: [
              BoxShadow(
                color: cs.error.withValues(alpha: 0.22 + 0.18 * t),
                blurRadius: 5 + 5 * t,
                spreadRadius: 0.15,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CollapsedNeonStrip extends StatelessWidget {
  const _CollapsedNeonStrip({
    required this.rank,
    required this.level,
    required this.expProgress,
    required this.sanctuaryActive,
    required this.t,
    required this.neonColor,
  });

  final String rank;
  final int level;
  final double expProgress;
  final bool sanctuaryActive;
  final String Function(String, {Map<String, String>? params}) t;
  final Color neonColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final left = t(
      'living_header_collapsed_left',
      params: {'rank': rank, 'level': '$level'},
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (sanctuaryActive) ...[
              const SizedBox(width: 6),
              _LivingSanctuaryGlyph(
                t: t,
                accent: cs.tertiary,
                size: 18,
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        _SegmentNeonBar(progress: expProgress, neonColor: neonColor),
      ],
    );
  }
}

/// Иконка «Святилище» в живом заголовке (Фаза 9.2).
class _LivingSanctuaryGlyph extends StatelessWidget {
  const _LivingSanctuaryGlyph({
    required this.t,
    required this.accent,
    required this.size,
  });

  final String Function(String, {Map<String, String>? params}) t;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final msg = t('living_header_sanctuary_tooltip');
    return Tooltip(
      message: msg,
      child: Semantics(
        label: msg,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: size * 0.45,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Icon(
            Icons.shield_moon_rounded,
            size: size,
            color: accent,
            shadows: [
              Shadow(
                color: accent.withValues(alpha: 0.55),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentNeonBar extends StatelessWidget {
  const _SegmentNeonBar({
    required this.progress,
    required this.neonColor,
  });

  final double progress;
  final Color neonColor;

  @override
  Widget build(BuildContext context) {
    const segments = 10;
    final filled = (progress.clamp(0.0, 1.0) * segments).round().clamp(0, segments);
    return SizedBox(
      height: 5,
      child: Row(
        children: List.generate(segments, (i) {
          final on = i < filled;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: on
                      ? neonColor
                      : neonColor.withValues(alpha: 0.18),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: neonColor.withValues(alpha: 0.55),
                            blurRadius: 5,
                            spreadRadius: 0.2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
