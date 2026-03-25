import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/translations.dart';

import '../../../models/enums.dart';

// Убедись, что путь правильный (относительно папки widgets)
import '../../../models/skill_model.dart';
import '../../../services/providers.dart';

class SkillCard extends ConsumerWidget {
  final Skill skill;
  final Color branchColor; // Цвет ветки для стилизации
  final bool isLearned;    // Изучен ли навык
  final bool isAvailable;  // Доступен ли для изучения
  final bool canAfford;    // Хватает ли очков навыков
  final VoidCallback onLearn; // Функция для изучения

  const SkillCard({
    super.key,
    required this.skill,
    required this.branchColor,
    required this.isLearned,
    required this.isAvailable,
    required this.canAfford,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    // Используем withValues вместо устаревшего withOpacity
    Color cardColor = Colors.black.withValues(alpha: 0.8);
    Color borderColor = Colors.grey.shade800;
    Color textColor = Colors.grey.shade400;
    
    Widget? actionButton;
    String buttonText = '';
    VoidCallback? buttonOnPressed;

    if (isLearned) {
      // СЛУЧАЙ 1: Изучено
      borderColor = branchColor;
      textColor = Colors.white;
      
      // Получаем изученный навык с актуальным состоянием
      final hunter = ref.watch(hunterProvider);
      final learnedSkill = hunter?.skills.firstWhere(
        (s) => s.id == skill.id,
        orElse: () => skill,
      );
      
      // Проверяем cooldown для активных навыков
      final isOnCooldown = learnedSkill != null && 
                          learnedSkill.lastUsed != null && 
                          !learnedSkill.isReady;
      final remainingCooldown = learnedSkill?.remainingCooldown;
      
      if (skill.type == SkillType.active) {
        if (isOnCooldown && remainingCooldown != null) {
          // Навык на перезарядке
          final minutes = remainingCooldown ~/ 60;
          final seconds = remainingCooldown % 60;
          buttonText =
              '${t('cooldown')}: $minutes:${seconds.toString().padLeft(2, '0')}';
          buttonOnPressed = null;
        } else {
          buttonText = t('activate');
          buttonOnPressed = () {
            ref.read(hunterProvider.notifier).activateSkill(learnedSkill ?? skill);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('skill_activated', params: {'name': skill.name})), 
                backgroundColor: branchColor,
                duration: const Duration(seconds: 1),
              ),
            );
          };
        }
      } else {
        buttonText = t('upgrade');
        buttonOnPressed = () {
          if ((learnedSkill?.level ?? skill.level) < skill.maxLevel) {
            ref.read(hunterProvider.notifier).spendSkillPointAndUpgradeSkill(learnedSkill ?? skill);
          }
        };
      }

      final currentLevel = learnedSkill?.level ?? skill.level;
      if (skill.type == SkillType.passive && currentLevel >= skill.maxLevel) {
        actionButton = null; 
      } else {
        actionButton = ElevatedButton(
          onPressed: buttonOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOnCooldown ? Colors.grey.shade800 : branchColor,
            foregroundColor: isOnCooldown ? Colors.grey : Colors.white,
          ),
          child: Text(buttonText),
        );
      }
      
    } else if (isAvailable) {
      // СЛУЧАЙ 2: Доступно
      borderColor = branchColor.withValues(alpha: 0.5);
      textColor = Colors.white70;
      buttonText = '${t('learn')} (${skill.cost} SP)';
      
      buttonOnPressed = canAfford ? onLearn : null;
      
      actionButton = ElevatedButton(
        onPressed: buttonOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford ? branchColor : Colors.grey.shade800,
          foregroundColor: canAfford ? Colors.white : Colors.grey,
        ),
        child: Text(buttonText),
      );
      
    } else {
      // СЛУЧАЙ 3: Заблокировано
      borderColor = Colors.grey.shade900;
      cardColor = Colors.black.withValues(alpha: 0.5);
      textColor = Colors.grey.shade600;
      actionButton = const Icon(Icons.lock, color: Colors.grey);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Иконка навыка
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLearned ? branchColor.withValues(alpha: 0.2) : Colors.transparent,
              ),
              child: Icon(
                skill.type == SkillType.active ? Icons.flash_on : Icons.shield,
                color: isLearned ? branchColor : textColor,
                size: 32,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final hunter = ref.watch(hunterProvider);
                      final learnedSkill = hunter?.skills.firstWhere(
                        (s) => s.id == skill.id,
                        orElse: () => skill,
                      );
                      final displayLevel = learnedSkill?.level ?? skill.level;
                      return Text(
                        '${skill.name}${isLearned ? ' (${t('level')} $displayLevel)' : ''}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor, 
                          fontWeight: FontWeight.bold
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.8)
                    ),
                  ),
                  if (!isLearned && !isAvailable && skill.parentId != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      t('requires_parent_skill'),
                      style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            if (actionButton != null) actionButton,
          ],
        ),
      ),
    );
  }
}