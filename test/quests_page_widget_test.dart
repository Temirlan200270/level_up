import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:level_up/src/core/theme.dart';
import 'package:level_up/src/features/quests/quests_page.dart';
import 'package:level_up/src/services/database_service.dart';
import 'package:level_up/src/services/translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        final dir = await Directory.systemTemp.createTemp('level_up_quests_ui_');
        return dir.path;
      }
      return null;
    });

    const homeWidgetChannel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async {
      return null;
    });

    await DatabaseService.init();
  });

  setUp(() async {
    await DatabaseService.deleteAllQuests();
    await DatabaseService.deleteHunter();
    await DatabaseService.clearGamificationMeta();
    await DatabaseService.createDefaultHunter('Quests UI Tester');
    await TranslationService.loadTranslations('ru');
  });

  testWidgets(
    'QuestsPage smoke (NestedScrollView)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.forSkinId('solo'),
            home: const QuestsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(QuestsPage), findsOneWidget);
      expect(find.byType(NestedScrollView), findsOneWidget);
    },
    skip: true, // Manrope через google_fonts без ttf в assets — тест падает без сети/шрифтов.
  );
}
