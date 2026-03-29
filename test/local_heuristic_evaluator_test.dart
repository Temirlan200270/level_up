import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/models/hunter_model.dart';
import 'package:level_up/src/models/quest_model.dart';
import 'package:level_up/src/models/stats_model.dart';
import 'package:level_up/src/services/evaluators/local_heuristic_evaluator.dart';

void main() {
  final hunter = Hunter(
    name: 'Test',
    level: 5,
    currentExp: 0,
    gold: 0,
    stats: const Stats(strength: 1, agility: 1, intelligence: 1, vitality: 1),
  );

  test('trivial quest is penalized and marked local', () async {
    final ev = LocalHeuristicEvaluator();
    final r = await ev.evaluateQuest(
      title: 'Чит',
      description: 'моргнуть один раз',
      hunter: hunter,
      type: QuestType.special,
    );
    expect(r.usedLocalHeuristics, isTrue);
    expect(r.suggestedExp, lessThanOrEqualTo(5));
    expect(r.suggestedGold, lessThanOrEqualTo(2));
    expect(r.systemComment, isNotNull);
  });

  test('sport keywords bump rewards', () async {
    final ev = LocalHeuristicEvaluator();
    final r = await ev.evaluateQuest(
      title: 'Run',
      description: 'morning workout 5km',
      hunter: hunter,
      type: QuestType.daily,
    );
    expect(r.usedLocalHeuristics, isTrue);
    expect(r.tags, contains('sport'));
  });

  test('coding keywords add hidden-class aligned tags', () async {
    final ev = LocalHeuristicEvaluator();
    final r = await ev.evaluateQuest(
      title: 'Алгоритмы',
      description: 'Реализовать сортировку на Dart, git commit',
      hunter: hunter,
      type: QuestType.special,
    );
    expect(r.usedLocalHeuristics, isTrue);
    expect(r.tags, contains('coding'));
    expect(r.tags, contains('programming'));
  });
}
