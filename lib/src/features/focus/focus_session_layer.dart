import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/translations.dart';
import '../../services/database_service.dart';
import '../../services/providers.dart';

/// Полупрозрачный оверлей с таймером фокус-сессии (навык «Медитация»).
class FocusSessionLayer extends ConsumerStatefulWidget {
  const FocusSessionLayer({super.key});

  @override
  ConsumerState<FocusSessionLayer> createState() => _FocusSessionLayerState();
}

class _FocusSessionLayerState extends ConsumerState<FocusSessionLayer> {
  Timer? _tick;
  /// Ключ сессии, для которой уже выполнен естественный выход (таймер → один зачёт).
  String? _naturalEndClaimedKey;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _sessionKey(FocusSessionState s) =>
      '${s.endsAt.toIso8601String()}_${s.plannedDurationSeconds}_${s.closedMeditation}';

  /// Защита от двойного зачёта гильдии/награды при гонке таймера и кадра.
  void _maybeRecordGuildFocusRaid(FocusSessionState s) {
    if (s.plannedDurationSeconds < 60) return;
    // Ключ хранится в замыкании async — дубли по тем же endsAt/planned не пишем в Hive.
    _GuildRaidDedupe.instance.tryRecord(s, () async {
      await DatabaseService.recordGuildFocusRaidCompletion(
        s.plannedDurationSeconds,
      );
      if (mounted) {
        ref.read(settingsMetaRefreshProvider.notifier).state++;
        ref.read(livingHeaderPulseProvider.notifier).state++;
      }
    });
  }

  void _onFocusSessionNaturalEnd(FocusSessionState s) {
    final key = _sessionKey(s);
    if (_naturalEndClaimedKey == key) return;
    _naturalEndClaimedKey = key;

    _maybeRecordGuildFocusRaid(s);
    if (s.closedMeditation && !s.rewardGranted) {
      unawaited(ref.read(hunterProvider.notifier).addExperience(25));
    }

    _tick?.cancel();
    _tick = null;

    // Сброс провайдера после кадра — не во время build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(focusSessionProvider.notifier).state = null;
      setState(() {});
    });
  }

  void _ensureTimer(FocusSessionState session) {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = ref.read(focusSessionProvider);
      if (s != null && DateTime.now().isAfter(s.endsAt)) {
        _onFocusSessionNaturalEnd(s);
      } else {
        setState(() {});
      }
    });
    // Если дедлайн уже прошёл до старта таймера — один вызов без дубля из build.
    if (DateTime.now().isAfter(session.endsAt)) {
      _onFocusSessionNaturalEnd(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusSessionProvider);
    if (session == null) {
      _tick?.cancel();
      _tick = null;
      _naturalEndClaimedKey = null;
      _GuildRaidDedupe.instance.reset();
      return const SizedBox.shrink();
    }

    if (_tick == null || !_tick!.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final s = ref.read(focusSessionProvider);
        if (s != null) _ensureTimer(s);
      });
    }

    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    if (now.isAfter(session.endsAt)) {
      // Только планирование таймера; завершение делает [Timer] или немедленная ветка в [_ensureTimer].
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
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.closedMeditation
                        ? t('focus_session_title_closed')
                        : t('focus_session_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onSurface,
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
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!session.closedMeditation)
                    TextButton(
                      onPressed: () {
                        ref.read(focusSessionProvider.notifier).state = null;
                        _tick?.cancel();
                        _naturalEndClaimedKey = null;
                        _GuildRaidDedupe.instance.reset();
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

/// Синглтон на время жизни слоя: не записывать рейд дважды для одной пары endsAt+planned.
class _GuildRaidDedupe {
  _GuildRaidDedupe._();
  static final _GuildRaidDedupe instance = _GuildRaidDedupe._();

  String? _lastKey;
  bool _inFlight = false;

  void reset() {
    _lastKey = null;
    _inFlight = false;
  }

  Future<void> tryRecord(
    FocusSessionState s,
    Future<void> Function() run,
  ) async {
    final key =
        '${s.endsAt.toIso8601String()}_${s.plannedDurationSeconds}';
    if (_lastKey == key || _inFlight) return;
    _lastKey = key;
    _inFlight = true;
    try {
      await run();
    } finally {
      _inFlight = false;
    }
  }
}
