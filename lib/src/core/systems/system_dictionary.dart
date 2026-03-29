import 'system_id.dart';
import 'system_rules.dart';

class SystemDictionary {
  const SystemDictionary({
    required this.levelName,
    required this.experienceName,
    required this.currencyName,
    required this.energyName,
    required this.skillsName,
  });

  final String levelName;
  final String experienceName;
  final String currencyName;
  final String energyName;
  final String skillsName;
}

/// Подписи вкладок главного экрана по философии (индексы совпадают с [HomeShell]).
abstract final class SystemHomeNavLabels {
  SystemHomeNavLabels._();

  /// Какую ветку терминов использовать для навигации (кастом наследует пресет правил).
  static SystemId effectiveNavSystemId(SystemId id, SystemRules rules) {
    if (id != SystemId.custom) return id;
    final base = rules is CustomRules ? rules.base : rules;
    if (base is MageRules) return SystemId.mage;
    if (base is CultivatorRules) return SystemId.cultivator;
    return SystemId.solo;
  }

  /// Короткий label для [NavigationDestination] / заголовков замка.
  static String tabLabel({
    required SystemId systemId,
    required SystemRules rules,
    required int index,
    required String Function(String key, {Map<String, String>? params}) t,
  }) {
    final navId = effectiveNavSystemId(systemId, rules);
    return switch (navId) {
      SystemId.solo => switch (index) {
          0 => 'Профиль',
          1 => 'Квесты',
          2 => 'Инвентарь',
          3 => 'Гильдия',
          4 => 'Подземелья',
          _ => 'Навыки',
        },
      SystemId.mage => switch (index) {
          0 => 'Гримуар',
          1 => 'Задачи',
          2 => 'Артефакты',
          3 => 'Орден',
          4 => 'Башня',
          _ => 'Таланты',
        },
      SystemId.cultivator => switch (index) {
          0 => 'Дао',
          1 => 'Испытания',
          2 => 'Кольцо',
          3 => 'Секта',
          4 => 'Небеса',
          _ => 'Техники',
        },
      SystemId.custom => switch (index) {
          0 => t('nav_profile'),
          1 => t('nav_quests'),
          2 => t('nav_inventory'),
          3 => t('guild_hub_title'),
          4 => t('activities_title'),
          _ => t('nav_skills'),
        },
    };
  }
}

