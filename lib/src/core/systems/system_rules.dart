import '../../models/hunter_model.dart';
import '../../models/quest_model.dart';

abstract class SystemRules {
  const SystemRules();

  /// Подсказка для ИИ (в будущем будет собираться в промпт).
  String aiSystemPromptHint(Hunter hunter);

  /// Хук на начисление опыта — пока без изменения, но точка расширения.
  int mapQuestExperienceReward({
    required Hunter hunter,
    required Quest quest,
    required int baseExp,
  });

  /// Хук на начисление валюты — пока без изменения, но точка расширения.
  int mapQuestCurrencyReward({
    required Hunter hunter,
    required Quest quest,
    required int baseGold,
  });

  /// Хук на штраф при провале.
  int mapFailureGoldLoss({
    required Hunter hunter,
    required Quest quest,
    required int baseGoldLoss,
  });

  /// Хук на потерю опыта при провале.
  double mapFailureExperienceLoss({
    required Hunter hunter,
    required Quest quest,
    required double baseExpLoss,
  });

  /// Какие типы квестов “важнее” (для будущего роутинга и UI).
  Set<QuestType> preferredQuestTypes();
}

class SoloRules extends SystemRules {
  const SoloRules();

  @override
  String aiSystemPromptHint(Hunter hunter) => 'Solo Leveling: System voice.';

  @override
  int mapQuestExperienceReward({
    required Hunter hunter,
    required Quest quest,
    required int baseExp,
  }) {
    return baseExp;
  }

  @override
  int mapQuestCurrencyReward({
    required Hunter hunter,
    required Quest quest,
    required int baseGold,
  }) {
    return baseGold;
  }

  @override
  int mapFailureGoldLoss({
    required Hunter hunter,
    required Quest quest,
    required int baseGoldLoss,
  }) {
    return baseGoldLoss;
  }

  @override
  double mapFailureExperienceLoss({
    required Hunter hunter,
    required Quest quest,
    required double baseExpLoss,
  }) {
    return baseExpLoss;
  }

  @override
  Set<QuestType> preferredQuestTypes() {
    return {
      QuestType.story,
      QuestType.daily,
      QuestType.weekly,
      QuestType.urgent,
    };
  }
}

class MageRules extends SystemRules {
  const MageRules();

  @override
  String aiSystemPromptHint(Hunter hunter) =>
      'Кодекс Мага: ты — Эхо в гримуаре. Говори мистически, задавай вопросы, подталкивай к осознанным ритуалам.';

  @override
  int mapQuestExperienceReward({
    required Hunter hunter,
    required Quest quest,
    required int baseExp,
  }) {
    return baseExp;
  }

  @override
  int mapQuestCurrencyReward({
    required Hunter hunter,
    required Quest quest,
    required int baseGold,
  }) {
    return baseGold;
  }

  @override
  int mapFailureGoldLoss({
    required Hunter hunter,
    required Quest quest,
    required int baseGoldLoss,
  }) {
    return baseGoldLoss;
  }

  @override
  double mapFailureExperienceLoss({
    required Hunter hunter,
    required Quest quest,
    required double baseExpLoss,
  }) {
    return baseExpLoss;
  }

  @override
  Set<QuestType> preferredQuestTypes() {
    // Мага интересуют “ритуалы” и долгие цепочки: story/special/urgent.
    return {
      QuestType.story,
      QuestType.special,
      QuestType.urgent,
      QuestType.daily,
    };
  }
}

class CultivatorRules extends SystemRules {
  const CultivatorRules();

  @override
  String aiSystemPromptHint(Hunter hunter) =>
      'Путь культивации: ты — Мастер/Старейшина. Тон строгий, дисциплинирующий, про терпение и основу.';

  @override
  int mapQuestExperienceReward({
    required Hunter hunter,
    required Quest quest,
    required int baseExp,
  }) {
    return baseExp;
  }

  @override
  int mapQuestCurrencyReward({
    required Hunter hunter,
    required Quest quest,
    required int baseGold,
  }) {
    return baseGold;
  }

  @override
  int mapFailureGoldLoss({
    required Hunter hunter,
    required Quest quest,
    required int baseGoldLoss,
  }) {
    return baseGoldLoss;
  }

  @override
  double mapFailureExperienceLoss({
    required Hunter hunter,
    required Quest quest,
    required double baseExpLoss,
  }) {
    return baseExpLoss;
  }

  @override
  Set<QuestType> preferredQuestTypes() {
    // Культиватору важны daily/weekly как дисциплина + story как испытания.
    return {
      QuestType.daily,
      QuestType.weekly,
      QuestType.story,
      QuestType.special,
    };
  }
}

/// Обёртка над базовыми правилами для Custom System.
/// Добавляет пользовательскую подсказку для ИИ, не меняя математику.
class CustomRules extends SystemRules {
  const CustomRules({required this.base, required this.userPrompt});

  final SystemRules base;
  final String userPrompt;

  @override
  String aiSystemPromptHint(Hunter hunter) {
    final p = userPrompt.trim();
    if (p.isEmpty) return base.aiSystemPromptHint(hunter);
    return '${base.aiSystemPromptHint(hunter)}\nПользовательский стиль: $p';
  }

  @override
  int mapQuestExperienceReward({
    required Hunter hunter,
    required Quest quest,
    required int baseExp,
  }) {
    return base.mapQuestExperienceReward(
      hunter: hunter,
      quest: quest,
      baseExp: baseExp,
    );
  }

  @override
  int mapQuestCurrencyReward({
    required Hunter hunter,
    required Quest quest,
    required int baseGold,
  }) {
    return base.mapQuestCurrencyReward(
      hunter: hunter,
      quest: quest,
      baseGold: baseGold,
    );
  }

  @override
  int mapFailureGoldLoss({
    required Hunter hunter,
    required Quest quest,
    required int baseGoldLoss,
  }) {
    return base.mapFailureGoldLoss(
      hunter: hunter,
      quest: quest,
      baseGoldLoss: baseGoldLoss,
    );
  }

  @override
  double mapFailureExperienceLoss({
    required Hunter hunter,
    required Quest quest,
    required double baseExpLoss,
  }) {
    return base.mapFailureExperienceLoss(
      hunter: hunter,
      quest: quest,
      baseExpLoss: baseExpLoss,
    );
  }

  @override
  Set<QuestType> preferredQuestTypes() => base.preferredQuestTypes();
}

