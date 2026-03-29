import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'database_service.dart';
import 'translation_service.dart';

abstract final class BackgroundTasks {
  static const String expireQuestsTask = 'expire_quests_task_v1';

  /// Инициализация планировщика фоновых задач.
  ///
  /// Важно: iOS может требовать доп. настройку background modes. Мы держим каркас,
  /// чтобы Android “штрафы без UI” работали сразу.
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Android: минимальная периодическая проверка дедлайнов.
    await Workmanager().registerPeriodicTask(
      expireQuestsTask,
      expireQuestsTask,
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(minutes: 10),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  /// Диспетчер фоновых задач (должен быть top-level или static).
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await DatabaseService.init();
        await TranslationService.init();
        await DatabaseService.applyQuestDeadlinesInBackground();
      } catch (_) {
        // Ничего не падаем: фон не должен крашить процесс.
      }
      return Future.value(true);
    });
  }
}

