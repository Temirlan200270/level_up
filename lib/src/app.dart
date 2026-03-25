import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/system_visuals_extension.dart';
import 'core/systems/system_id.dart';
import 'core/translations.dart';
import 'core/feedback_overlay.dart';
import 'features/hunter/hunter_profile_page.dart';
import 'features/quests/quests_page.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/skills/skills_screen.dart';
import 'features/activities/activities_screen.dart';
import 'features/guild/guild_hub_screen.dart';
import 'features/settings/settings_page.dart';
import 'features/focus/focus_session_layer.dart';
import 'features/system/system_selection_screen.dart';
import 'services/database_service.dart';
import 'services/providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData _replaceSystemVisuals(ThemeData base, SystemVisuals visuals) {
    final cur = base.extensions.values.toList();
    cur.removeWhere((e) => e is SystemVisuals);
    cur.add(visuals);
    return base.copyWith(extensions: cur);
  }

  SystemBackgroundKind _parseBgKind(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'parchment':
        return SystemBackgroundKind.parchment;
      case 'mist':
        return SystemBackgroundKind.mist;
      case 'grid':
      default:
        return SystemBackgroundKind.grid;
    }
  }

  SystemParticlesKind _parseParticles(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'runes':
        return SystemParticlesKind.runes;
      case 'petals':
        return SystemParticlesKind.petals;
      case 'none':
        return SystemParticlesKind.none;
      case 'sparkles':
      default:
        return SystemParticlesKind.sparkles;
    }
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
      final baseVisuals = theme.extension<SystemVisuals>() ??
          const SystemVisuals(
            backgroundKind: SystemBackgroundKind.grid,
            backgroundAssetPath: '',
            particlesKind: SystemParticlesKind.none,
            panelRadius: 12,
            panelBorderWidth: 1,
            titleLetterSpacing: 2.2,
          );

      final bgAsset =
          DatabaseService.getCustomSystemBackgroundAssetPathForSlug(customSlug);
      final bgKindRaw =
          DatabaseService.getCustomSystemBackgroundKindForSlug(customSlug);
      final particlesRaw =
          DatabaseService.getCustomSystemParticlesKindForSlug(customSlug);
      final radius =
          DatabaseService.getCustomSystemPanelRadiusForSlug(customSlug);

      final next = baseVisuals.copyWith(
        backgroundAssetPath: (bgAsset == null || bgAsset.trim().isEmpty)
            ? baseVisuals.backgroundAssetPath
            : bgAsset.trim(),
        backgroundKind: _parseBgKind(bgKindRaw),
        particlesKind: _parseParticles(particlesRaw),
        panelRadius: radius ?? baseVisuals.panelRadius,
      );
      theme = _replaceSystemVisuals(theme, next);
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
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _systemSelectionScheduled = false;

  final _pages = [
    const HunterProfilePage(),
    const QuestsPage(),
    const InventoryScreen(),
    const GuildHubScreen(),
    const ActivitiesScreen(),
    const SkillsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final hunter = ref.watch(hunterProvider);
    final systemId = ref.watch(activeSystemIdProvider);

    if (!_systemSelectionScheduled &&
        hunter != null &&
        !DatabaseService.isSystemSelectionShown()) {
      _systemSelectionScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SystemSelectionScreen(isFirstRun: true),
          ),
        );
      });
    }

    String navLabel(int index) {
      // Терминология навигации — часть “философии”, не просто перевод.
      return switch (systemId) {
        SystemId.solo => switch (index) {
            0 => 'Профиль',
            1 => 'Квесты',
            2 => 'Инвентарь',
            3 => 'Гильдия',
            4 => 'Подземелья',
            _ => 'Навыки',
          },
        SystemId.mage => switch (index) {
            0 => 'Медитация',
            1 => 'Заклинания',
            2 => 'Хранилище',
            3 => 'Орден',
            4 => 'Башня',
            _ => 'Таланты',
          },
        SystemId.cultivator => switch (index) {
            0 => 'Дао',
            1 => 'Испытания',
            2 => 'Артефакты',
            3 => 'Секта',
            4 => 'Небеса',
            _ => 'Техники',
          },
        SystemId.custom => switch (index) {
            0 => t('nav_profile'),
            1 => t('nav_quests'),
            2 => t('nav_inventory'),
            3 => t('guild_hub_title'),
            4 => 'Активности',
            _ => t('nav_skills'),
          },
      };
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            // Короткие подписи nav_* + только у выбранной вкладки — без переноса по буквам.
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            surfaceTintColor: Colors.transparent,
            indicatorColor:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.42),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.person),
                label: navLabel(0),
                tooltip: t('profile'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment),
                label: navLabel(1),
                tooltip: t('quests'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.inventory_2),
                label: navLabel(2),
                tooltip: t('inventory'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_rounded),
                label: navLabel(3),
                tooltip: t('guild_hub_title'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_rounded),
                label: navLabel(4),
                tooltip: t('activities_title'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome),
                label: navLabel(5),
                tooltip: t('skills'),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, right: 12),
            child: Align(
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                      semanticLabel: t('settings'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const FeedbackOverlayLayer(),
        const FocusSessionLayer(),
      ],
    );
  }
}
