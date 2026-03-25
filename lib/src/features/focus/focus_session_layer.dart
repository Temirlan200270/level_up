import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/providers.dart';

/// Полупрозрачный оверлей с таймером фокус-сессии (навык «Медитация»).
class FocusSessionLayer extends ConsumerStatefulWidget {
  const FocusSessionLayer({super.key});

  @override
  ConsumerState<FocusSessionLayer> createState() => _FocusSessionLayerState();
}

class _FocusSessionLayerState extends ConsumerState<FocusSessionLayer> {
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _ensureTimer(FocusSessionState? session) {
    _tick?.cancel();
    _tick = null;
    if (session == null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = ref.read(focusSessionProvider);
      if (s != null && DateTime.now().isAfter(s.endsAt)) {
        if (s.closedMeditation && !s.rewardGranted) {
          // Награда за успешную закрытую медитацию (cultivator).
          // Математика пока базовая; дальше будет через SystemRules.
          unawaited(ref.read(hunterProvider.notifier).addExperience(25));
          ref.read(focusSessionProvider.notifier).state =
              s.copyWith(rewardGranted: true);
        }
        ref.read(focusSessionProvider.notifier).state = null;
        _tick?.cancel();
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusSessionProvider);
    if (session == null) {
      _tick?.cancel();
      _tick = null;
      return const SizedBox.shrink();
    }

    if (_tick == null || !_tick!.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureTimer(session);
      });
    }

    final t = useTranslations(ref);
    final now = DateTime.now();
    if (now.isAfter(session.endsAt)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(focusSessionProvider.notifier).state = null;
      });
      return const SizedBox.shrink();
    }

    final left = session.endsAt.difference(now);
    final mm = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = left.inHours;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.closedMeditation
                        ? t('focus_session_title_closed')
                        : t('focus_session_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: SoloLevelingColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.closedMeditation
                        ? t('focus_session_hint_closed')
                        : t('focus_session_hint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SoloLevelingColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!session.closedMeditation)
                    TextButton(
                      onPressed: () {
                        ref.read(focusSessionProvider.notifier).state = null;
                        _tick?.cancel();
                      },
                      child: Text(t('focus_session_dismiss')),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
