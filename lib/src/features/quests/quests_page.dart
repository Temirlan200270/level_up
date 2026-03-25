import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/quest_model.dart';
import '../../models/enums.dart';
import '../../services/providers.dart';
import '../../services/ai_service.dart';
import '../inventory/widgets/loot_notification.dart';

class QuestsPage extends ConsumerWidget {
  const QuestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedQuests = ref.watch(completedQuestsProvider);
    final t = useTranslations(ref);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(t('quests')),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(questsProvider.notifier).refresh();
                  },
                  tooltip: t('refresh'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Активные квесты
                    if (activeQuests.isNotEmpty) ...[
                      Text(
                        t('active_quests'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...activeQuests.map((quest) => _buildQuestCard(
                        context,
                        ref,
                        quest,
                        isActive: true,
                        t: t,
                      )),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildEmptyState(
                        context,
                        t('no_active_quests'),
                        t('get_daily_quests'),
                        icon: Icons.assignment_outlined,
                        t: t,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Выполненные квесты
                    if (completedQuests.isNotEmpty) ...[
                      Text(
                        t('completed_quests'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...completedQuests.take(5).map((quest) => _buildQuestCard(
                        context,
                        ref,
                        quest,
                        isActive: false,
                        t: t,
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'ai_quest',
            onPressed: () => _generateAIQuest(context, ref),
            backgroundColor: SoloLevelingColors.neonPurple,
            tooltip: t('generate_ai_quest'),
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'daily_quests',
            onPressed: () async {
              // Инициализируем ежедневные квесты
              await ref.read(questsProvider.notifier).initializeDailyQuests();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('daily_quests_updated')),
                    backgroundColor: SoloLevelingColors.neonBlue,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_task),
            label: Text(t('daily')),
          ),
        ],
      ),
    );
  }

  // Карточка квеста
  Widget _buildQuestCard(
    BuildContext context,
    WidgetRef ref,
    Quest quest, {
    required bool isActive,
    required String Function(String) t,
  }) {
    final isExpired = quest.isExpired;
    final canComplete = quest.canComplete;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isActive && canComplete
            ? () => _showCompleteQuestDialog(context, ref, quest)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isExpired
                            ? SoloLevelingColors.textTertiary
                            : SoloLevelingColors.textPrimary,
                        decoration: isExpired
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    if (canComplete)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        color: SoloLevelingColors.neonGreen,
                        onPressed: () => _showCompleteQuestDialog(
                          context,
                          ref,
                          quest,
                        ),
                        tooltip: t('complete_quest'),
                      )
                    else if (isExpired)
                      const Icon(
                        Icons.access_time,
                        color: SoloLevelingColors.error,
                        size: 20,
                      ),
                  ] else
                    const Icon(
                      Icons.check_circle,
                      color: SoloLevelingColors.neonGreen,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Описание
              Text(
                quest.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              
              // Награды и тип
              Row(
                children: [
                  // Тип квеста
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getQuestTypeColor(quest.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getQuestTypeColor(quest.type),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getQuestTypeLabel(quest.type),
                      style: TextStyle(
                        color: _getQuestTypeColor(quest.type),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Награды
                  if (quest.experienceReward > 0)
                    _buildRewardChip(
                      context,
                      Icons.star,
                      '${quest.experienceReward} EXP',
                      SoloLevelingColors.neonBlue,
                    ),
                  if (quest.experienceReward > 0 && quest.statPointsReward > 0)
                    const SizedBox(width: 8),
                  if (quest.statPointsReward > 0)
                    _buildRewardChip(
                      context,
                      Icons.trending_up,
                      '${quest.statPointsReward} очков',
                      SoloLevelingColors.neonPurple,
                    ),
                ],
              ),
              
              // Срок выполнения
              if (quest.expiresAt != null && isActive) ...[
                const SizedBox(height: 8),
                Text(
                  'До: ${_formatDateTime(quest.expiresAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isExpired
                        ? SoloLevelingColors.error
                        : SoloLevelingColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Чип награды
  Widget _buildRewardChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Пустое состояние
  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle, {
    required IconData icon,
    required String Function(String) t,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: SoloLevelingColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Диалог выполнения квеста
  void _showCompleteQuestDialog(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
  ) {
    final t = useTranslations(ref);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('complete_quest_question'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.title,
              style: const TextStyle(
                color: SoloLevelingColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quest.description,
              style: const TextStyle(color: SoloLevelingColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (quest.experienceReward > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: SoloLevelingColors.neonBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${t('reward')}: ${quest.experienceReward} ${t('experience').toLowerCase()}',
                    style: const TextStyle(
                      color: SoloLevelingColors.neonBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!context.mounted) return;
              Navigator.pop(context);

              // Отмечаем квест как выполненный и получаем результат
              final result =
                  await ref.read(questsProvider.notifier).completeQuest(quest.id, ref);

              if (!context.mounted) return;
              if (result != null) {
                  final finalExp = result['experience'] as int;
                  final lootDrop = result['lootDrop'] as LootDropResult?;
                  
                  // Показываем уведомление об опыте (всегда показываем!)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t('quest_completed', params: {'exp': finalExp.toString()}),
                      ),
                      backgroundColor: SoloLevelingColors.neonGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // Показываем уведомление о дропе, если есть
                  if (lootDrop != null && context.mounted) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: lootDrop.goldAmount != null
                                ? LootNotification(
                                    itemName: '',
                                    goldAmount: lootDrop.goldAmount,
                                  )
                                : LootNotification(
                                    itemName: lootDrop.item?.name ?? '',
                                    itemRarity: lootDrop.item != null
                                        ? _getRarityName(lootDrop.item!.rarity)
                                        : null,
                                  ),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                  }
                }
            },
            child: Text(t('complete_quest')),
          ),
        ],
      ),
    );
  }

  // Цвет типа квеста
  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.daily:
        return SoloLevelingColors.neonBlue;
      case QuestType.weekly:
        return SoloLevelingColors.neonPurple;
      case QuestType.special:
        return SoloLevelingColors.neonPink;
      case QuestType.story:
        return SoloLevelingColors.neonGreen;
    }
  }

  // Метка типа квеста
  String _getQuestTypeLabel(QuestType type) {
    switch (type) {
      case QuestType.daily:
        return 'Ежедневный';
      case QuestType.weekly:
        return 'Еженедельный';
      case QuestType.special:
        return 'Особый';
      case QuestType.story:
        return 'Сюжетный';
    }
  }

  String _getRarityName(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return 'Обычный';
      case ItemRarity.rare:
        return 'Редкий';
      case ItemRarity.epic:
        return 'Эпический';
      case ItemRarity.legendary:
        return 'Легендарный';
      case ItemRarity.mythic:
        return 'Мифический';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Генерация квеста через ИИ
  Future<void> _generateAIQuest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final t = useTranslations(ref);
    // Проверяем наличие API ключа
    final hasApiKey = await AIService.hasApiKey();
    if (!hasApiKey) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: SoloLevelingColors.surface,
            title: Text(
              t('no_api_key'),
              style: const TextStyle(color: SoloLevelingColors.textPrimary),
            ),
            content: Text(
              t('no_api_key_message'),
              style: const TextStyle(color: SoloLevelingColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('ok')),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Показываем индикатор загрузки
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t('generating_quest')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final hunter = ref.read(hunterProvider);
      
      // Генерируем квест через ИИ
      final questData = await AIService.generateQuest(
        hunterLevel: hunter?.level.toString(),
        hunterStats: hunter != null
            ? 'Сила: ${hunter.stats.strength}, Ловкость: ${hunter.stats.agility}, Интеллект: ${hunter.stats.intelligence}, Живучесть: ${hunter.stats.vitality}'
            : null,
      );

      // Парсим тип квеста
      QuestType questType = QuestType.special;
      final typeStr = questData['type'] as String?;
      if (typeStr != null) {
        questType = QuestType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => QuestType.special,
        );
      }

      // Создаём квест
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(
        const Duration(days: 1),
      );

      final quest = Quest(
        title: questData['title'] as String? ?? 'Новый квест',
        description: questData['description'] as String? ?? 'Описание квеста',
        type: questType,
        experienceReward: (questData['experienceReward'] as num?)?.toInt() ?? 20,
        statPointsReward: (questData['statPointsReward'] as num?)?.toInt() ?? 0,
        expiresAt: tomorrow,
      );

      // Добавляем квест
      await ref.read(questsProvider.notifier).addQuest(quest);

      if (context.mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('quest_created', params: {'title': quest.title})),
            backgroundColor: SoloLevelingColors.neonGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error')}: $e'),
            backgroundColor: SoloLevelingColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

