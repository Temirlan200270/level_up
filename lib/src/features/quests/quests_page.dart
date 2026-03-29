import 'dart:async';
import 'dart:math' show Random;

import '../../core/master_command_draft_thoughts.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:uuid/uuid.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/systems/system_dictionary.dart';
import '../../core/systems/system_id.dart';
import '../../core/systems/system_rules.dart';
import '../../core/rpg_theme_tokens_extension.dart';
import '../../core/widgets/world_quest_card_shell.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../core/translations.dart';
import '../../models/quest_model.dart';
import '../../models/hunter_model.dart';
import '../../models/enums.dart';
import '../../services/providers.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/sound_service.dart';
import '../../services/evaluators/ai_edge_evaluator.dart';
import '../../services/evaluators/local_heuristic_evaluator.dart';
import '../../services/world_journal_milestone_notifications.dart';
import 'quest_section_grouping.dart';
import 'widgets/living_header_metrics.dart';
import 'widgets/living_quests_header.dart';
import 'widgets/master_command_bar.dart';
import 'widgets/master_thoughts.dart';
import 'widgets/world_journal_sheet.dart';
import '../inventory/widgets/loot_notification.dart';
import '../onboarding/onboarding_models.dart';
import '../../services/evaluators/adaptive_difficulty_service.dart';
import 'quest_weak_area_prioritization.dart';
import '../shop/shop_screen.dart';

class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key});

  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();

  /// Определение типа квеста по свободному тексту (командная строка).
  static QuestType _inferQuickQuestType(String text) {
    final t = text.toLowerCase();
    if (t.contains('ежедневн') ||
        t.contains('сегодня') ||
        t.contains('каждый день') ||
        t.contains('daily')) {
      return QuestType.daily;
    }
    if (t.contains('недел') ||
        t.contains('weekly') ||
        t.contains('на неделю')) {
      return QuestType.weekly;
    }
    return QuestType.special;
  }

  /// Фон диалога: [DialogTheme.backgroundColor] или fallback на surface.
  static Color _dialogSurface(BuildContext context) {
    final t = Theme.of(context);
    return t.dialogTheme.backgroundColor ?? t.colorScheme.surfaceContainerHigh;
  }

  /// Пустое состояние секции квестов (l10n + эффективная философия).
  static String _questEmptyText(
    SystemId systemId,
    SystemRules rules,
    String section,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
    return t('quest_empty_${section}_${nav.name}');
  }

  /// Реплика Мастера под пустым состоянием секции (Фаза 7.7).
  static String _questEmptyMasterVoice(
    SystemId systemId,
    SystemRules rules,
    String section,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
    return t('quest_empty_master_${section}_${nav.name}');
  }

  /// Заголовок секции квестов (l10n + эффективная философия).
  static String _questSectionTitleText(
    SystemId systemId,
    SystemRules rules,
    String section,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
    return t('quest_section_${section}_${nav.name}');
  }
}

class _QuestsPageState extends ConsumerState<QuestsPage> {
  late final TextEditingController _commandController;
  bool _commandBusy = false;
  String? _dynamicCommandHint;
  bool _commandHintPickScheduled = false;

