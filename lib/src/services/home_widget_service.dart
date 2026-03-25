import 'package:home_widget/home_widget.dart';

import '../models/hunter_model.dart';
import '../models/quest_model.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const String _androidWidgetName = 'HunterStatusWidget';

  static Future<void> update({
    required Hunter? hunter,
    required List<Quest> quests,
  }) async {
    // Fallback: если охотник не создан — показываем приглашение.
    final title = hunter == null ? 'Создай охотника' : hunter.name;
    final level = hunter?.level ?? 0;
    final gold = hunter?.gold ?? 0;

    // Мини-список ежедневных активных квестов (до 3).
    final daily = quests
        .where((q) => q.type == QuestType.daily && q.status == QuestStatus.active && !q.isExpired)
        .take(3)
        .map((q) => q.title)
        .toList();

    await HomeWidget.saveWidgetData<String>('title', title);
    await HomeWidget.saveWidgetData<int>('level', level);
    await HomeWidget.saveWidgetData<int>('gold', gold);
    await HomeWidget.saveWidgetData<String>('daily1', daily.length >= 1 ? daily[0] : '');
    await HomeWidget.saveWidgetData<String>('daily2', daily.length >= 2 ? daily[1] : '');
    await HomeWidget.saveWidgetData<String>('daily3', daily.length >= 3 ? daily[2] : '');

    // Android: обновляем инстансы.
    await HomeWidget.updateWidget(name: _androidWidgetName);
  }
}

