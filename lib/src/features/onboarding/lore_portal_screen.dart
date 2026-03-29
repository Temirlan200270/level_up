import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/translations.dart';
import 'onboarding_atmosphere.dart';
import 'typewriter_text.dart';

/// Портал лора (Фаза 7.5): первый экран онбординга до выбора философии.
class LorePortalScreen extends ConsumerWidget {
  const LorePortalScreen({
    super.key,
    required this.onContinue,
  });

  /// Переход к выбору философии (родитель проигрывает вспышку и шаг state machine).
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Реальный арт портала (Фаза 7.5): SVG фон + затемнение; при сбое ассета — только атмосфера.
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  'assets/backgrounds/solo_bg.svg',
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => const SizedBox.shrink(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: OnboardingLoreAtmosphere(),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            Text(
              t('lore_portal_label'),
              style: promoAppBarTitleStyle(context).copyWith(
                color: Colors.white.withValues(alpha: 0.35),
                letterSpacing: 4,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TypewriterText(
                      text: t('lore_portal_typewriter'),
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        height: 1.6,
                        shadows: [
                          Shadow(
                            color: scheme.secondary.withValues(alpha: 0.8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      charDelay: const Duration(milliseconds: 38),
                    ),
                    const Spacer(),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 5),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value > 0.8 ? (value - 0.8) * 5 : 0.0,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: OutlinedButton(
                        onPressed: () async {
                          await onContinue();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: scheme.secondary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          t('lore_portal_cta'),
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
