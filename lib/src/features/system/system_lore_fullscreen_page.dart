import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/systems/system_id.dart';
import '../onboarding/typewriter_text.dart';

class SystemLoreFullscreenPage extends ConsumerWidget {
  const SystemLoreFullscreenPage({
    super.key,
    required this.systemId,
    required this.title,
  });

  final SystemId systemId;
  final String title;

  String _loreKey(SystemId id) => switch (id) {
        SystemId.solo => 'lore_solo',
        SystemId.mage => 'lore_mage',
        SystemId.cultivator => 'lore_cultivator',
        SystemId.custom => 'lore_custom',
      };

  String _bgAsset(SystemId id) => switch (id) {
        SystemId.solo => 'assets/backgrounds/solo_bg.svg',
        SystemId.mage => 'assets/backgrounds/archmage_bg.svg',
        SystemId.cultivator => 'assets/backgrounds/cultivation_bg.svg',
        SystemId.custom => 'assets/backgrounds/archmage_bg.svg',
      };

  Color _accent(ColorScheme scheme, SystemId id) => switch (id) {
        SystemId.solo => scheme.secondary,
        SystemId.mage => scheme.primary,
        SystemId.cultivator => scheme.tertiary,
        SystemId.custom => scheme.secondary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(scheme, systemId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              _bgAsset(systemId),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: t('back'),
                      ),
                      Expanded(
                        child: Text(
                          t('system_lore_title'),
                          style: promoAppBarTitleStyle(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    builder: (context, v, child) {
                      return Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, (1 - v) * 10),
                          child: child,
                        ),
                      );
                    },
                    child: ProfileNeonCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.manrope(
                                    color: SoloLevelingColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TypewriterText(
                            text: t(_loreKey(systemId)),
                            charDelay: const Duration(milliseconds: 12),
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textSecondary,
                              height: 1.55,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.92),
                      foregroundColor: scheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(t('back')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

