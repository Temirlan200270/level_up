import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/systems/system_id.dart';
import '../../core/systems/systems_catalog.dart';
import '../../services/database_service.dart';
import '../../services/providers.dart';
import '../../models/hunter_model.dart';
import '../../models/quest_model.dart';
import '../../services/supabase/public_profiles_service.dart';
import '../system/system_selection_screen.dart';
import 'onboarding_ai_service.dart';
import 'onboarding_models.dart';
import 'typewriter_text.dart';

class OnboardingJourneyScreen extends ConsumerStatefulWidget {
  const OnboardingJourneyScreen({super.key});

  @override
  ConsumerState<OnboardingJourneyScreen> createState() =>
      _OnboardingJourneyScreenState();
}

class _OnboardingJourneyScreenState extends ConsumerState<OnboardingJourneyScreen> {
  bool _busy = false;
  String? _error;

  // Persona inputs.
  final _roleCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _interest = <String>{};

  @override
  void initState() {
    super.initState();
    final raw = DatabaseService.getOnboardingPersonaRaw();
    final persona = OnboardingPersona.fromMap(raw);
    if (persona != null) {
      _roleCtrl.text = persona.selfRole;
      _goalCtrl.text = persona.goal;
      _interest.addAll(persona.interests);
    }
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _go(OnboardingStep step) async {
    await DatabaseService.setOnboardingStep(step);
    if (mounted) setState(() {});
  }

  Future<void> _savePersonaAndProceed() async {
    final role = _roleCtrl.text.trim();
    final goal = _goalCtrl.text.trim();
    if (role.isEmpty || goal.isEmpty) {
      setState(() => _error = useTranslations(ref)('onb_master_validation'));
      return;
    }
    final persona = OnboardingPersona(
      selfRole: role,
      interests: _interest.toList(),
      goal: goal,
    );
    await DatabaseService.setOnboardingPersonaRaw(persona.toMap());
    await _go(OnboardingStep.needAiProcessing);
  }

  Future<void> _runAiAndApply() async {
    if (_busy) return;
    final t = useTranslations(ref);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final hunter = ref.read(hunterProvider) ?? Hunter(name: '');
      final systemId = ref.read(activeSystemIdProvider);
      final cfg = systemId == SystemId.custom
          ? DatabaseService.getCustomSystemConfigForSlug(
              ref.read(activeCustomSlugProvider),
            )
          : SystemsCatalog.forId(systemId);
      final raw = DatabaseService.getOnboardingPersonaRaw();
      final persona = OnboardingPersona.fromMap(raw) ??
          const OnboardingPersona(selfRole: 'Игрок', interests: [], goal: 'Стать сильнее');

      final ai = const OnboardingAiService();
      final result = await ai.initPersona(system: cfg, persona: persona);

      // Применяем скрытый класс.
      if ((result.hiddenClass).trim().isNotEmpty) {
        await ref.read(hunterProvider.notifier).updateHunter(
              hunter.copyWith(hiddenClassId: result.hiddenClass),
            );
      }

      // Создаём стартовые квесты (в текущей системе).
      for (final q in result.quests.take(5)) {
        await DatabaseService.addQuest(
          Quest(
            title: q.title,
            description: q.description,
            type: QuestType.story,
            experienceReward: q.exp,
            goldReward: q.gold,
            statPointsReward: q.statPoints,
            mandatory: q.mandatory,
            tags: [
              ...q.tags,
              'system',
              'onboarding',
            ],
            difficulty: q.difficulty,
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        );
      }

      // Закрываем legacy-«Пробуждение», чтобы не всплыло поверх.
      await DatabaseService.setAwakeningTutorialSceneShown(true);

      // Публичный профиль (если Supabase настроен и есть сессия).
      try {
        await PublicProfilesService(Supabase.instance.client).upsertMyProfile(
          hunter: ref.read(hunterProvider) ?? hunter,
          activeSystemId: systemId,
          hiddenClass: result.hiddenClass,
        );
      } catch (_) {
        // Игнорируем: онбординг должен завершаться и без облака.
      }

      await DatabaseService.setOnboardingStep(OnboardingStep.done);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('onb_done_snack'))),
      );

