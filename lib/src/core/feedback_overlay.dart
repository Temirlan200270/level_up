import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import 'theme.dart';

enum FeedbackOverlayKind { levelUp, legendaryLoot }

class FeedbackOverlayEvent {
  const FeedbackOverlayEvent({
    required this.kind,
    required this.id,
  });

  final FeedbackOverlayKind kind;
  final int id;
}

final feedbackOverlayProvider =
    StateNotifierProvider<FeedbackOverlayNotifier, FeedbackOverlayEvent?>(
  (ref) => FeedbackOverlayNotifier(),
);

class FeedbackOverlayNotifier extends StateNotifier<FeedbackOverlayEvent?> {
  FeedbackOverlayNotifier() : super(null);
  int _seq = 0;
  Timer? _t;

  void show(FeedbackOverlayKind kind) {
    _t?.cancel();
    _seq++;
    state = FeedbackOverlayEvent(kind: kind, id: _seq);
    _t = Timer(const Duration(milliseconds: 900), () => state = null);
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
      FeedbackOverlayKind.legendaryLoot => 'assets/lottie/level_up.json',
    };

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 120),
        child: Center(
          child: Container(
            width: 220,
            height: 220,
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
                  color: SoloLevelingColors.textPrimary,
                  size: 64,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

