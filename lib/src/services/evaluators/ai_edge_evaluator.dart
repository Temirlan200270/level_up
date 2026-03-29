import 'dart:convert';

import '../../models/quest_model.dart';
import '../../models/hunter_model.dart';
import '../ai_service.dart';
import 'quest_evaluator.dart';
import 'local_heuristic_evaluator.dart';

class AiEdgeEvaluator implements QuestEvaluator {
  final LocalHeuristicEvaluator _fallbackEvaluator = LocalHeuristicEvaluator();

  static const String _systemPrompt = '''Ты — античит-система и Гейм-мастер в RPG-приложении для реальной жизни.
Твоя задача — оценить задачу (квест), которую пользователь хочет добавить себе, и вернуть сбалансированные награды и теги.

Правила балансировки:
- Обычная рутина или легкая задача (например, "помыть посуду", "почистить зубы"): ранг 1 (E), 10-15 EXP, 5-10 Gold.
- Средняя задача (например, "тренировка 30 минут", "написать статью"): ранг 2-3 (D-C), 20-40 EXP, 15-25 Gold.
- Сложная задача (например, "закончить большой проект", "пробежать полумарафон"): ранг 4-6 (B-S), 50-100+ EXP, 30-50+ Gold.
- Если задача выглядит как явный чит (например, "моргнуть 1 раз", "просто нажать кнопку"): снижай награду до минимума (1-5 EXP) и дай строгий комментарий.

Теги (английские, snake_case / латиница) выбирай из набора, чтобы работала скрытая эволюция классов:
coding, programming, dev, software, sport, workout, gym, training, body, study, learning, reading, science, research, meditation, focus, mindfulness, mental, routine, general, strength, intelligence.

Формат ответа СТРОГО JSON:
{
  "suggestedExp": число,
  "suggestedGold": число,
  "difficultyRank": число (1-6),
  "tags": ["тег1", "тег2"],
  "systemComment": "Комментарий системы от 1 лица (опционально, если есть что сказать про чит или похвалить)",
  "isApproved": boolean
}''';

  QuestEvaluationResult _fromAiJson(Map<String, dynamic> jsonMap) {
    return QuestEvaluationResult(
      suggestedExp: (jsonMap['suggestedExp'] as num?)?.toInt() ?? 10,
      suggestedGold: (jsonMap['suggestedGold'] as num?)?.toInt() ?? 5,
      difficultyRank: (jsonMap['difficultyRank'] as num?)?.toInt() ?? 1,
      tags:
          (jsonMap['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      systemComment: jsonMap['systemComment'] as String?,
      isApproved: jsonMap['isApproved'] as bool? ?? true,
      usedLocalHeuristics: false,
    );
  }

  Future<Map<String, dynamic>> _requestAiJson({
    required String title,
    required String description,
    required Hunter hunter,
  }) async {
    final userPrompt = '''Оцени квест:
Название: "$title"
Описание: "$description"
Уровень охотника: ${hunter.level}''';

    final response = await AIService.sendMessage(
      message: userPrompt,
      systemPrompt: _systemPrompt,
      temperature: 0.3,
    );

    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (match != null) {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      }
      throw const FormatException('Invalid JSON from AI');
    }
  }

  /// Только ответ ИИ; при ошибке или отсутствии ключа — `null` (без локального фолбэка).
  Future<QuestEvaluationResult?> evaluateQuestAiOrNull({
    required String title,
    required String description,
    required Hunter hunter,
    required QuestType type,
  }) async {
    if (!await AIService.hasApiKey()) return null;
    try {
      final jsonMap = await _requestAiJson(
        title: title,
        description: description,
        hunter: hunter,
      );
      return _fromAiJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<QuestEvaluationResult> evaluateQuest({
    required String title,
    required String description,
    required Hunter hunter,
    required QuestType type,
  }) async {
    if (!await AIService.hasApiKey()) {
      return _fallbackEvaluator.evaluateQuest(
        title: title,
        description: description,
        hunter: hunter,
        type: type,
      );
    }

    try {
      final jsonMap = await _requestAiJson(
        title: title,
        description: description,
        hunter: hunter,
      );
      return _fromAiJson(jsonMap);
    } catch (_) {
      return _fallbackEvaluator.evaluateQuest(
        title: title,
        description: description,
        hunter: hunter,
        type: type,
      );
    }
  }
}
