import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/progression_gates.dart';
import 'core/widgets/system_locked_screen.dart';
import 'core/system_visuals_extension.dart';
import 'core/systems/system_id.dart';
import 'core/systems/system_dictionary.dart';
import 'core/translations.dart';
import 'core/feedback_overlay.dart';
import 'core/widgets/laboratory_master_lock_dialog.dart';
import 'features/hunter/hunter_profile_page.dart';
import 'features/quests/quests_page.dart';
import 'features/quests/widgets/adaptive_calibration_dialog.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/skills/skills_screen.dart';
import 'features/activities/activities_screen.dart';
import 'features/guild/guild_hub_screen.dart';
import 'features/settings/settings_page.dart';
import 'features/focus/focus_session_layer.dart';
import 'features/onboarding/onboarding_journey_screen.dart';
import 'models/hunter_model.dart';
import 'services/database_service.dart';
import 'services/providers.dart';
import 'services/evaluators/adaptive_difficulty_service.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData _replaceSystemVisuals(ThemeData base, SystemVisuals visuals) {
    final cur = base.extensions.values.toList();
    cur.removeWhere((e) => e is SystemVisuals);
    cur.add(visuals);
    return base.copyWith(extensions: cur);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final skinId = ref.watch(themeSkinIdProvider);
    final systemId = ref.watch(activeSystemIdProvider);
    ref.watch(settingsMetaRefreshProvider);
    final customSlug = systemId == SystemId.custom
        ? ref.watch(activeCustomSlugProvider)
        : null;
    final locale = language == 'en'
        ? const Locale('en', 'US')
        : const Locale('ru', 'RU');

    var theme = AppTheme.forSkinId(skinId);
    if (systemId == SystemId.custom && customSlug != null) {
      final baseVisuals =
          theme.extension<SystemVisuals>() ?? SystemVisuals.fallback;

      final bgAsset = DatabaseService.getCustomSystemBackgroundAssetPathForSlug(
        customSlug,
      );
      final bgKindRaw = DatabaseService.getCustomSystemBackgroundKindForSlug(
        customSlug,
      );
      final particlesRaw = DatabaseService.getCustomSystemParticlesKindForSlug(
        customSlug,
      );
      final radius = DatabaseService.getCustomSystemPanelRadiusForSlug(
        customSlug,
      );

      final next = baseVisuals.copyWith(
        backgroundAssetPath: (bgAsset == null || bgAsset.trim().isEmpty)
            ? baseVisuals.backgroundAssetPath
            : bgAsset.trim(),
        backgroundKind: SystemBackgroundKind.fromCustomStored(bgKindRaw),
        particlesKind: SystemParticlesKind.fromCustomStored(particlesRaw),
        panelRadius: radius ?? baseVisuals.panelRadius,
      );
      theme = _replaceSystemVisuals(theme, next);
    }

    if (DatabaseService.isLowFxModeEnabled()) {
      final v = theme.extension<SystemVisuals>() ?? SystemVisuals.fallback;
      theme = _replaceSystemVisuals(theme, v.applyLowFxMerge());
    }

    return MaterialApp(
      title: 'Solo Leveling System',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.dark, // Только тёмная тема
      locale: locale,
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AppRoot(),
    );
  }
}