  @override
  void initState() {
    super.initState();
    _commandController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_commandHintPickScheduled) return;
    _commandHintPickScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final t = useTranslations(ref);
      setState(() {
        _dynamicCommandHint = _pickRandomCommandPlaceholder(ref, t);
      });
    });
  }

  /// Случайный плейсхолдер консоли Мастера по философии (Фаза 10.3).
  String _pickRandomCommandPlaceholder(
    WidgetRef ref,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    final systemId = ref.read(activeSystemIdProvider);
    final rules = ref.read(activeSystemRulesProvider);
    final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
    final branch = switch (nav) {
      SystemId.solo => 'solo',
      SystemId.mage => 'mage',
      SystemId.cultivator => 'cult',
      SystemId.custom => 'solo',
    };
    final i = Random().nextInt(3);
    return t('master_cmd_ph_${branch}_$i');
  }

  @override
  void dispose() {
    ref.read(masterCommandTypingThoughtKeyProvider.notifier).state = null;
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _submitQuickCommand(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || _commandBusy) return;

    final hunter = ref.read(hunterProvider);
    final t = useTranslations(ref);
    if (hunter == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('guild_need_hunter')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    setState(() => _commandBusy = true);
    FocusScope.of(context).unfocus();

    try {
      final selectedType = QuestsPage._inferQuickQuestType(trimmed);
      final localEval = LocalHeuristicEvaluator();
      final result = await localEval.evaluateQuest(
        title: trimmed,
        description: '',
        hunter: hunter,
        type: selectedType,
      );

      if (result.difficultyRank >= 5) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }

      DateTime? expiresAt;
      if (selectedType == QuestType.daily) {
        expiresAt = DateTime.now().add(const Duration(days: 1));
      } else if (selectedType == QuestType.weekly) {
        expiresAt = DateTime.now().add(const Duration(days: 7));
      }

      final questId = const Uuid().v4();
      final quest = Quest(
        id: questId,
        title: trimmed,
        description: selectedType == QuestType.special
            ? t('master_command_auto_description')
            : '',
        type: selectedType,
        experienceReward: result.suggestedExp,
        goldReward: result.suggestedGold,
        difficulty: result.difficultyRank,
        tags: result.tags,
        mandatory:
            selectedType == QuestType.daily ||
                selectedType == QuestType.weekly,
        expiresAt: expiresAt,
      );

      await ref.read(questsProvider.notifier).addQuest(quest);
      unawaited(SoundService.playCommandSubmit());
      if (result.difficultyRank >= 5) {
        unawaited(SoundService.playCommandHighRank());
      }
      _commandController.clear();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final hasAiKey = await AIService.hasApiKey();
      if (!mounted) return;

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            t('master_command_created_snack', params: {'title': quest.title}),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      if (hasAiKey) {
        final cur = ref.read(questsAwaitingAiRefinementIdsProvider);
        ref.read(questsAwaitingAiRefinementIdsProvider.notifier).state = {
          ...cur,
          questId,
        };
        unawaited(
          _refineManualQuestWithAi(
            ref: ref,
            questId: questId,
            title: trimmed,
            description: quest.description,
            hunter: hunter,
            type: selectedType,
            messenger: messenger,
            t: t,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final te = useTranslations(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${te('error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _commandBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedQuests = ref.watch(completedQuestsProvider);
    final systemId = ref.watch(activeSystemIdProvider);
    final systemRules = ref.watch(activeSystemRulesProvider);
    final t = useTranslations(ref);
    final colorScheme = Theme.of(context).colorScheme;
    final questVisuals = context.systemVisuals;

    final hunter = ref.watch(hunterProvider);
    ref.watch(livingHeaderPulseProvider);
    final allQuests = ref.watch(questsProvider);

    final personaMap =
        DatabaseService.getOnboardingPersonaRaw(systemId: systemId);
    final persona = personaMap != null
        ? OnboardingPersona.fromMap(personaMap)
        : null;
    final adaptiveEval =
        AdaptiveDifficultyService.evaluate(14, systemId: systemId);

    final penaltyQuests = QuestSectionGrouping.penalty(activeQuests);
    final storyQuests = QuestWeakAreaPrioritization.sort(
      QuestSectionGrouping.story(activeQuests),
      hunter: hunter,
      persona: persona,
      adaptive: adaptiveEval,
      systemId: systemId,
    );
    final dailyQuests = QuestWeakAreaPrioritization.sort(
      QuestSectionGrouping.daily(activeQuests),
      hunter: hunter,
      persona: persona,
      adaptive: adaptiveEval,
      systemId: systemId,
    );
    final miscQuests = QuestWeakAreaPrioritization.sort(
      QuestSectionGrouping.misc(activeQuests),
      hunter: hunter,
      persona: persona,
      adaptive: adaptiveEval,
      systemId: systemId,
    );

    final vitalitySnap = computeLivingHeaderVitality(allQuests);
    final focusMin = DatabaseService.getFocusMinutesToday();
    final focusGoalMinutes = DatabaseService.livingHeaderFocusDailyGoalMinutes;
    final focusR = livingHeaderFocusMpRatio(focusMin);
    final hour = DateTime.now().hour;
    final isEvening = hour >= 17;
    final vitalityStressPulse = isEvening &&
        vitalitySnap.totalCount > 0 &&
        vitalitySnap.ratio < 0.2;
    final focusStressPulse = focusGoalMinutes > 0 && focusMin == 0;
    final neonAccent = colorScheme.tertiary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MasterThoughts(),
              const SizedBox(height: 8),
              MasterCommandBar(
                controller: _commandController,
                hintText: _dynamicCommandHint ?? t('master_command_hint'),
                sendTooltip: t('master_command_send'),
                onSubmitted:
                    _commandBusy ? (_) {} : _submitQuickCommand,
                onChanged: (text) {
                  ref.read(masterCommandTypingThoughtKeyProvider.notifier).state =
                      masterCommandDraftThoughtKey(text);
                },
              ),
              if (_commandBusy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    final handle =
                        NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    );
                    return [
                      SliverOverlapAbsorber(
                        handle: handle,
                        sliver: SliverAppBar(
                          pinned: true,
                          toolbarHeight: 48,
                          expandedHeight: 196,
                          backgroundColor:
                              colorScheme.surface.withValues(alpha: 0.94),
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          automaticallyImplyLeading: false,
                          flexibleSpace: FlexibleSpaceBar(
                            collapseMode: CollapseMode.pin,
                            background: LivingQuestsFlexibleHeader(
                              hunter: hunter,
                              vitalityRatio: vitalitySnap.ratio,
                              focusRatio: focusR,
                              focusMinutesToday: focusMin,
                              focusGoalMinutes: focusGoalMinutes,
                              vitalityStressPulse: vitalityStressPulse,
                              focusStressPulse: focusStressPulse,
                              t: t,
                              neonColor: neonAccent,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.menu_book_outlined),
                              tooltip: t('world_journal_title'),
                              onPressed: () =>
                                  showWorldJournalSheet(context, ref),
                            ),
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ShopScreen(),
                                  ),
                                );
                              },
                              tooltip: t('shop'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                ref.read(questsProvider.notifier).refresh();
                              },
                              tooltip: t('refresh'),
                            ).animate().rotate(
                                  duration: 600.ms,
                                  curve: Curves.easeOut,
                                ),
                            PopupMenuButton<String>(
                              tooltip: t('quests_overflow_menu'),
                              icon: const Icon(Icons.more_vert_rounded),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'manual':
                                    _showManualQuestDialog(context, ref);
                                    break;
                                  case 'urgent':
                                    await ref
                                        .read(questsProvider.notifier)
                                        .spawnUrgentQuest();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            t('urgent_quest_spawned'),
                                          ),
                                          backgroundColor: colorScheme.error,
                                        ),
                                      );
                                    }
                                    break;
                                  case 'ai':
                                    await _generateAIQuest(context, ref);
                                    break;
                                  case 'daily':
                                    await ref
                                        .read(questsProvider.notifier)
                                        .initializeDailyQuests();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            t('daily_quests_updated'),
                                          ),
                                          backgroundColor:
                                              colorScheme.primary,
                                        ),
                                      );
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'manual',
                                  child: ListTile(
                                    dense: true,
                                    leading:
                                        const Icon(Icons.edit_note_rounded),
                                    title: Text(t('create_quest')),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'urgent',
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.bolt_rounded,
                                      color: colorScheme.error,
                                    ),
                                    title: Text(t('spawn_urgent_quest')),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'ai',
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: colorScheme.secondary,
                                    ),
                                    title: Text(t('generate_ai_quest')),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'daily',
                                  child: ListTile(
                                    dense: true,
                                    leading:
                                        const Icon(Icons.add_task_rounded),
                                    title: Text(t('daily')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: Builder(
                    builder: (context) {
                      return WorldSurfacePanel(
                        visuals: questVisuals,
                        margin: EdgeInsets.zero,
                        child: CustomScrollView(
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                context,
                              ),
                            ),

            // --- Штрафные Врата ---
            _buildQuestSection(
              context: context,
              visuals: questVisuals,
              sectionStaggerIndex: 0,
              title: QuestsPage._questSectionTitleText(
                systemId,
                systemRules,
                'penalty',
                t,
              ),
              color: colorScheme.error,
              icon: Icons.warning_amber_rounded,
              quests: penaltyQuests,
              emptyText: QuestsPage._questEmptyText(
                systemId,
                systemRules,
                'penalty',
                t,
              ),
              emptyMasterVoice: QuestsPage._questEmptyMasterVoice(
                systemId,
                systemRules,
                'penalty',
                t,
              ),
              ref: ref,
              t: t,
            ),

            // --- Сюжетные Вехи ---
            _buildQuestSection(
              context: context,
              visuals: questVisuals,
              sectionStaggerIndex: 1,
              title: QuestsPage._questSectionTitleText(
                systemId,
                systemRules,
                'story',
                t,
              ),
              color: colorScheme.primary, // Динамичный цвет темы
              icon: Icons.auto_stories_rounded,
              quests: storyQuests,
              emptyText: QuestsPage._questEmptyText(
                systemId,
                systemRules,
                'story',
                t,
              ),
              emptyMasterVoice: QuestsPage._questEmptyMasterVoice(
                systemId,
                systemRules,
                'story',
                t,
              ),
              ref: ref,
              t: t,
              isStory: true,
            ),

            // --- Ежедневные Задания ---
            _buildQuestSection(
              context: context,
              visuals: questVisuals,
              sectionStaggerIndex: 2,
              title: QuestsPage._questSectionTitleText(
                systemId,
                systemRules,
                'daily',
                t,
              ),
              color: colorScheme.secondary,
              icon: Icons.calendar_today_rounded,
              quests: dailyQuests,
              emptyText: QuestsPage._questEmptyText(
                systemId,
                systemRules,
                'daily',
                t,
              ),
              emptyMasterVoice: QuestsPage._questEmptyMasterVoice(
                systemId,
                systemRules,
                'daily',
                t,
              ),
              ref: ref,
              t: t,
            ),

            // --- Прочие: недельные, особые, срочные ---
            _buildQuestSection(
              context: context,
              visuals: questVisuals,
              sectionStaggerIndex: 3,
              title: QuestsPage._questSectionTitleText(
                systemId,
                systemRules,
                'misc',
                t,
              ),
              color: colorScheme.tertiary,
              icon: Icons.bolt_rounded,
              quests: miscQuests,
              emptyText: QuestsPage._questEmptyText(
                systemId,
                systemRules,
                'misc',
                t,
              ),
              emptyMasterVoice: QuestsPage._questEmptyMasterVoice(
                systemId,
                systemRules,
                'misc',
                t,
              ),
              ref: ref,
              t: t,
            ),

            // --- Завершённые квесты (показываем только если есть) ---
            if (completedQuests.isNotEmpty)
              MultiSliver(
                children: [
                  SliverPinnedHeader(
                    child: _buildSectionHeader(
                      context,
                      questVisuals,
                      sectionStaggerIndex: 4,
                      title: t('completed_quests').toUpperCase(),
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      icon: Icons.history_rounded,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final baseMs = 4 * 320 + index * 80;
                          return _buildQuestCard(
                                context,
                                ref,
                                completedQuests[index],
                                isActive: false,
                                t: t,
                                isAwaitingAiRefinement: false,
                                goldFlashHighlight: false,
                              )
                              .animate(delay: baseMs.ms)
                              .fadeIn(
                                duration: 480.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideY(begin: 0.14, curve: Curves.easeOutCubic);
                        },
                        childCount: completedQuests.take(5).length,
                      ),
                    ),
                  ),
                ],
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Универсальный сборщик секций (Sliver) ---
  Widget _buildQuestSection({
    required BuildContext context,
    required SystemVisuals visuals,
    required int sectionStaggerIndex,
    required String title,
    required Color color,
    required IconData icon,
    required List<Quest> quests,
    required String emptyText,
    required String emptyMasterVoice,
    required WidgetRef ref,
    required String Function(String, {Map<String, String>? params}) t,
    bool isStory = false,
  }) {
    final awaiting = ref.watch(questsAwaitingAiRefinementIdsProvider);
    final goldFlash = ref.watch(questCardGoldFlashIdsProvider);

    return MultiSliver(
      children: [
        SliverPinnedHeader(
          child: _buildSectionHeader(
            context,
            visuals,
            sectionStaggerIndex: sectionStaggerIndex,
            title: title,
            color: color,
            icon: icon,
          ),
        ),
        if (quests.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: color.withValues(alpha: 0.62),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      height: 1.45,
                      letterSpacing:
                          (visuals.titleLetterSpacing * 0.42).clamp(0.5, 1.6),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 620.ms,
                        delay: (sectionStaggerIndex * 140 + 40).ms,
                      )
                      .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    emptyMasterVoice,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.88),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      height: 1.5,
                      letterSpacing:
                          (visuals.titleLetterSpacing * 0.35).clamp(0.3, 1.2),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 720.ms,
                        delay: (sectionStaggerIndex * 140 + 160).ms,
                      )
                      .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final baseMs = sectionStaggerIndex * 320 + index * 95;
                  final q = quests[index];
                  return _buildQuestCard(
                        context,
                        ref,
                        q,
                        isActive: true,
                        t: t,
                        isStoryGlow: isStory,
                        isAwaitingAiRefinement: awaiting.contains(q.id),
                        goldFlashHighlight: goldFlash.contains(q.id),
                      )
                      .animate(delay: baseMs.ms)
                      .fadeIn(duration: 520.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.22, curve: Curves.easeOutCubic);
                },
                childCount: quests.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Заголовок секции по токенам мира (Фаза 7.7).
  Widget _buildSectionHeader(
    BuildContext context,
    SystemVisuals visuals, {
    required int sectionStaggerIndex,
    required String title,
    required Color color,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = switch (visuals.surfaceKind) {
      SystemSurfaceKind.glass => scheme.surface.withValues(alpha: 0.44),
      SystemSurfaceKind.parchment => Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.06),
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.93),
        ),
      SystemSurfaceKind.digital =>
        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.96),
    };

    final glow = visuals.glowIntensity.clamp(0.0, 1.0);
    final bottomRadius =
        (visuals.panelRadius * visuals.borderRadiusScale * 0.55).clamp(8.0, 22.0);
    final List<BoxShadow> headerShadows = switch (visuals.shadowProfile) {
      SystemShadowProfile.none => const [],
      SystemShadowProfile.soft => [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      SystemShadowProfile.glow => [
          BoxShadow(
            color: color.withValues(alpha: 0.2 * glow + 0.06),
            blurRadius: 12 + 14 * glow,
            spreadRadius: 0.5,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1 * glow + 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
    };

    final borderW = visuals.panelBorderWidth.clamp(0.0, 2.5);
    final bottomBorder = borderW >= 0.5
        ? BorderSide(
            color: color.withValues(alpha: 0.22 + 0.2 * glow),
            width: borderW,
          )
        : null;

    final header = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
        border: bottomBorder != null
            ? Border(bottom: bottomBorder)
            : null,
        boxShadow: headerShadows,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2.seconds),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing:
                    (visuals.titleLetterSpacing * 0.62).clamp(0.8, 2.4),
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

    return header
        .animate()
        .fadeIn(
          duration: 420.ms,
          delay: (sectionStaggerIndex * 140).ms,
        )
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  // Карточка квеста
  Widget _buildQuestCard(
    BuildContext context,
    WidgetRef ref,
    Quest quest, {
    required bool isActive,
    required String Function(String, {Map<String, String>? params}) t,
    bool isStoryGlow = false,
    bool isAwaitingAiRefinement = false,
    bool goldFlashHighlight = false,
  }) {
    final isExpired = quest.isExpired;
    final canComplete = quest.canComplete;
    final mutationBusy = ref.watch(questMutationBusyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final rpg = Theme.of(context).extension<RpgThemeTokens>();
    final goldRewardColor = rpg?.rarityLegendary ?? colorScheme.tertiary;
    final visuals = context.systemVisuals;
    final aiLoadingPhraseKey = isAwaitingAiRefinement
        ? ref.watch(questAiLoadingPhraseKeyProvider)[quest.id]
        : null;
    final aiLoadingLine = aiLoadingPhraseKey != null
        ? t(aiLoadingPhraseKey)
        : t('master_quest_scanning');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: goldFlashHighlight
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: goldRewardColor.withValues(alpha: 0.55),
                  blurRadius: 22,
                  spreadRadius: 0.5,
                ),
              ],
            )
          : null,
      child: WorldQuestCardShell(
        visuals: visuals,
        isStoryGlow: isStoryGlow,
        isActive: isActive,
        onTap: isActive && canComplete
            ? () => _showCompleteQuestDialog(context, ref, quest)
            : null,
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
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                          decoration: isExpired
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      if (quest.canFail)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          color: colorScheme.error,
                          onPressed: mutationBusy
                              ? null
                              : () => _confirmFailQuest(context, ref, quest, t),
                          tooltip: t('fail_quest'),
                        ),
                      if (canComplete)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          color: colorScheme.primary,
                          onPressed: mutationBusy
                              ? null
                              : () => _showCompleteQuestDialog(
                                  context,
                                  ref,
                                  quest,
                                ),
                          tooltip: t('complete_quest'),
                        )
                      else if (isExpired)
                        Icon(
                          Icons.access_time,
                          color: colorScheme.error,
                          size: 20,
                        ).animate(onPlay: (c) => c.repeat()).shake(),
                    ] else
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
                if (isActive && isAwaitingAiRefinement) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiLoadingLine,
                          style: GoogleFonts.manrope(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 400.ms)
                      .shimmer(
                        duration: 900.ms,
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                ],
                const SizedBox(height: 8),

                // Описание
                if (quest.description.trim().isNotEmpty) ...[
                  Text(
                    quest.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],

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
                        color: _getQuestTypeColor(
                          quest.type,
                          colorScheme,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getQuestTypeColor(
                            quest.type,
                            colorScheme,
                          ).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getQuestTypeLabel(quest.type, t),
                        style: TextStyle(
                          color: _getQuestTypeColor(quest.type, colorScheme),
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
                        colorScheme.primary,
                      ),
                    if (quest.experienceReward > 0 &&
                        quest.statPointsReward > 0)
                      const SizedBox(width: 8),
                    if (quest.statPointsReward > 0)
                      _buildRewardChip(
                        context,
                        Icons.trending_up,
                        '${quest.statPointsReward} SP',
                        colorScheme.secondary,
                      ),
                    if (quest.goldReward > 0) ...[
                      if (quest.experienceReward > 0 ||
                          quest.statPointsReward > 0)
                        const SizedBox(width: 8),
                      _buildRewardChip(
                        context,
                        Icons.monetization_on,
                        '${quest.goldReward} ${t('gold')}',
                        goldRewardColor,
                      ),
                    ],
                  ],
                ),

                // Срок выполнения
                if (quest.expiresAt != null && isActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    'До: ${_formatDateTime(quest.expiresAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isExpired
                          ? colorScheme.error
                          : colorScheme.onSurface.withValues(alpha: 0.5),
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteQuestDialog(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
  ) {
    final t = useTranslations(ref);
    final dict = ref.watch(activeSystemProvider).dictionary;
    final mutationBusy = ref.watch(questMutationBusyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final rpg = Theme.of(context).extension<RpgThemeTokens>();
    final goldRewardColor = rpg?.rarityLegendary ?? colorScheme.tertiary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuestsPage._dialogSurface(context),
        title: Text(
          t('complete_quest_question'),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quest.description,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (quest.experienceReward > 0)
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${t('reward')}: ${quest.experienceReward} ${dict.experienceName.toLowerCase()}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (quest.goldReward > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: goldRewardColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${t('gold_reward')}: ${quest.goldReward} ${dict.currencyName}',
                    style: TextStyle(
                      color: goldRewardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: mutationBusy
                ? null
                : () async {
                    if (!context.mounted) return;
                    Navigator.pop(context);

                    final result = await ref
                        .read(questsProvider.notifier)
                        .completeQuest(quest.id, ref);

                    if (!context.mounted) return;
                    if (result != null) {
                      final finalExp = result['experience'] as int;
                      final lootDrop = result['lootDrop'] as LootDropResult?;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t(
                              'quest_completed',
                              params: {'exp': finalExp.toString()},
                            ),
                          ),
                          backgroundColor: colorScheme.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );

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
                                            ? _getRarityName(
                                                lootDrop.item!.rarity,
                                              )
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

                      final wj =
                          result['worldJournalSnack'] as WorldJournalSnackHit?;
                      if (wj != null) {
                        final delayMs = lootDrop != null ? 3600 : 2400;
                        Future.delayed(Duration(milliseconds: delayMs), () {
                          if (!context.mounted) return;
                          final scheme = Theme.of(context).colorScheme;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t(
                                  wj.tierTranslationKey,
                                  params: {'axis': t(wj.axisLabelKey)},
                                ),
                              ),
                              duration: const Duration(seconds: 5),
                              backgroundColor: scheme.primaryContainer,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }
                    }
                  },
            child: Text(t('complete_quest')),
          ),
        ],
      ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Color _getQuestTypeColor(QuestType type, ColorScheme colorScheme) {
    switch (type) {
      case QuestType.daily:
        return colorScheme.secondary;
      case QuestType.weekly:
        return colorScheme.secondary;
      case QuestType.special:
        return colorScheme.tertiary;
      case QuestType.story:
        return colorScheme.primary;
      case QuestType.urgent:
        return colorScheme.errorContainer;
      case QuestType.penalty:
        return colorScheme.error;
    }
  }

  String _getQuestTypeLabel(
    QuestType type,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    switch (type) {
      case QuestType.daily:
        return t('quest_type_daily');
      case QuestType.weekly:
        return t('quest_type_weekly');
      case QuestType.special:
        return t('quest_type_special');
      case QuestType.story:
        return t('quest_type_story');
      case QuestType.urgent:
        return t('quest_type_urgent');
      case QuestType.penalty:
        return t('quest_type_penalty');
    }
  }

  void _confirmFailQuest(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    String Function(String, {Map<String, String>? params}) t,
  ) {
    final mutationBusy = ref.watch(questMutationBusyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuestsPage._dialogSurface(ctx),
        title: Text(
          t('fail_quest_title'),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          t('fail_quest_message'),
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: mutationBusy
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(questsProvider.notifier)
                        .failQuest(quest.id, ref);
                    if (context.mounted) {
                      final extra =
                          quest.mandatory && quest.type != QuestType.penalty
                          ? '\n${t('penalty_zone_applied_snack')}'
                          : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${t('quest_failed_snack')}$extra'),
                          backgroundColor: colorScheme.error,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
            child: Text(
              t('fail_quest'),
              style: TextStyle(color: colorScheme.onError),
            ),
          ),
        ],
      ).animate().shake(duration: 300.ms),
    );
  }

  Future<void> _showManualQuestDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final t = useTranslations(ref);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    QuestType selectedType = QuestType.special;
    var isEvaluating = false;

    if (!context.mounted) return;
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: QuestsPage._dialogSurface(ctx),
              title: Text(
                t('create_quest'),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: t('quest_title_label'),
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: t('description'),
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('quest_type'),
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    DropdownButton<QuestType>(
                      dropdownColor: QuestsPage._dialogSurface(ctx),
                      value: selectedType,
                      isExpanded: true,
                      items: QuestType.values
                          .where((e) => e != QuestType.penalty)
                          .map(
                            (e) => DropdownMenuItem<QuestType>(
                              value: e,
                              child: Text(
                                _getQuestTypeLabel(e, t),
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setLocal(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isEvaluating)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      Text(
                        t('manual_quest_help_blurb'),
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isEvaluating ? null : () => Navigator.pop(ctx),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                  onPressed: isEvaluating
                      ? null
                      : () async {
                          if (titleCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t('enter_title')),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                            return;
                          }

                          final hunter = ref.read(hunterProvider);
                          if (hunter == null) return;

                          setLocal(() => isEvaluating = true);

                          try {
                            final questId = const Uuid().v4();
                            final localEval = LocalHeuristicEvaluator();
                            final result = await localEval.evaluateQuest(
                              title: titleCtrl.text,
                              description: descCtrl.text,
                              hunter: hunter,
                              type: selectedType,
                            );

                            DateTime? expiresAt;
                            if (selectedType == QuestType.daily) {
                              expiresAt = DateTime.now().add(
                                const Duration(days: 1),
                              );
                            } else if (selectedType == QuestType.weekly) {
                              expiresAt = DateTime.now().add(
                                const Duration(days: 7),
                              );
                            }

                            final quest = Quest(
                              id: questId,
                              title: titleCtrl.text,
                              description: descCtrl.text,
                              type: selectedType,
                              experienceReward: result.suggestedExp,
                              goldReward: result.suggestedGold,
                              difficulty: result.difficultyRank,
                              tags: result.tags,
                              mandatory:
                                  selectedType == QuestType.daily ||
                                  selectedType == QuestType.weekly,
                              expiresAt: expiresAt,
                            );

                            await ref
                                .read(questsProvider.notifier)
                                .addQuest(quest);

                            if (ctx.mounted) {
                              setLocal(() => isEvaluating = false);
                              Navigator.pop(ctx);
                            }

                            if (!context.mounted) return;
                            final pageScheme = Theme.of(context).colorScheme;

                            final hasAiKey = await AIService.hasApiKey();
                            if (!context.mounted) return;
                            final messenger = ScaffoldMessenger.maybeOf(context);

                            messenger?.showSnackBar(
                              SnackBar(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t(
                                        'manual_quest_created_title',
                                        params: {'title': quest.title},
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hasAiKey
                                          ? t('manual_quest_created_subtitle_ai')
                                          : t(
                                              'manual_quest_created_subtitle_no_ai',
                                            ),
                                      style: TextStyle(
                                        color: pageScheme.onSurface.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (result.systemComment != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        result.systemComment!,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: pageScheme.primary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      t(
                                        'manual_quest_reward_line',
                                        params: {
                                          'rank': '${result.difficultyRank}',
                                          'exp': '${result.suggestedExp}',
                                          'gold': '${result.suggestedGold}',
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    pageScheme.surfaceContainerHighest,
                                duration: const Duration(seconds: 5),
                              ),
                            );

                            if (hasAiKey) {
                              final curA =
                                  ref.read(questsAwaitingAiRefinementIdsProvider);
                              ref
                                  .read(
                                    questsAwaitingAiRefinementIdsProvider
                                        .notifier,
                                  )
                                  .state = {
                                ...curA,
                                questId,
                              };
                              unawaited(
                                _refineManualQuestWithAi(
                                  ref: ref,
                                  questId: questId,
                                  title: titleCtrl.text,
                                  description: descCtrl.text,
                                  hunter: hunter,
                                  type: selectedType,
                                  messenger: messenger,
                                  t: t,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setLocal(() => isEvaluating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка при оценке квеста: $e'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(
                    t('save'),
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 200.ms).scale(curve: Curves.easeOutBack);
          },
        ),
      );
    } finally {
      titleCtrl.dispose();
      descCtrl.dispose();
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

  Future<void> _generateAIQuest(BuildContext context, WidgetRef ref) async {
    final t = useTranslations(ref);
    final colorScheme = Theme.of(context).colorScheme;

    final hasApiKey = await AIService.hasApiKey();
    if (!hasApiKey) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: QuestsPage._dialogSurface(context),
            title: Text(
              t('no_api_key'),
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Text(
              t('no_api_key_message'),
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('ok')),
              ),
            ],
          ).animate().shake(),
        );
      }
      return;
    }

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
                  CircularProgressIndicator(
                    color: colorScheme.secondary,
                  ).animate(onPlay: (c) => c.repeat()).shimmer(),
                  const SizedBox(height: 16),
                  Text(t('generating_quest')),
                ],
              ),
            ),
          ).animate().scale(curve: Curves.easeOutBack),
        ),
      );
    }

    try {
      final hunter = ref.read(hunterProvider);
      final questData = await AIService.generateQuest(
        hunterLevel: hunter?.level.toString(),
        hunterStats: hunter != null
            ? 'Сила: ${hunter.stats.strength}, Ловкость: ${hunter.stats.agility}, Интеллект: ${hunter.stats.intelligence}, Живучесть: ${hunter.stats.vitality}'
            : null,
        lowestStatsFocus: hunter?.describeLowestStatsForPrompt(),
      );

      QuestType questType = QuestType.special;
      final typeStr = questData['type'] as String?;
      if (typeStr != null) {
        questType = QuestType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => QuestType.special,
        );
      }

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final quest = Quest(
        title: questData['title'] as String? ?? 'Новый квест',
        description: questData['description'] as String? ?? 'Описание квеста',
        type: questType,
        experienceReward:
            (questData['experienceReward'] as num?)?.toInt() ?? 20,
        statPointsReward: (questData['statPointsReward'] as num?)?.toInt() ?? 0,
        goldReward: (questData['goldReward'] as num?)?.toInt() ?? 0,
        expiresAt: tomorrow,
      );

      await ref.read(questsProvider.notifier).addQuest(quest);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('quest_created', params: {'title': quest.title})),
            backgroundColor: colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error')}: $e'),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Фоновое уточнение наград через ИИ после мгновенного локального создания квеста.
Future<void> _refineManualQuestWithAi({
  required WidgetRef ref,
  required String questId,
  required String title,
  required String description,
  required Hunter hunter,
  required QuestType type,
  ScaffoldMessengerState? messenger,
  required String Function(String, {Map<String, String>? params}) t,
}) async {
  try {
    final systemId = ref.read(activeSystemIdProvider);
    final rules = ref.read(activeSystemRulesProvider);
    final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
    final tag = switch (nav) {
      SystemId.solo => 'solo',
      SystemId.mage => 'mage',
      SystemId.cultivator => 'cultivator',
      SystemId.custom => 'solo',
    };
    final phraseKey = 'ai_master_loading_${tag}_${Random().nextInt(3)}';
    final phraseMap = Map<String, String>.from(
      ref.read(questAiLoadingPhraseKeyProvider),
    );
    phraseMap[questId] = phraseKey;
    ref.read(questAiLoadingPhraseKeyProvider.notifier).state = phraseMap;

    final refined = await AiEdgeEvaluator().evaluateQuestAiOrNull(
      title: title,
      description: description,
      hunter: hunter,
      type: type,
    );
    if (refined == null) return;

    final q = DatabaseService.getQuest(questId);
    if (q == null || q.status != QuestStatus.active) return;

    await ref.read(questsProvider.notifier).updateQuest(
          q.copyWith(
            experienceReward: refined.suggestedExp,
            goldReward: refined.suggestedGold,
            difficulty: refined.difficultyRank,
            tags: refined.tags,
          ),
        );

    final flash = ref.read(questCardGoldFlashIdsProvider);
    ref.read(questCardGoldFlashIdsProvider.notifier).state = {
      ...flash,
      questId,
    };
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        final cur = ref.read(questCardGoldFlashIdsProvider);
        if (!cur.contains(questId)) return;
        ref.read(questCardGoldFlashIdsProvider.notifier).state = {
          ...cur,
        }..remove(questId);
      }),
    );

    HapticFeedback.mediumImpact();

    messenger?.showSnackBar(
      SnackBar(
        content: Text(t('manual_quest_refined_ai')),
        duration: const Duration(seconds: 4),
      ),
    );
  } finally {
    final w = ref.read(questsAwaitingAiRefinementIdsProvider);
    ref.read(questsAwaitingAiRefinementIdsProvider.notifier).state = {
      ...w,
    }..remove(questId);
    final pm = Map<String, String>.from(
      ref.read(questAiLoadingPhraseKeyProvider),
    )..remove(questId);
    ref.read(questAiLoadingPhraseKeyProvider.notifier).state = pm;
  }
}
