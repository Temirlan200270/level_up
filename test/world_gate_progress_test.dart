import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/models/quest_model.dart';
import 'package:level_up/src/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        final dir = await Directory.systemTemp.createTemp('level_up_wg_');
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
    await DatabaseService.createDefaultHunter('WG Tester');
  });

  test('recordWorldGateContributionFromQuest учитывает спортивный квест', () async {
    final before = await DatabaseService.getWorldGateSnapshot();
    final sportQuest = Quest(
      title: 'Пробежка',
      description: 'Лёгкий run в парке',
      type: QuestType.daily,
      tags: const ['sport'],
      experienceReward: 10,
      difficulty: 3,
    );
    await DatabaseService.recordWorldGateContributionFromQuest(sportQuest);
    final after = await DatabaseService.getWorldGateSnapshot();
    expect(after.personalContribution, greaterThan(before.personalContribution));
  });

  test('recordWorldGateContributionFromQuest игнорирует нематериальный квест', () async {
    final before = await DatabaseService.getWorldGateSnapshot();
    final mental = Quest(
      title: 'Чтение',
      description: 'Книга по психологии',
      type: QuestType.daily,
      tags: const ['mind'],
      experienceReward: 10,
      difficulty: 2,
    );
    await DatabaseService.recordWorldGateContributionFromQuest(mental);
    final after = await DatabaseService.getWorldGateSnapshot();
    expect(after.personalContribution, before.personalContribution);
  });
}
