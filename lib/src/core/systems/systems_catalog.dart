import 'system_config.dart';
import 'system_dictionary.dart';
import 'system_id.dart';
import 'system_rules.dart';

class SystemsCatalog {
  SystemsCatalog._();

  static SystemConfig forId(SystemId id) {
    switch (id) {
      case SystemId.solo:
        return const SystemConfig(
          id: SystemId.solo,
          dictionary: SystemDictionary(
            levelName: 'Уровень',
            experienceName: 'Опыт',
            currencyName: 'Золото',
            energyName: 'Энергия',
            skillsName: 'Навыки',
          ),
          aiVoiceName: 'Система',
          aiToneHint: 'холодная, лаконичная, как интерфейс',
        );
      case SystemId.mage:
        return const SystemConfig(
          id: SystemId.mage,
          dictionary: SystemDictionary(
            levelName: 'Круг',
            experienceName: 'Мощь',
            currencyName: 'Золото',
            energyName: 'Мана',
            skillsName: 'Заклинания',
          ),
          aiVoiceName: 'Эхо Кодекса',
          aiToneHint: 'мистическая, наблюдающая, задаёт вопросы',
        );
      case SystemId.cultivator:
        return const SystemConfig(
          id: SystemId.cultivator,
          dictionary: SystemDictionary(
            levelName: 'Стадия',
            experienceName: 'Прогресс',
            currencyName: 'Духовные монеты',
            energyName: 'Ци',
            skillsName: 'Техники',
          ),
          aiVoiceName: 'Мастер',
          aiToneHint: 'строгая, мудрая, дисциплина и путь',
        );
      case SystemId.custom:
        return const SystemConfig(
          id: SystemId.custom,
          dictionary: SystemDictionary(
            levelName: 'Уровень',
            experienceName: 'Опыт',
            currencyName: 'Валюта',
            energyName: 'Энергия',
            skillsName: 'Навыки',
          ),
          aiVoiceName: 'Ваш голос',
          aiToneHint: 'задается пользователем',
        );
    }
  }

  static SystemRules rulesForId(SystemId id) {
    switch (id) {
      case SystemId.solo:
        return const SoloRules();
      case SystemId.mage:
        return const MageRules();
      case SystemId.cultivator:
        return const CultivatorRules();
      case SystemId.custom:
        // Безопасный дефолт — solo, пока не будет конструктора правил.
        return const SoloRules();
    }
  }
}

