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
        final dir = await Directory.systemTemp.createTemp('level_up_lb_');
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
    await DatabaseService.createDefaultHunter('LB Tester');
  });

  test('getLeaderboardLocalStats считает сюжет и победы без штрафов', () async {
    await DatabaseService.addQuest(
      Quest(
        title: 'Сюжет 1',
        description: 'd',
        type: QuestType.story,
        status: QuestStatus.completed,
        experienceReward: 1,
      ),
    );
    await DatabaseService.addQuest(
      Quest(
        title: 'Дейли',
        description: 'd',
        type: QuestType.daily,
        status: QuestStatus.completed,
        experienceReward: 1,
      ),
    );
    await DatabaseService.addQuest(
      Quest(
        title: 'Штраф',
        description: 'd',
        type: QuestType.penalty,
        status: QuestStatus.completed,
        experienceReward: 0,
      ),
    );

    final s = DatabaseService.getLeaderboardLocalStats();
    expect(s.storyCompleted, 1);
    expect(s.nonPenaltyCompleted, 2);
  });
}
