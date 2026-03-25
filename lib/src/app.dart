
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/translations.dart';
import 'features/hunter/hunter_profile_page.dart';
import 'features/quests/quests_page.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/skills/skills_screen.dart';
import 'features/settings/settings_page.dart';
import 'services/providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final locale = language == 'en' ? const Locale('en', 'US') : const Locale('ru', 'RU');
    
    return MaterialApp(
      title: 'Solo Leveling System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Только тёмная тема
      locale: locale,
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
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

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  final _pages = [
    const HunterProfilePage(),
    const QuestsPage(),
    const InventoryScreen(),
    const ShopScreen(),
    const SkillsScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.person),
              label: t('profile'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment),
              label: t('quests'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2),
              label: t('inventory'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.shopping_cart),
              label: t('shop'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome),
              label: t('skills'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings),
              label: t('settings'),
            ),
          ],
      ),
    );
  }
}
