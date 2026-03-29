import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../systems/system_dictionary.dart';
import '../translations.dart';
import '../../services/providers.dart';

/// Полноэкранная реплика Мастера при блокировке Лаборатории (голос Системы, не SnackBar).
Future<void> showLaboratoryMasterLockDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final systemId = ref.read(activeSystemIdProvider);
  final rules = ref.read(activeSystemRulesProvider);
  final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
  final t = useTranslations(ref);
  final bodyKey = 'laboratory_master_lock_${nav.name}';

  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.94),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, animation, secondary) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.psychology_alt_rounded,
                    size: 48,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t('laboratory_master_lock_title'),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        t(bodyKey),
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t('close'),
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
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

/// Одноразовая реплика Мастера при первом доступе к Лаборатории (ур. 10 / веха).
Future<void> showLaboratoryUnlockMasterDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final systemId = ref.read(activeSystemIdProvider);
  final rules = ref.read(activeSystemRulesProvider);
  final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
  final t = useTranslations(ref);
  final bodyKey = 'laboratory_unlock_master_${nav.name}';

  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.94),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, animation, secondary) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hub_rounded,
                    size: 48,
                    color: scheme.secondary.withValues(alpha: 0.95),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t('laboratory_unlock_master_title'),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        t(bodyKey),
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t('close'),
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
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
