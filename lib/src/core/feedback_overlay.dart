import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../services/sound_service.dart';

enum FeedbackOverlayKind {
  levelUp,
  legendaryLoot,
  unlock,
  questSuccessMaster,
  questFailMaster,
}

class FeedbackOverlayEvent {
  const FeedbackOverlayEvent({
    required this.kind,
    required this.id,
    this.masterMessage,
  });

  final FeedbackOverlayKind kind;
  final int id;
  /// Текст Мастера под Lottie (Фаза 7.5.2).
  final String? masterMessage;
}

final feedbackOverlayProvider =
    StateNotifierProvider<FeedbackOverlayNotifier, FeedbackOverlayEvent?>(
      (ref) => FeedbackOverlayNotifier(),
    );

class FeedbackOverlayNotifier extends StateNotifier<FeedbackOverlayEvent?> {
  FeedbackOverlayNotifier() : super(null);
  int _seq = 0;
  Timer? _t;

  void show(FeedbackOverlayKind kind, {String? masterMessage}) {
    _t?.cancel();
    _seq++;
    final cap = masterMessage?.trim();
    final hasCaption = cap != null && cap.isNotEmpty;
    state = FeedbackOverlayEvent(
      kind: kind,
      id: _seq,
      masterMessage: hasCaption ? cap : null,
    );
    if (kind != FeedbackOverlayKind.questSuccessMaster &&
        kind != FeedbackOverlayKind.questFailMaster) {
      unawaited(switch (kind) {
        FeedbackOverlayKind.levelUp => SoundService.playLevelUp(),
        FeedbackOverlayKind.legendaryLoot => SoundService.playClick(),
        FeedbackOverlayKind.unlock => SoundService.playAlert(),
        _ => Future<void>.value(),
      });
    }
    final duration = hasCaption
        ? const Duration(milliseconds: 4200)
        : const Duration(milliseconds: 900);
    _t = Timer(duration, () => state = null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

class FeedbackOverlayLayer extends ConsumerWidget {
  const FeedbackOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(feedbackOverlayProvider);
    if (event == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final asset = switch (event.kind) {
      FeedbackOverlayKind.levelUp => 'assets/lottie/level_up.json',
      FeedbackOverlayKind.legendaryLoot =>
        'assets/lottie/loot_drop.json', // Заменено на лут лотти
      FeedbackOverlayKind.unlock =>
        'assets/lottie/unlock.json', // Заменено на анлок лотти
      FeedbackOverlayKind.questSuccessMaster => 'assets/lottie/level_up.json',
      FeedbackOverlayKind.questFailMaster => 'assets/lottie/unlock.json',
    };

    final caption = event.masterMessage;
    final hasCaption = caption != null && caption.isNotEmpty;
    final lottieSize = hasCaption ? 168.0 : 220.0;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 120),
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: lottieSize,
                  height: lottieSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.25),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.25),
                        blurRadius: 40,
                      ),
                    ],
                    border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Lottie.asset(
                    asset,
                    repeat: false,
                    frameRate: FrameRate.max,
                    fit: BoxFit.contain,
                    errorBuilder: (context, _, __) {
                      return Icon(
                        Icons.auto_awesome_rounded,
                        color: scheme.onSurface,
                        size: 52,
                      );
                    },
                  ),
                ),
                if (hasCaption) ...[
                  const SizedBox(height: 14),
                  Material(
                    elevation: 10,
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.94,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Text(
                          caption,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
