import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/translations.dart';
import '../../../models/buff_model.dart';
import '../../../services/evaluators/adaptive_difficulty_service.dart';
import '../../../services/providers.dart';

class AdaptiveCalibrationDialog extends ConsumerWidget {
  const AdaptiveCalibrationDialog({super.key, required this.evaluation});

  final AdaptiveDifficultyEvaluation evaluation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEasy = evaluation.status == AdaptiveDifficultyStatus.tooEasy;
    final scheme = Theme.of(context).colorScheme;
    final t = useTranslations(ref);

    final accent = isEasy ? scheme.tertiary : scheme.primary;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      title: Row(
        children: [
          Icon(
            isEasy ? Icons.trending_up : Icons.spa_rounded,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t('adaptive_calibration_title'),
              style: GoogleFonts.manrope(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEasy
                ? t('adaptive_calibration_body_easy')
                : t('adaptive_calibration_body_hard'),
            style: GoogleFonts.manrope(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEasy
                      ? t('adaptive_calibration_mode_hard')
                      : t('adaptive_calibration_mode_soft'),
                  style: GoogleFonts.manrope(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEasy
                      ? t('adaptive_calibration_effects_hard')
                      : t('adaptive_calibration_effects_soft'),
                  style: GoogleFonts.manrope(
                    color: scheme.onSurface,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('adaptive_calibration_prompt'),
            style: GoogleFonts.manrope(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('adaptive_calibration_dismiss')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final effectId = isEasy ? 'adaptive_hard' : 'adaptive_soft';
            final buff = Buff(
              effectId: effectId,
              value: isEasy ? 1.5 : 1.3,
              expiresAt: DateTime.now().add(const Duration(hours: 24)),
            );
            await ref.read(hunterProvider.notifier).addBuff(buff);

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEasy
                        ? t('adaptive_calibration_snack_hard')
                        : t('adaptive_calibration_snack_soft'),
                  ),
                  backgroundColor: accent,
                ),
              );
            }
          },
          child: Text(t('adaptive_calibration_confirm')),
        ),
      ],
    );
  }
}
