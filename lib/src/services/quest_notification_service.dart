import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/quest_model.dart';
import 'translation_service.dart';

/// Локальные напоминания о дедлайнах активных квестов (не веб).
abstract final class QuestNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static const _channelId = 'quest_deadlines';
  static const _channelName = 'Квесты';

  /// Инициализация канала и timezone (вызывать из `main` после Hive).
  static Future<void> init() async {
    if (kIsWeb) return;
    if (_inited) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    final settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.requestNotificationsPermission();

    _inited = true;
  }

  /// Пересоздать отложенные уведомления по списку квестов.
  static Future<void> rescheduleForActiveQuests(List<Quest> quests) async {
    if (kIsWeb || !_inited) return;

    for (var id = 9000; id < 9100; id++) {
      await _plugin.cancel(id: id);
    }

    final soon = quests.where((q) {
      if (q.status != QuestStatus.active) return false;
      final exp = q.expiresAt;
      if (exp == null) return false;
      if (q.isExpired) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.expiresAt!.compareTo(b.expiresAt!));

    final now = DateTime.now();
    var id = 9000;
    const before = Duration(hours: 2);

    for (final q in soon.take(12)) {
      if (id >= 9100) break;
      final exp = q.expiresAt!;
      final remind = exp.subtract(before);
      if (!remind.isAfter(now)) continue;

      final when = tz.TZDateTime.from(remind, tz.local);
      final title = TranslationService.translate('notif_quest_deadline_title');
      final body = TranslationService.translate(
        'notif_quest_deadline_body',
        params: {'title': q.title},
      );

      try {
        await _plugin.zonedSchedule(
          id: id++,
          scheduledDate: when,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
        );
      } catch (_) {
        id--;
      }
    }
  }
}
