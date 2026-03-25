import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/hunter_model.dart';
import '../../services/providers.dart';
import '../system/system_chat_page.dart';

class HunterProfilePage extends ConsumerStatefulWidget {
  const HunterProfilePage({super.key});

  @override
  ConsumerState<HunterProfilePage> createState() => _HunterProfilePageState();
}

class _HunterProfilePageState extends ConsumerState<HunterProfilePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hunter = ref.watch(hunterProvider);
    final t = useTranslations(ref);

    // Если охотника нет, показываем экран создания
    if (hunter == null) {
      return _buildCreateHunterScreen(context, ref);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(t('hunter_profile')),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.smart_toy),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SystemChatPage(),
                      ),
                    );
                  },
                  tooltip: t('system'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя и уровень
                    _buildLevelCard(context, hunter, t),
                    const SizedBox(height: 16),
                    
                    // Прогресс опыта
                    _buildExperienceBar(context, hunter, t),
                    const SizedBox(height: 24),
                    
                    // Статы
                    _buildStatsPanel(context, hunter, t),
                    const SizedBox(height: 24),
                    
                    // Информация
                    _buildInfoCard(context, hunter, t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Экран создания охотника
  Widget _buildCreateHunterScreen(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        Icon(
                          Icons.person_add,
                          size: 80,
                          color: SoloLevelingColors.neonBlue,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t('create_hunter'),
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('enter_name'),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: SoloLevelingColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('hunter_name'),
                            labelStyle: const TextStyle(color: SoloLevelingColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: SoloLevelingColors.neonBlue,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: SoloLevelingColors.neonBlue,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: SoloLevelingColors.neonBlue,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_nameController.text.trim().isNotEmpty) {
                              try {
                                await ref.read(hunterProvider.notifier).createHunter(
                                  _nameController.text.trim(),
                                );
                                // UI обновится автоматически через ref.watch
                              } catch (e) {
                                if (context.mounted) {
                                  final t = useTranslations(ref);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${t('hunter_creation_error')}: $e'),
                                      backgroundColor: SoloLevelingColors.error,
                                    ),
                                  );
                                }
                              }
                            } else {
                              if (context.mounted) {
                                final t = useTranslations(ref);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(t('enter_hunter_name')),
                                    backgroundColor: SoloLevelingColors.warning,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                          ),
                          child: Text(t('start_journey')),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Карточка уровня
  Widget _buildLevelCard(BuildContext context, Hunter hunter, String Function(String) t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Иконка уровня
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SoloLevelingColors.neonBlue,
                  width: 3,
                ),
                gradient: const RadialGradient(
                  colors: [
                    SoloLevelingColors.neonBlue,
                    SoloLevelingColors.background,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  '${hunter.level}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: SoloLevelingColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Имя и информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hunter.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t('level')} ${hunter.level}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SoloLevelingColors.neonBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t('experience')}: ${hunter.currentExp.toInt()} / ${hunter.experienceToNextLevel.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Полоса прогресса опыта
  Widget _buildExperienceBar(BuildContext context, Hunter hunter, String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('experience_to_next'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${(hunter.levelProgress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SoloLevelingColors.neonBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: hunter.levelProgress,
            minHeight: 12,
            backgroundColor: SoloLevelingColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(
              SoloLevelingColors.neonBlue,
            ),
          ),
        ),
      ],
    );
  }

  // Панель статов
  Widget _buildStatsPanel(BuildContext context, Hunter hunter, String Function(String) t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('stats'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatBar(
              context,
              t('strength'),
              hunter.stats.strength,
              Icons.fitness_center,
              SoloLevelingColors.neonPink,
              'strength',
              hunter,
              t,
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              context,
              t('agility'),
              hunter.stats.agility,
              Icons.speed,
              SoloLevelingColors.neonGreen,
              'agility',
              hunter,
              t,
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              context,
              t('intelligence'),
              hunter.stats.intelligence,
              Icons.psychology,
              SoloLevelingColors.neonPurple,
              'intelligence',
              hunter,
              t,
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              context,
              t('vitality'),
              hunter.stats.vitality,
              Icons.favorite,
              SoloLevelingColors.error,
              'vitality',
              hunter,
              t,
            ),
            if (hunter.stats.availablePoints > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SoloLevelingColors.neonBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SoloLevelingColors.neonBlue,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: SoloLevelingColors.neonBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t('available_points')}: ${hunter.stats.availablePoints}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: SoloLevelingColors.neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Полоса стата
  Widget _buildStatBar(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
    String statName,
    Hunter hunter,
    String Function(String) t,
  ) {
    final hasAvailablePoints = hunter.stats.availablePoints > 0;
    
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Row(
                    children: [
                      // Кнопка всегда видна, но неактивна если нет очков
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: hasAvailablePoints
                              ? color
                              : color.withValues(alpha: 0.3),
                        ),
                        onPressed: hasAvailablePoints
                            ? () {
                                ref.read(hunterProvider.notifier).allocateStatPoint(statName);
                              }
                            : null,
                        tooltip: hasAvailablePoints
                            ? t('add_point')
                            : t('no_points_available'),
                      ),
                      Text(
                        '$value',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value / 100, // Максимум 100 для визуализации
                  minHeight: 6,
                  backgroundColor: SoloLevelingColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Информационная карточка
  Widget _buildInfoCard(BuildContext context, Hunter hunter, String Function(String) t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('info'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              t('registration_date'),
              _formatDate(hunter.createdAt),
            ),
            if (hunter.lastLoginAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                t('last_login'),
                _formatDate(hunter.lastLoginAt!),
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              t('total_stats'),
              '${hunter.stats.total}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SoloLevelingColors.neonBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