/// Первый запуск: сразу портал лора без кадра «дома» с квестами под низом.
class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _hunterRecoveryScheduled = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsMetaRefreshProvider);
    final hunter = ref.watch(hunterProvider);
    final step = DatabaseService.getOnboardingStep();

    // Завершён онбординг, но профиля нет (битый сейв / сбой десериализации) —
    // иначе остаёмся на заглушке «Онбординг завершён» внутри Journey.
    if (hunter == null && step == OnboardingStep.done) {
      if (!_hunterRecoveryScheduled) {
        _hunterRecoveryScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_ensureHunterAfterCompletedOnboarding());
        });
      }
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                useTranslations(ref)('onboarding_recovery_loading'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    _hunterRecoveryScheduled = false;

    if (hunter == null || step != OnboardingStep.done) {
      return const OnboardingJourneyScreen();
    }
    return const HomeShell();
  }

  Future<void> _ensureHunterAfterCompletedOnboarding() async {
    if (!mounted) return;
    if (DatabaseService.getOnboardingStep() != OnboardingStep.done) {
      if (mounted) setState(() => _hunterRecoveryScheduled = false);
      return;
    }
    if (ref.read(hunterProvider) != null) {
      if (mounted) setState(() => _hunterRecoveryScheduled = false);
      return;
    }
    try {
      final raw = DatabaseService.getOnboardingPersonaRaw();
      String name = 'Игрок';
      if (raw != null) {
        final n = raw['name'] as String?;
        final t = n?.trim() ?? '';
        if (t.isNotEmpty) name = t;
      }
      await DatabaseService.createDefaultHunter(name);
      ref.read(hunterProvider.notifier).reloadFromLocalDb();
    } catch (_) {
      await DatabaseService.createDefaultHunter('Игрок');
      ref.read(hunterProvider.notifier).reloadFromLocalDb();
    }
    if (mounted) setState(() => _hunterRecoveryScheduled = false);
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  bool _labUnlockHintInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdaptiveDifficulty();
    });
  }

  Future<void> _checkAdaptiveDifficulty() async {
    if (!mounted) return;

    // Убедимся, что онбординг завершен
    final step = DatabaseService.getOnboardingStep();
    if (step != OnboardingStep.done) return;

    // Проверяем, нужно ли показывать диалог калибровки
    if (!AdaptiveDifficultyService.shouldPromptCalibration()) return;

    final systemId = ref.read(activeSystemIdProvider);
    final evaluation = AdaptiveDifficultyService.evaluate(
      7,
      systemId: systemId,
    );
    if (evaluation.status != AdaptiveDifficultyStatus.balanced) {
      // Отмечаем, что показали, чтобы не спамить
      await AdaptiveDifficultyService.markPromptShown();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AdaptiveCalibrationDialog(evaluation: evaluation),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DatabaseService.refreshWorldEventState();
      ref.read(worldEventTickProvider.notifier).state++;
      _checkAdaptiveDifficulty();
    }
  }

  Future<void> _tryLaboratoryUnlockMasterHint() async {
    if (_labUnlockHintInFlight || !mounted) return;
    if (DatabaseService.hasSeenLaboratoryUnlockMasterHint()) return;
    final h = ref.read(hunterProvider);
    if (h == null) return;
    final completed = ref.read(completedQuestsProvider);
    final gate10 =
        completed.any((q) => q.tags.contains('story_gate_10'));
    final open = ProgressionGates.canOpenLaboratory(
      hunterLevel: h.level,
      philosophyPickerIsFirstRun: false,
      completedStoryGate10: gate10,
    );
    if (!open) return;
    _labUnlockHintInFlight = true;
    if (!mounted) return;
    await showLaboratoryUnlockMasterDialog(context, ref);
    await DatabaseService.setSeenLaboratoryUnlockMasterHint();
    _labUnlockHintInFlight = false;
  }

  void _scheduleFeatureUnlockHint(int tabIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final level = ref.read(hunterProvider)?.level ?? 1;
      final consumed = await DatabaseService.tryConsumeFeatureUnlockHint(
        tabIndex: tabIndex,
        hunterLevel: level,
      );
      if (!mounted || !consumed) return;
      final t = useTranslations(ref);
      final msg = switch (tabIndex) {
        2 => t('unlock_hint_inventory'),
        3 => t('unlock_hint_guild'),
        4 => t('unlock_hint_dungeons'),
        5 => t('unlock_hint_skills'),
        _ => '',
      };
      if (msg.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final hunter = ref.watch(hunterProvider);
    final systemId = ref.watch(activeSystemIdProvider);
    final systemRules = ref.watch(activeSystemRulesProvider);
    final tabIndex = ref.watch(homeTabIndexProvider);

    ref.listen<Hunter?>(hunterProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_tryLaboratoryUnlockMasterHint());
      });
    });

    ref.listen<int>(adaptiveCalibrationTickProvider, (prev, next) {
      if (prev != null && prev != next) {
        _checkAdaptiveDifficulty();
      }
    });

    String navLabel(int index) => SystemHomeNavLabels.tabLabel(
          systemId: systemId,
          rules: systemRules,
          index: index,
          t: t,
        );

    final level = hunter?.level ?? 1;

    final pages = [
      const HunterProfilePage(),
      const QuestsPage(),
      level >= ProgressionGates.inventoryMinLevel
          ? const InventoryScreen()
          : SystemLockedScreen(
              title: navLabel(2),
              requiredLevel: ProgressionGates.inventoryMinLevel,
              currentLevel: level,
              rewardPreview: t(
                'home_lock_reward_inventory',
                params: {'feature': navLabel(2)},
              ),
            ),
      level >= ProgressionGates.guildMinLevel
          ? const GuildHubScreen()
          : SystemLockedScreen(
              title: navLabel(3),
              requiredLevel: ProgressionGates.guildMinLevel,
              currentLevel: level,
              rewardPreview: t(
                'home_lock_reward_guild',
                params: {'feature': navLabel(3)},
              ),
            ),
      level >= ProgressionGates.dungeonsMinLevel
          ? const ActivitiesScreen()
          : SystemLockedScreen(
              title: navLabel(4),
              requiredLevel: ProgressionGates.dungeonsMinLevel,
              currentLevel: level,
              rewardPreview: t(
                'home_lock_reward_dungeons',
                params: {'feature': navLabel(4)},
              ),
            ),
      level >= ProgressionGates.skillsMinLevel
          ? const SkillsScreen()
          : SystemLockedScreen(
              title: navLabel(5),
              requiredLevel: ProgressionGates.skillsMinLevel,
              currentLevel: level,
              rewardPreview: t(
                'home_lock_reward_skills',
                params: {'feature': navLabel(5)},
              ),
            ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: IndexedStack(index: tabIndex, children: pages),
          floatingActionButton: FloatingActionButton.small(
            heroTag: 'settings_fab',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              );
            },
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.9),
            foregroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(Icons.settings_outlined, semanticLabel: t('settings')),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tabIndex,
            onDestinationSelected: (i) {
              ref.read(homeTabIndexProvider.notifier).state = i;
              _scheduleFeatureUnlockHint(i);
            },
            // Короткие подписи nav_* + только у выбранной вкладки — без переноса по буквам.
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.42),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.person),
                label: navLabel(0),
                tooltip: navLabel(0),
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment),
                label: navLabel(1),
                tooltip: navLabel(1),
              ),
              NavigationDestination(
                icon: const Icon(Icons.inventory_2),
                label: navLabel(2),
                tooltip: navLabel(2),
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_rounded),
                label: navLabel(3),
                tooltip: navLabel(3),
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_rounded),
                label: navLabel(4),
                tooltip: navLabel(4),
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome),
                label: navLabel(5),
                tooltip: navLabel(5),
              ),
            ],
          ),
        ),
        const FeedbackOverlayLayer(),
        const FocusSessionLayer(),
      ],
    );
  }
}
