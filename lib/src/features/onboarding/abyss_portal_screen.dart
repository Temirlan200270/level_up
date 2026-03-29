import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../core/translations.dart';
import 'onboarding_atmosphere.dart';

/// Экран 0: ритуал входа до портала лора (Project Overlord).
class AbyssPortalScreen extends ConsumerWidget {
  const AbyssPortalScreen({super.key, required this.onEnterAbyss});

  final Future<void> Function() onEnterAbyss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: OnboardingLoreAtmosphere()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    scheme.primary.withValues(alpha: 0.12),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('abyss_portal_label'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.2,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Lottie.asset(
                              'assets/lottie/level_up.json',
                              repeat: true,
                              frameRate: FrameRate.max,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.blur_circular_rounded,
                                size: 96,
                                color: scheme.primary.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            t('abyss_portal_title'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('abyss_portal_subtitle'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await onEnterAbyss();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      t('abyss_portal_cta'),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.12, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
