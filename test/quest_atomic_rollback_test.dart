import 'package:level_up/src/models/quest_model.dart';
import 'package:level_up/src/services/database_service.dart';
import 'package:level_up/src/services/providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            final dir = await Directory.systemTemp.createTemp('level_up_test_');
            return dir.path;
          }
          return null;
        });

    // home_widget (unit tests): plugin channel is not registered.
    const homeWidgetChannel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async {
          // We don't need real widget updates in tests.
          return null;
        });
    await DatabaseService.init();
  });

  setUp(() async {
    await DatabaseService.deleteAllQuests();
    await DatabaseService.deleteHunter();
    await DatabaseService.clearGamificationMeta();
    await DatabaseService.createDefaultHunter('Rollback Tester');
  });

  test('runAtomicMutationForTest откатывает состояние после ошибки', () async {
    final quest = Quest(
      id: 'rollback_q1',
      title: 'Rollback probe',
      description: 'Should stay active after failed atomic mutation',
      type: QuestType.special,
      experienceReward: 20,
      goldReward: 10,
      difficulty: 2,
    );
    await DatabaseService.addQuest(quest);
    final beforeHunter = DatabaseService.getHunter();

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(questsProvider.notifier);

    await expectLater(
      notifier.runAtomicMutationForTest(() async {
        await DatabaseService.updateQuest(quest.complete());
        await container.read(hunterProvider.notifier).addGold(500);
        throw Exception('forced rollback');
      }),
      throwsException,
    );

    final afterQuest = DatabaseService.getQuest('rollback_q1');
    final afterHunter = DatabaseService.getHunter();

    expect(afterQuest, isNotNull);
    expect(afterQuest!.status, QuestStatus.active);
    expect(afterHunter, isNotNull);
    expect(afterHunter!.gold, beforeHunter!.gold);
    expect(afterHunter.level, beforeHunter.level);
  });
}
