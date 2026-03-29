import 'dart:math';

import '../../models/quest_model.dart';
import '../../models/hunter_model.dart';
import 'quest_evaluator.dart';

class LocalHeuristicEvaluator implements QuestEvaluator {
  final _random = Random();

  @override
  Future<QuestEvaluationResult> evaluateQuest({
    required String title,
    required String description,
    required Hunter hunter,
    required QuestType type,
  }) async {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    int difficultyRank = 1;
    List<String> tags = [];
    int baseExp = 10;
    int baseGold = 5;

    // Античит: тривиальные «квесты»
    final cheatHints = [
      'моргнуть',
      'моргн',
      'blink',
      'нажать кнопку',
      'нажми кнопку',
      'один раз вздох',
      'ничего не делать',
      'просто лечь',
      'do nothing',
      'click button',
    ];
    if (cheatHints.any(text.contains)) {
      return QuestEvaluationResult(
        suggestedExp: 2,
        suggestedGold: 1,
        difficultyRank: 1,
        tags: ['trivial', 'general'],
        systemComment:
            'Система не признаёт это испытанием. Добавь измеримое действие.',
        isApproved: true,
        usedLocalHeuristics: true,
      );
    }

    // Простые эвристики
    if (text.contains('бег') ||
        text.contains('отжимания') ||
        text.contains('спорт') ||
        text.contains('трениров') ||
        text.contains('run') ||
        text.contains('gym') ||
        text.contains('workout') ||
        text.contains('training') ||
        text.contains('body')) {
      tags.add('sport');
      tags.add('workout');
      tags.add('gym');
      tags.add('training');
      tags.add('body');
      tags.add('strength');
      difficultyRank += 1;
      baseExp += 10;
    }

    if (text.contains('код') ||
        text.contains('программирование') ||
        text.contains('алгоритм') ||
        text.contains('разработ') ||
        text.contains('git') ||
        text.contains('учеба') ||
        text.contains('книга') ||
        text.contains('code') ||
        text.contains('coding') ||
        text.contains('developer') ||
        text.contains('development') ||
        text.contains('devops') ||
        text.contains('software') ||
        text.contains('study') ||
        text.contains('read') ||
        text.contains('course')) {
      tags.add('intelligence');
      tags.add('learning');
      if (text.contains('код') ||
          text.contains('программ') ||
          text.contains('алгоритм') ||
          text.contains('разработ') ||
          text.contains('git') ||
          text.contains('code') ||
        text.contains('coding') ||
        text.contains('developer') ||
        text.contains('development') ||
        text.contains('devops') ||
        text.contains('software')) {
        tags.add('coding');
        tags.add('programming');
        tags.add('dev');
        tags.add('software');
        tags.add('it');
      }
      if (text.contains('книг') ||
          text.contains('учеб') ||
          text.contains('экзамен') ||
          text.contains('лекци') ||
          text.contains('read') ||
          text.contains('study') ||
          text.contains('course') ||
          text.contains('наук') ||
          text.contains('science') ||
          text.contains('research')) {
        tags.add('study');
        tags.add('reading');
        tags.add('science');
        tags.add('research');
      }
      difficultyRank += 1;
      baseExp += 10;
    }

    if (text.contains('медитац') ||
        text.contains('фокус') ||
        text.contains('осознан') ||
        text.contains('meditation') ||
        text.contains('mindful') ||
        text.contains('mental')) {
      tags.add('meditation');
      tags.add('focus');
      tags.add('mental');
      tags.add('mindfulness');
      difficultyRank += 1;
      baseExp += 8;
    }

    if (text.contains('уборка') || text.contains('дом') || text.contains('рутина')) {
      tags.add('routine');
      baseExp += 5;
    }

    if (text.length > 50) {
      difficultyRank += 1;
      baseExp += 5;
      baseGold += 5;
    }

    // Скелинг от уровня
    final levelMultiplier = 1.0 + (hunter.level * 0.1);
    int finalExp = (baseExp * levelMultiplier).round();
    int finalGold = (baseGold * levelMultiplier).round();

    // Шанс на комментарий Системы
    String? systemComment;
    if (_random.nextDouble() < 0.15) { // 15% шанс
      if (text.length < 10) {
        systemComment = 'Задача выглядит слишком простой. Добавь конкретики, чтобы получить больше наград.';
        finalExp = (finalExp * 0.5).round();
        finalGold = (finalGold * 0.5).round();
      } else {
        systemComment = 'Система одобряет твое стремление. Награда слегка увеличена.';
        finalExp = (finalExp * 1.2).round();
        finalGold = (finalGold * 1.2).round();
      }
    }

    // Ограничение ранга
    difficultyRank = difficultyRank.clamp(1, 6);
    if (tags.isEmpty) {
      tags.add('general');
    }

    return QuestEvaluationResult(
      suggestedExp: finalExp,
      suggestedGold: finalGold,
      difficultyRank: difficultyRank,
      tags: tags,
      systemComment: systemComment,
      isApproved: true,
      usedLocalHeuristics: true,
    );
  }
}
