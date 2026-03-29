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
import 'abyss_portal_screen.dart';
import 'lore_portal_screen.dart';
import '../../models/hunter_model.dart';
import '../../models/quest_model.dart';
import '../../services/supabase/public_profiles_service.dart';
import '../system/system_selection_screen.dart';
import 'onboarding_ai_service.dart';
import 'onboarding_models.dart';
import 'typewriter_text.dart';
import 'onboarding_atmosphere.dart';

class OnboardingJourneyScreen extends ConsumerStatefulWidget {
  const OnboardingJourneyScreen({super.key});

  @override
  ConsumerState<OnboardingJourneyScreen> createState() =>
      _OnboardingJourneyScreenState();
}

class _OnboardingJourneyScreenState
    extends ConsumerState<OnboardingJourneyScreen> {
  bool _busy = false;
  String? _error;
  bool _showWhiteFlash = false;
  bool _lorePortalFlash = false;
  bool _lorePortalBusy = false;

  // Persona inputs.
  final _nameCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _weaknessesCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _interest = <String>{};

  @override
  void initState() {
    super.initState();
    final raw = DatabaseService.getOnboardingPersonaRaw();
    final persona = OnboardingPersona.fromMap(raw);
    if (persona != null) {
      _nameCtrl.text = persona.name;
      _strengthsCtrl.text = persona.strengths;
      _weaknessesCtrl.text = persona.weaknesses;
      _goalCtrl.text = persona.goal;
      _interest.addAll(persona.interests);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _strengthsCtrl.dispose();
    _weaknessesCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _go(OnboardingStep step) async {
    await DatabaseService.setOnboardingStep(step);
    if (mounted) setState(() {});
  }

  Future<void> _advanceFromAbyssPortal() async {
    await _go(OnboardingStep.needLore);
  }

  /// Вспышка и переход с портала лора к выбору философии (Фаза 7.5).
  Future<void> _advanceFromLorePortal() async {
    if (_lorePortalBusy) return;
    _lorePortalBusy = true;
    try {
      if (!mounted) return;
      setState(() => _lorePortalFlash = true);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _go(OnboardingStep.needPhilosophySelection);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (mounted) setState(() => _lorePortalFlash = false);
    } finally {
      _lorePortalBusy = false;
    }
  }

  Future<void> _savePersonaAndProceed() async {
    final name = _nameCtrl.text.trim();
    final strengths = _strengthsCtrl.text.trim();
    final weaknesses = _weaknessesCtrl.text.trim();
    final goal = _goalCtrl.text.trim();

    if (name.isEmpty ||
        strengths.isEmpty ||
        weaknesses.isEmpty ||
        goal.isEmpty) {
      setState(() => _error = useTranslations(ref)('onb_master_validation'));
      return;
    }

    final persona = OnboardingPersona(
      name: name,
      strengths: strengths,
      weaknesses: weaknesses,
      selfRole: name,
      goal: goal,
      interests: _interest.toList(),
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
      final persona =
          OnboardingPersona.fromMap(raw ?? {}) ??
          const OnboardingPersona(
            name: 'Игрок',
            strengths: '',
            weaknesses: '',
            selfRole: 'Игрок',
            interests: [],
            goal: 'Стать сильнее',
          );

      final ai = const OnboardingAiService();
      final result = await ai.initPersona(system: cfg, persona: persona);

      // Применяем имя и скрытый класс
      await ref
          .read(hunterProvider.notifier)
          .updateHunter(
            hunter.copyWith(
              name: _nameCtrl.text.trim().isNotEmpty
                  ? _nameCtrl.text.trim()
                  : persona.name,
              hiddenClassId: result.hiddenClass.trim().isNotEmpty
                  ? result.hiddenClass
                  : hunter.hiddenClassId,
            ),
          );

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
            tags: [...q.tags, 'system', 'onboarding'],
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

      // Синхронизация с Hive: без охотника в провайдере HomeShell не откроется.
      ref.read(hunterProvider.notifier).reloadFromLocalDb();
      if (ref.read(hunterProvider) == null) {
        final nm = _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : (persona.name.trim().isNotEmpty ? persona.name : 'Игрок');
        await DatabaseService.createDefaultHunter(nm);
        ref.read(hunterProvider.notifier).reloadFromLocalDb();
      }

      await DatabaseService.setOnboardingStep(OnboardingStep.done);
      if (!mounted) return;

      // Показываем белую вспышку
      setState(() => _showWhiteFlash = true);

      // Ждем, пока экран заполнится белым
      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('onb_done_snack'))));

      ref.read(homeTabIndexProvider.notifier).state = 1; // вкладка "Квесты"
      ref.read(settingsMetaRefreshProvider.notifier).state++;
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
      body: Stack(
        children: [
          ProfileBackdrop(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: switch (step) {
                    OnboardingStep.needAbyssPortal => AbyssPortalScreen(
                      key: const ValueKey('abyss'),
                      onEnterAbyss: _advanceFromAbyssPortal,
                    ),
                    OnboardingStep.needLore => LorePortalScreen(
                      key: const ValueKey('lore'),
                      onContinue: _advanceFromLorePortal,
                    ),
                    OnboardingStep.needPhilosophySelection =>
                      SystemSelectionScreen(
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
                      systemId: ref.watch(activeSystemIdProvider),
                      nameCtrl: _nameCtrl,
                      strengthsCtrl: _strengthsCtrl,
                      weaknessesCtrl: _weaknessesCtrl,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            t('onboarding_recovery_loading'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  },
                ),
              ),
            ),
          ),

          // Вспышка: портал лора → выбор философии
          IgnorePointer(
            ignoring: !_lorePortalFlash,
            child: AnimatedOpacity(
              opacity: _lorePortalFlash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              child: Container(color: Colors.white),
            ),
          ),

          // Эффект белой вспышки при пробуждении
          IgnorePointer(
            ignoring: !_showWhiteFlash,
            child: AnimatedOpacity(
              opacity: _showWhiteFlash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
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
                            colors: [tintA, tintB],
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

class _MasterStep extends StatefulWidget {
  const _MasterStep({
    super.key,
    required this.systemId,
    required this.nameCtrl,
    required this.strengthsCtrl,
    required this.weaknessesCtrl,
    required this.goalCtrl,
    required this.interest,
    required this.error,
    required this.onNext,
  });

  final SystemId systemId;
  final TextEditingController nameCtrl;
  final TextEditingController strengthsCtrl;
  final TextEditingController weaknessesCtrl;
  final TextEditingController goalCtrl;
  final Set<String> interest;
  final String? error;
  final VoidCallback onNext;

  @override
  State<_MasterStep> createState() => _MasterStepState();
}

class _MasterStepState extends State<_MasterStep> {
  int _dialogPhase =
      0; // 0 - name, 1 - strengths/weaknesses, 2 - goal/interests

  void _nextPhase() {
    if (_dialogPhase == 0 && widget.nameCtrl.text.trim().isEmpty) return;
    if (_dialogPhase == 1 &&
        (widget.strengthsCtrl.text.trim().isEmpty ||
            widget.weaknessesCtrl.text.trim().isEmpty)) {
      return;
    }

    setState(() {
      _dialogPhase++;
    });
  }

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
      key: widget.key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Встреча с Мастером',
          style: promoAppBarTitleStyle(context).copyWith(
            color: SoloLevelingColors.textPrimary.withValues(alpha: 0.8),
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ProfileNeonCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                32,
                24,
                32 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnboardingMasterAvatar(systemId: widget.systemId),
                  const SizedBox(height: 20),
                  if (_dialogPhase >= 0) ...[
                    TypewriterText(
                      key: ValueKey('m0-${widget.systemId}'),
                      text:
                          'Голос из тени обращается к тебе.\n— Назови себя, смертный... или тот, кто им был.',
                      charDelay: const Duration(milliseconds: 30),
                      style: GoogleFonts.manrope(
                        color: SoloLevelingColors.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: widget.nameCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _nextPhase(),
                      autofocus: true,
                      style: GoogleFonts.manrope(
                        color: scheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Твоё имя',
                        hintText: 'Охотник...',
                        border: const UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: scheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_dialogPhase >= 1) ...[
                    const SizedBox(height: 40),
                    TypewriterText(
                      text:
                          '— Что движет тобой? Твои искры (сильные стороны) и твои тени (слабые стороны)?',
                      charDelay: const Duration(milliseconds: 30),
                      style: GoogleFonts.manrope(
                        color: SoloLevelingColors.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: widget.strengthsCtrl,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.manrope(
                        color: scheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Искры (Сильные стороны)',
                        hintText: 'Например: “аналитика”, “упорство”...',
                        border: const UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: scheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.weaknessesCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _nextPhase(),
                      style: GoogleFonts.manrope(
                        color: scheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Тени (Слабые стороны)',
                        hintText: 'Например: “лень”, “прокрастинация”...',
                        border: const UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: scheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_dialogPhase >= 2) ...[
                    const SizedBox(height: 40),
                    TypewriterText(
                      text:
                          '— Чем ты занимаешь свой разум? Что ты хочешь выковать из своего сосуда?',
                      charDelay: const Duration(milliseconds: 30),
                      style: GoogleFonts.manrope(
                        color: SoloLevelingColors.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: widget.goalCtrl,
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.manrope(
                        color: scheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Твоя главная цель',
                        hintText: 'Например: “стать сеньором”, “похудеть”...',
                        border: const UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: scheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (final c in chips)
                          FilterChip(
                            selected: widget.interest.contains(c['id']),
                            label: Text(c['label'] ?? ''),
                            labelStyle: GoogleFonts.manrope(
                              color: widget.interest.contains(c['id'])
                                  ? scheme.onSecondary
                                  : SoloLevelingColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedColor: scheme.secondary,
                            backgroundColor: scheme.surface.withValues(
                              alpha: 0.5,
                            ),
                            checkmarkColor: scheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (v) {
                              final id = c['id'];
                              if (id == null) return;
                              setState(() {
                                if (v) {
                                  widget.interest.add(id);
                                } else {
                                  widget.interest.remove(id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],

                  if (widget.error != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      widget.error!,
                      style: GoogleFonts.manrope(
                        color: SoloLevelingColors.warning,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 48),
                  if (_dialogPhase < 2)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _nextPhase,
                        child: Text(
                          'Ответить',
                          style: GoogleFonts.manrope(
                            color: scheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: widget.onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.secondary,
                        foregroundColor: scheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Завершить контракт',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
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
