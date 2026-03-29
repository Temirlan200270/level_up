import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/systems/system_id.dart';
import '../../../core/translations.dart';
import '../../../models/hunter_model.dart';
import '../../../services/providers.dart';

/// Приоритет реплики: черновик команды → Святилище → статы.
String _effectiveThoughtKey(WidgetRef ref, Hunter? hunter) {
  final draft = ref.watch(masterCommandTypingThoughtKeyProvider);
  if (draft != null && draft.isNotEmpty) return draft;
  final systemId = ref.watch(activeSystemIdProvider);
  return MasterThoughts.thoughtKeyForHunter(hunter, systemId);
}

/// Реплика Мастера над командной строкой (контекст от статов охотника).
class MasterThoughts extends ConsumerWidget {
  const MasterThoughts({super.key});

  /// Ключ перевода по состоянию охотника и активной философии.
  static String thoughtKeyForHunter(Hunter? hunter, SystemId systemId) {
    if (hunter == null) return 'master_thought_idle';
    if (hunter.isSanctuaryActive) {
      switch (systemId) {
        case SystemId.solo:
          return 'master_thought_sanctuary_solo';
        case SystemId.mage:
          return 'master_thought_sanctuary_mage';
        case SystemId.cultivator:
          return 'master_thought_sanctuary_cultivator';
        case SystemId.custom:
          return 'master_thought_sanctuary_custom';
      }
    }
    final s = hunter.stats;
    final vit = s.vitality;
    final intel = s.intelligence;
    final str = s.strength;
    // Низкая живучесть относительно силы — «сосуд истощён».
    if (vit < str && vit <= 4) {
      return 'master_thought_low_vitality';
    }
    if (intel >= 12 && intel >= str && intel >= s.agility) {
      return 'master_thought_high_intellect';
    }
    return 'master_thought_idle';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunter = ref.watch(hunterProvider);
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final key = _effectiveThoughtKey(ref, hunter);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey<String>(key),
        child: Text(
          t(key),
          style: GoogleFonts.manrope(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
            fontSize: 13,
            height: 1.45,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
