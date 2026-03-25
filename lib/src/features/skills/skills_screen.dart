import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart'; // Нужен пакет: flutter pub add collection
import '../../core/translations.dart';

// Убедись, что пути к файлам правильные:
import '../../data/skills_data.dart';
import '../../models/skill_model.dart';
import '../../services/providers.dart';
import 'widgets/skill_card.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    // Получаем данные охотника
    final hunter = ref.watch(hunterProvider);
    final learnedSkills = hunter?.skills ?? [];
    final skillPoints = hunter?.skillPoints ?? 0;
    final hunterLevel = hunter?.level ?? 1;

    // Группируем навыки по веткам (assassin, mage, tank)
    // Используем initialSkills из skills_data.dart
    final skillsByBranch = groupBy(
      initialSkills,
      (Skill skill) => skill.branch,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t('skill_tree')),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Text(
                  'SP: $skillPoints',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: skillsByBranch.entries.map((entry) {
            final branchName = entry.key;
            final branchSkills = entry.value;

            // Сортируем навыки внутри ветки по уровню (tier), чтобы шли по порядку
            branchSkills.sort((a, b) => a.tier.compareTo(b.tier));

            // Определяем цвет для ветки
            Color branchColor;
            switch (branchName) {
              case 'assassin':
                branchColor = Colors.redAccent;
                break;
              case 'mage':
                branchColor = Colors.blueAccent;
                break;
              case 'tank':
                branchColor = Colors.greenAccent;
                break;
              default:
                branchColor = Colors.grey;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              // Исправлено: withOpacity -> withValues (для новых версий Flutter)
              color: branchColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: branchColor.withValues(alpha: 0.3)),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                iconColor: branchColor,
                collapsedIconColor: branchColor,
                title: Text(
                  _getBranchDisplayName(branchName, t),
                  style: TextStyle(
                    color: branchColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                children: branchSkills.map((skill) {
                  // 1. Проверяем, изучен ли навык
                  final isLearned = learnedSkills.any((s) => s.id == skill.id);

                  // 2. Проверяем, хватает ли очков (только если еще не изучен)
                  final canAfford = skillPoints >= skill.cost;

                  // 3. Проверяем доступность (родитель + уровень)
                  bool isParentLearned = true;
                  if (skill.parentId != null) {
                    isParentLearned = learnedSkills.any(
                      (s) => s.id == skill.parentId,
                    );
                  }
                  final isAvailable =
                      hunterLevel >= 1 &&
                      isParentLearned; // Упростили проверку уровня

                  return SkillCard(
                    skill: skill,
                    branchColor: branchColor,
                    isLearned: isLearned,
                    isAvailable: isAvailable,
                    canAfford: canAfford,
                    onLearn: () {
                      // Логика нажатия на кнопку "Изучить"
                      if (isAvailable && canAfford && !isLearned) {
                        ref.read(hunterProvider.notifier).learnSkill(skill);

                        // Показываем уведомление
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t('skill_learned', params: {'name': skill.name}),
                            ),
                            backgroundColor: branchColor,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else if (!canAfford) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('not_enough_sp'))),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getBranchDisplayName(String branchName, String Function(String) t) {
    switch (branchName) {
      case 'assassin':
        return t('branch_assassin');
      case 'mage':
        return t('branch_mage');
      case 'tank':
        return t('branch_tank');
      default:
        return t('branch_general');
    }
  }
}
