import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/hunter_model.dart';
import '../../services/providers.dart';
import '../../models/ai_provider_model.dart';
import '../system/system_chat_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunter = ref.watch(hunterProvider);
    final language = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final t = useTranslations(ref);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(t('settings')),
            centerTitle: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Секция профиля охотника
                    if (hunter != null) ...[
                      Text(
                        t('hunter_profile'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: SoloLevelingColors.neonBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(t('hunter_name')),
                              subtitle: Text(hunter.name),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showChangeNameDialog(context, ref, hunter.name, t),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.refresh, color: SoloLevelingColors.warning),
                              title: Text(
                                t('reset_progress'),
                                style: TextStyle(color: SoloLevelingColors.warning),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showResetProgressDialog(context, ref, t),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Секция общих настроек
                    Text(
                      t('general'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: SoloLevelingColors.neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: Text(t('language')),
                            subtitle: Text(_getLanguageName(language, t)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _showLanguagePicker(context, ref, language, t),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.smart_toy),
                            title: Text(t('system')),
                            subtitle: Text(t('ai_chat')),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SystemChatPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Секция ИИ
                    Text(
                      t('ai_settings'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: SoloLevelingColors.neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _AiSettingsCard(),
                    const SizedBox(height: 24),

                    // Статистика охотника
                    if (hunter != null) ...[
                      _buildHunterStatisticsCard(context, ref, hunter),
                      const SizedBox(height: 24),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 64,
                                color: SoloLevelingColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t('hunter_not_created'),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('create_hunter_in_profile'),
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Секция о приложении
                    Text(
                      t('about'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: SoloLevelingColors.neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: Text(t('version')),
                            subtitle: const Text('1.0.0'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.code),
                            title: Text(t('developed_with')),
                            subtitle: Text('Flutter ${_getFlutterVersion()}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Карточка статистики охотника
  Widget _buildHunterStatisticsCard(
    BuildContext context,
    WidgetRef ref,
    Hunter hunter,
  ) {
    final t = useTranslations(ref);
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedQuests = ref.watch(completedQuestsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('statistics'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  t('level'),
                  '${hunter.level}',
                  Icons.star,
                  SoloLevelingColors.neonBlue,
                ),
                _buildStatItem(
                  context,
                  t('experience'),
                  '${hunter.currentExp}',
                  Icons.trending_up,
                  SoloLevelingColors.neonGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  t('active_quests'),
                  '${activeQuests.length}',
                  Icons.assignment,
                  SoloLevelingColors.neonPurple,
                ),
                _buildStatItem(
                  context,
                  t('completed_quests'),
                  '${completedQuests.length}',
                  Icons.check_circle,
                  SoloLevelingColors.neonGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  t('total_stats'),
                  '${hunter.stats.total}',
                  Icons.fitness_center,
                  SoloLevelingColors.neonPink,
                ),
                _buildStatItem(
                  context,
                  t('available_points'),
                  '${hunter.stats.availablePoints}',
                  Icons.add_circle,
                  SoloLevelingColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Диалог изменения имени
  void _showChangeNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String Function(String) t,
  ) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('hunter_name_change'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
          decoration: InputDecoration(
            labelText: t('hunter_name'),
            labelStyle: const TextStyle(color: SoloLevelingColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: SoloLevelingColors.neonBlue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final hunter = ref.read(hunterProvider);
                if (hunter != null) {
                  await ref.read(hunterProvider.notifier).updateHunter(
                    hunter.copyWith(name: nameController.text.trim()),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }

  // Диалог сброса прогресса
  void _showResetProgressDialog(BuildContext context, WidgetRef ref, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('reset_progress_title'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: Text(
          t('reset_progress_message'),
          style: const TextStyle(color: SoloLevelingColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(hunterProvider.notifier).resetHunter();
              await ref.read(questsProvider.notifier).deleteAllQuests();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('progress_reset')),
                    backgroundColor: SoloLevelingColors.neonBlue,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SoloLevelingColors.error,
            ),
            child: Text(t('reset')),
          ),
        ],
      ),
    );
  }

  // Диалог выбора языка
  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    String currentLanguage,
    String Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('select_language'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                currentLanguage == 'ru' ? Icons.check_circle : Icons.circle_outlined,
                color: currentLanguage == 'ru'
                    ? SoloLevelingColors.neonBlue
                    : SoloLevelingColors.textTertiary,
              ),
              title: Text(
                t('russian'),
                style: const TextStyle(color: SoloLevelingColors.textPrimary),
              ),
              onTap: () async {
                await ref.read(languageProvider.notifier).setLanguage('ru');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('language_changed')),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                currentLanguage == 'en' ? Icons.check_circle : Icons.circle_outlined,
                color: currentLanguage == 'en'
                    ? SoloLevelingColors.neonBlue
                    : SoloLevelingColors.textTertiary,
              ),
              title: Text(
                t('english'),
                style: const TextStyle(color: SoloLevelingColors.textPrimary),
              ),
              onTap: () async {
                await ref.read(languageProvider.notifier).setLanguage('en');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('language_changed')),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String language, String Function(String) t) {
    switch (language) {
      case 'ru':
        return t('russian');
      case 'en':
        return t('english');
      default:
        return language;
    }
  }

  String _getFlutterVersion() {
    return '3.9.2'; // Версия из pubspec.yaml
  }
}

String _apiKeyHint(AIProvider provider) {
  switch (provider) {
    case AIProvider.openai:
      return 'sk-...';
    case AIProvider.gemini:
      return 'AIza...';
    case AIProvider.openRouter:
      return 'sk-or-...';
    case AIProvider.huggingFace:
      return 'hf_...';
    case AIProvider.claude:
      return 'sk-ant-...';
  }
}

/// Карточка настроек ИИ с контроллерами полей (не пересоздаётся на каждом кадре).
class _AiSettingsCard extends ConsumerStatefulWidget {
  const _AiSettingsCard();

  @override
  ConsumerState<_AiSettingsCard> createState() => _AiSettingsCardState();
}

class _AiSettingsCardState extends ConsumerState<_AiSettingsCard> {
  TextEditingController? _modelCtrl;
  TextEditingController? _keyCtrl;
  AIProvider? _boundProvider;
  Timer? _modelDebounce;
  Timer? _keyDebounce;
  final FocusNode _modelFocus = FocusNode();
  final FocusNode _keyFocus = FocusNode();

  @override
  void dispose() {
    _modelDebounce?.cancel();
    _keyDebounce?.cancel();
    _modelFocus.dispose();
    _keyFocus.dispose();
    _modelCtrl?.dispose();
    _keyCtrl?.dispose();
    super.dispose();
  }

  void _bindToProvider(AIProvider p, String model, String key) {
    if (_boundProvider == p && _modelCtrl != null && _keyCtrl != null) {
      return;
    }
    _modelDebounce?.cancel();
    _keyDebounce?.cancel();
    _modelCtrl?.dispose();
    _keyCtrl?.dispose();
    _modelCtrl = TextEditingController(text: model);
    _keyCtrl = TextEditingController(text: key);
    _boundProvider = p;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = useTranslations(ref);
    final currentProvider = ref.watch(aiProviderProvider);
    final currentModel = ref.watch(aiModelProvider);
    final currentKey = ref.watch(aiApiKeyProvider(currentProvider));

    _bindToProvider(currentProvider, currentModel, currentKey);

    if (_modelCtrl != null &&
        !_modelFocus.hasFocus &&
        _modelCtrl!.text != currentModel) {
      _modelCtrl!.text = currentModel;
    }
    if (_keyCtrl != null &&
        !_keyFocus.hasFocus &&
        _keyCtrl!.text != currentKey) {
      _keyCtrl!.text = currentKey;
    }

    final models = AIModels.models[currentProvider] ?? [];
    final hasKey = currentKey.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('ai_provider'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AIProvider.values.map((provider) {
                final isSelected = provider == currentProvider;
                return FilterChip(
                  selected: isSelected,
                  label: Text(AIModels.getProviderName(provider)),
                  onSelected: (selected) async {
                    if (selected) {
                      await ref.read(aiProviderProvider.notifier).setProvider(provider);
                      ref.read(aiModelProvider.notifier).refresh();
                      ref.read(aiApiKeyProvider(provider).notifier).refresh();
                    }
                  },
                  selectedColor: SoloLevelingColors.neonBlue.withValues(alpha: 0.3),
                  checkmarkColor: SoloLevelingColors.neonBlue,
                  side: BorderSide(
                    color: isSelected
                        ? SoloLevelingColors.neonBlue
                        : SoloLevelingColors.textTertiary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              t('model'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _modelCtrl,
              focusNode: _modelFocus,
              style: const TextStyle(color: SoloLevelingColors.textPrimary),
              decoration: InputDecoration(
                hintText: t('enter_model_name'),
                hintStyle: TextStyle(color: SoloLevelingColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: SoloLevelingColors.neonBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: SoloLevelingColors.neonBlue.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: SoloLevelingColors.neonBlue,
                    width: 2,
                  ),
                ),
                suffixIcon: models.isNotEmpty
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (model) async {
                          _modelCtrl?.text = model;
                          await ref.read(aiModelProvider.notifier).setModel(model);
                        },
                        itemBuilder: (context) => models.map((model) {
                          return PopupMenuItem(
                            value: model,
                            child: Text(model),
                          );
                        }).toList(),
                      )
                    : null,
              ),
              onChanged: (value) {
                _modelDebounce?.cancel();
                _modelDebounce = Timer(const Duration(milliseconds: 500), () async {
                  if (!mounted) return;
                  if (_modelCtrl?.text == value) {
                    await ref.read(aiModelProvider.notifier).setModel(value);
                  }
                });
              },
            ),
            if (models.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t('or_select_from_list'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SoloLevelingColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: models.take(5).map((model) {
                  final isSelected = model == currentModel;
                  return ActionChip(
                    label: Text(
                      model,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? SoloLevelingColors.neonBlue
                            : SoloLevelingColors.textSecondary,
                      ),
                    ),
                    onPressed: () async {
                      _modelCtrl?.text = model;
                      await ref.read(aiModelProvider.notifier).setModel(model);
                    },
                    backgroundColor: isSelected
                        ? SoloLevelingColors.neonBlue.withValues(alpha: 0.2)
                        : SoloLevelingColors.surfaceLight,
                    side: BorderSide(
                      color: isSelected
                          ? SoloLevelingColors.neonBlue
                          : SoloLevelingColors.textTertiary,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              t('api_key'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  hasKey ? Icons.key : Icons.key_off,
                  color: hasKey
                      ? SoloLevelingColors.neonGreen
                      : SoloLevelingColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AIModels.getProviderName(currentProvider)} ${t('api_key')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasKey
                          ? SoloLevelingColors.neonGreen
                          : SoloLevelingColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyCtrl,
              focusNode: _keyFocus,
              style: const TextStyle(color: SoloLevelingColors.textPrimary),
              decoration: InputDecoration(
                hintText: _apiKeyHint(currentProvider),
                hintStyle: TextStyle(color: SoloLevelingColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasKey
                        ? SoloLevelingColors.neonGreen
                        : SoloLevelingColors.neonBlue,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasKey
                        ? SoloLevelingColors.neonGreen.withValues(alpha: 0.5)
                        : SoloLevelingColors.neonBlue.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasKey
                        ? SoloLevelingColors.neonGreen
                        : SoloLevelingColors.neonBlue,
                    width: 2,
                  ),
                ),
                suffixIcon: currentKey.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _keyCtrl?.clear();
                          ref.read(aiApiKeyProvider(currentProvider).notifier).setKey('');
                        },
                      )
                    : null,
              ),
              obscureText: true,
              onChanged: (value) {
                _keyDebounce?.cancel();
                _keyDebounce = Timer(const Duration(milliseconds: 500), () async {
                  if (!mounted) return;
                  if (_keyCtrl?.text == value) {
                    await ref.read(aiApiKeyProvider(currentProvider).notifier).setKey(value);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
