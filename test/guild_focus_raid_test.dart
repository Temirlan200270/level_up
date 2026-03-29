import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:level_up/src/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        final dir = await Directory.systemTemp.createTemp('level_up_gfr_');
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

  tearDown(() async {
    final box = Hive.box(DatabaseService.settingsBox);
    await box.delete('guild_focus_raid_month_v1');
    await box.delete('guild_focus_raid_personal_min_v1');
    await box.delete('guild_focus_raid_sim_min_v1');
    await box.delete('guild_focus_raid_guild_xp_v1');
  });

  test('recordGuildFocusRaidCompletion увеличивает личные минуты и Guild XP', () async {
    await DatabaseService.recordGuildFocusRaidCompletion(3600);
    final snap = await DatabaseService.getGuildFocusRaidSnapshot();
    expect(snap.personalFocusMinutesMonth, 60);
    expect(snap.guildXp, greaterThan(0));
    expect(snap.guildLevel, greaterThanOrEqualTo(1));
  });

  test('короткая сессия (<60 с) не засчитывается', () async {
    await DatabaseService.recordGuildFocusRaidCompletion(30);
    final snap = await DatabaseService.getGuildFocusRaidSnapshot();
    expect(snap.personalFocusMinutesMonth, 0);
  });

  test('getGuildGoldBonusMultiplier не ниже 1.0', () {
    expect(DatabaseService.getGuildGoldBonusMultiplier(), greaterThanOrEqualTo(1.0));
  });
}
