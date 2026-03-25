import '../models/quest_model.dart';

/// «Сложные» типы квеста для бонуса xp_hard_quest в экипировке.
bool isHardQuestType(QuestType? type) {
  if (type == null) return false;
  return type == QuestType.special ||
      type == QuestType.story ||
      type == QuestType.urgent;
}