      // Возвращаемся в `HomeShell`, чтобы нижняя навигация была на месте.
      ref.read(homeTabIndexProvider.notifier).state = 1; // вкладка "Квесты"
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '${t('error')}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final step = DatabaseService.getOnboardingStep();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: switch (step) {
                OnboardingStep.needLore => _LoreStep(
                    key: const ValueKey('lore'),
                    onNext: () => _go(OnboardingStep.needPhilosophySelection),
                  ),
                OnboardingStep.needPhilosophySelection => SystemSelectionScreen(
                    key: const ValueKey('ph'),
                    isFirstRun: true,
                    showBackButton: false,
                    onClose: () {
                      // Экран сам выставляет следующий `OnboardingStep`.
                      if (mounted) setState(() {});
                    },
                  ),
                OnboardingStep.needMasterEncounter => _MasterStep(
                    key: const ValueKey('master'),
                    roleCtrl: _roleCtrl,
                    goalCtrl: _goalCtrl,
                    interest: _interest,
                    error: _error,
                    onNext: _savePersonaAndProceed,
                  ),
                OnboardingStep.needAiProcessing => _ProcessingStep(
                    key: const ValueKey('ai'),
                    busy: _busy,
                    error: _error,
                    onStart: _runAiAndApply,
                    accent: scheme.secondary,
                  ),
                OnboardingStep.done => Center(
                    key: const ValueKey('done'),
                    child: Text(
                      t('onb_done'),
                      style: GoogleFonts.manrope(
                        color: SoloLevelingColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoreStep extends StatelessWidget {
  const _LoreStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          'Портал Лора',
          style: promoAppBarTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ProfileNeonCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TypewriterText(
                  text:
                      'Ты стоишь на границе миров. Здесь рутина превращается в силу, а привычки — в заклинания.\n\n'
                      'Система спрашивает: готов ли ты пройти через врата и назвать своё намерение?',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.secondary.withValues(alpha: 0.9),
                    foregroundColor: scheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Шагнуть в неизвестность'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemCardArt extends StatefulWidget {
  const _SystemCardArt({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String backgroundAsset;
  final VoidCallback onTap;

  @override
  State<_SystemCardArt> createState() => _SystemCardArtState();
}

class _SystemCardArtState extends State<_SystemCardArt> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tintA = widget.color.withValues(alpha: 0.22);
    final tintB = scheme.surface.withValues(alpha: 0.30);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: ProfileNeonCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: SizedBox(
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.82,
                        child: SvgPicture.asset(
                          widget.backgroundAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              tintA,
                              tintB,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: widget.color.withValues(alpha: 0.14),
                              border: Border.all(
                                color: widget.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(widget.icon, color: widget.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.manrope(
                                    color: SoloLevelingColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.subtitle,
                                  style: GoogleFonts.manrope(
                                    color: SoloLevelingColors.textSecondary,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MasterStep extends StatelessWidget {
  const _MasterStep({
    super.key,
    required this.roleCtrl,
    required this.goalCtrl,
    required this.interest,
    required this.error,
    required this.onNext,
  });

  final TextEditingController roleCtrl;
  final TextEditingController goalCtrl;
  final Set<String> interest;
  final String? error;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = const <Map<String, String>>[
      {'id': 'code', 'label': 'Код'},
      {'id': 'sport', 'label': 'Спорт'},
      {'id': 'study', 'label': 'Учёба'},
      {'id': 'health', 'label': 'Здоровье'},
      {'id': 'focus', 'label': 'Фокус'},
      {'id': 'mind', 'label': 'Менталка'},
      {'id': 'creative', 'label': 'Творчество'},
      {'id': 'business', 'label': 'Бизнес'},
    ];

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          'Встреча с Мастером',
          style: promoAppBarTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ProfileNeonCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TypewriterText(
                    text:
                        'Голос из тени обращается к тебе.\n\n'
                        '— Назови себя. И скажи, зачем ты явился.',
                    charDelay: const Duration(milliseconds: 14),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: roleCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Кто ты? (роль)',
                      hintText: 'Например: “программист”, “студент”, “спортсмен”…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: goalCtrl,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Что хочешь подтянуть?',
                      hintText: 'Например: “дисциплину”, “фокус”, “здоровье”…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Увлечения',
                    style: GoogleFonts.manrope(
                      color: SoloLevelingColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in chips)
                        FilterChip(
                          selected: interest.contains(c['id']),
                          label: Text(c['label'] ?? ''),
                          selectedColor: scheme.secondary.withValues(alpha: 0.22),
                          checkmarkColor: scheme.secondary,
                          onSelected: (v) {
                            final id = c['id'];
                            if (id == null) return;
                            if (v) {
                              interest.add(id);
                            } else {
                              interest.remove(id);
                            }
                            (context as Element).markNeedsBuild();
                          },
                        ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: GoogleFonts.manrope(
                        color: SoloLevelingColors.warning,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onNext,
                    child: const Text('Завершить диалог'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({
    super.key,
    required this.busy,
    required this.error,
    required this.onStart,
    required this.accent,
  });

  final bool busy;
  final String? error;
  final VoidCallback onStart;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          'Синхронизация',
          style: promoAppBarTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ProfileNeonCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Система анализирует твоё намерение и подбирает скрытый класс.\n\n'
                  'Первые квесты будут сгенерированы прямо сейчас.',
                  style: GoogleFonts.manrope(
                    color: SoloLevelingColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                if (busy) ...[
                  LinearProgressIndicator(
                    minHeight: 10,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Калибровка…',
                    style: GoogleFonts.manrope(
                      color: SoloLevelingColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: onStart,
                    child: const Text('Начать инициализацию'),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: GoogleFonts.manrope(
                      color: SoloLevelingColors.warning,
                      height: 1.35,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Если Edge Function недоступна, будет использован безопасный локальный fallback.',
                  style: GoogleFonts.manrope(
                    color: SoloLevelingColors.textTertiary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

