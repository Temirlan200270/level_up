import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/progression_gates.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/systems/custom_rules_preset.dart';
import '../../core/systems/generated_system_theme_json.dart';
import '../../models/quest_model.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/providers.dart';
import '../../core/system_visuals_extension.dart';

class CustomSystemBuilderPage extends ConsumerStatefulWidget {
  const CustomSystemBuilderPage({
    super.key,
    this.philosophyPickerIsFirstRun = false,
  });

  /// Первый выбор философии в онбординге — полный доступ к конструктору без уровня 10.
  final bool philosophyPickerIsFirstRun;

  @override
  ConsumerState<CustomSystemBuilderPage> createState() =>
      _CustomSystemBuilderPageState();
}

class _CustomSystemBuilderPageState extends ConsumerState<CustomSystemBuilderPage> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedSlug;
  late final TextEditingController _slugCtrl;
  List<String> _customSlugs = const ['default'];

  late final TextEditingController _bgPathCtrl;
  late SystemBackgroundKind _bgKind;
  late SystemParticlesKind _particlesKind;
  double _panelRadius = 12;

  late final TextEditingController _ideaCtrl;
  late final TextEditingController _levelCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _energyCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _voiceCtrl;
  late final TextEditingController _toneCtrl;
  late final TextEditingController _promptCtrl;

  late CustomRulesPreset _preset;
  bool _aiBusy = false;
  String? _aiError;
  GeneratedSystemThemeJson? _aiPreview;

  String _slugNormalize(String slug) {
    final s = slug.trim().toLowerCase();
    if (s.isEmpty) return 'default';
    final cleaned = s.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    return cleaned.isEmpty ? 'default' : cleaned;
  }

  String? _slugValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Укажите ID мира';
    if (s.length > 28) return 'Слишком длинный ID';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s)) {
      return 'Разрешены только латиница/цифры/подчёркивания';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedSlug = DatabaseService.getActiveCustomSystemSlug();
    _customSlugs = DatabaseService.getCustomSystemSlugs();
    _slugCtrl = TextEditingController(text: _selectedSlug);

    _bgPathCtrl = TextEditingController(
      text: DatabaseService.getCustomSystemBackgroundAssetPathForSlug(_selectedSlug) ?? '',
    );
    _bgKind = switch (
        (DatabaseService.getCustomSystemBackgroundKindForSlug(_selectedSlug) ??
                'grid')
            .toLowerCase()) {
      'parchment' => SystemBackgroundKind.parchment,
      'mist' => SystemBackgroundKind.mist,
      _ => SystemBackgroundKind.grid,
    };
    _particlesKind = switch (
        (DatabaseService.getCustomSystemParticlesKindForSlug(_selectedSlug) ??
                'sparkles')
            .toLowerCase()) {
      'runes' => SystemParticlesKind.runes,
      'petals' => SystemParticlesKind.petals,
      'none' => SystemParticlesKind.none,
      _ => SystemParticlesKind.sparkles,
    };
    _panelRadius = (DatabaseService.getCustomSystemPanelRadiusForSlug(_selectedSlug) ?? 12)
        .clamp(10, 24)
        .toDouble();

    final cfg = DatabaseService.getCustomSystemConfigForSlug(_selectedSlug);
    final raw =
        DatabaseService.getCustomSystemDictionaryRawForSlug(_selectedSlug);
    _ideaCtrl = TextEditingController();
    _levelCtrl = TextEditingController(
      text: raw['levelName'] ?? cfg.dictionary.levelName,
    );
    _expCtrl = TextEditingController(
      text: raw['experienceName'] ?? cfg.dictionary.experienceName,
    );
    _currencyCtrl = TextEditingController(
      text: raw['currencyName'] ?? cfg.dictionary.currencyName,
    );
    _energyCtrl = TextEditingController(
      text: raw['energyName'] ?? cfg.dictionary.energyName,
    );
    _skillsCtrl = TextEditingController(
      text: raw['skillsName'] ?? cfg.dictionary.skillsName,
    );

    _voiceCtrl = TextEditingController(
        text: DatabaseService.getCustomSystemAiVoiceNameForSlug(_selectedSlug));
    _toneCtrl = TextEditingController(
        text: DatabaseService.getCustomSystemAiToneHintForSlug(_selectedSlug));
    _promptCtrl =
        TextEditingController(
            text:
                DatabaseService.getCustomSystemAiUserPromptForSlug(_selectedSlug));

    _preset = CustomRulesPreset.fromValue(
        DatabaseService.getCustomSystemRulesPresetForSlug(_selectedSlug));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (DatabaseService.getHunter() == null) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Полная Лаборатория (ИИ, фон, токены); иначе — только термины и пресет правил.
  bool _isLaboratoryUnlocked() {
    final hunter = DatabaseService.getHunter();
    if (hunter == null) return false;
    final gate10 = DatabaseService.getAllQuests()
        .where((q) => q.status == QuestStatus.completed)
        .any((q) => q.tags.contains('story_gate_10'));
    return ProgressionGates.canOpenLaboratory(
      hunterLevel: hunter.level,
      philosophyPickerIsFirstRun: widget.philosophyPickerIsFirstRun,
      completedStoryGate10: gate10,
    );
  }

  @override
  void dispose() {
    _ideaCtrl.dispose();
    _levelCtrl.dispose();
    _expCtrl.dispose();
    _currencyCtrl.dispose();
    _energyCtrl.dispose();
    _skillsCtrl.dispose();
    _voiceCtrl.dispose();
    _toneCtrl.dispose();
    _promptCtrl.dispose();
    _slugCtrl.dispose();
    _bgPathCtrl.dispose();
    super.dispose();
  }

  String _presetLabelKey(CustomRulesPreset p) {
    return switch (p) {
      CustomRulesPreset.balanced => 'custom_rules_balanced',
      CustomRulesPreset.solo => 'custom_rules_solo',
      CustomRulesPreset.mage => 'custom_rules_mage',
      CustomRulesPreset.cultivator => 'custom_rules_cultivator',
    };
  }

  String? _requiredShort(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '—';
    if (s.length > 24) return '—';
    return null;
  }

  String? _optionalLong(String? v) {
    final s = (v ?? '').trim();
    if (s.length > 500) return '—';
    return null;
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() == true;
    if (!ok) return;

    final slug = _slugNormalize(_selectedSlug);
    await DatabaseService.setCustomSystemSlugExists(slug);

    await DatabaseService.setCustomSystemBackgroundAssetPathForSlug(
      slug,
      _bgPathCtrl.text.trim().isEmpty ? null : _bgPathCtrl.text.trim(),
    );
    await DatabaseService.setCustomSystemBackgroundKindForSlug(
      slug,
      _bgKind.name,
    );
    await DatabaseService.setCustomSystemParticlesKindForSlug(
      slug,
      _particlesKind.name,
    );
    await DatabaseService.setCustomSystemPanelRadiusForSlug(
      slug,
      _panelRadius,
    );

    await DatabaseService.setCustomSystemDictionaryRawForSlug(slug, {
      'levelName': _levelCtrl.text.trim(),
      'experienceName': _expCtrl.text.trim(),
      'currencyName': _currencyCtrl.text.trim(),
      'energyName': _energyCtrl.text.trim(),
      'skillsName': _skillsCtrl.text.trim(),
    });

    await DatabaseService.setCustomSystemRulesPresetForSlug(
      slug,
      _preset.value,
    );
    await DatabaseService.setCustomSystemAiVoiceNameForSlug(
      slug,
      _voiceCtrl.text.trim(),
    );
    await DatabaseService.setCustomSystemAiToneHintForSlug(
      slug,
      _toneCtrl.text.trim(),
    );
    await DatabaseService.setCustomSystemAiUserPromptForSlug(
      slug,
      _promptCtrl.text.trim(),
    );

    ref.read(settingsMetaRefreshProvider.notifier).state++;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(useTranslations(ref)('custom_saved'))),
    );
  }

  Future<void> _resetToDefaults() async {
    final cfg = DatabaseService.getCustomSystemConfigForSlug('default');
    _levelCtrl.text = 'Уровень';
    _expCtrl.text = 'Опыт';
    _currencyCtrl.text = 'Валюта';
    _energyCtrl.text = 'Энергия';
    _skillsCtrl.text = 'Навыки';
    _voiceCtrl.text = 'Ваш голос';
    _toneCtrl.text = cfg.aiToneHint;
    _promptCtrl.text = '';
    setState(() {
      _preset = CustomRulesPreset.balanced;
      _aiPreview = null;
      _aiError = null;
    });
    await _save();
  }

  CustomRulesPreset _presetFromRaw(String raw) {
    return CustomRulesPreset.fromValue(raw);
  }

  bool _isTooBright(Color c) => c.computeLuminance() > 0.60;

  Future<void> _generateAiWorld() async {
    if (!_isLaboratoryUnlocked()) return;
    final t = useTranslations(ref);
    final idea = _ideaCtrl.text.trim();
    if (idea.isEmpty) {
      setState(() => _aiError = t('custom_ai_idea_required'));
      return;
    }
    if (_aiBusy) return;

    setState(() {
      _aiBusy = true;
      _aiError = null;
    });
    try {
      final res = await AIService.generateCustomSystemThemeJson(
        systemIdea: idea,
        rulesPreset: _preset.value,
        systemIdValue: 'custom_${_slugNormalize(_selectedSlug)}',
        exampleTerminology: const {
          'exp': 'Опыт',
          'level': 'Уровень',
          'currency': 'Золото',
          'sp': 'Очки навыков',
          'system': 'Система',
        },
      );
      setState(() {
        _aiPreview = res;
      });
    } catch (e) {
      setState(() => _aiError = '${t('custom_ai_error')}: $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  String _colorToHex(Color c) {
    final rgb = c.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _initializeFromPreview(GeneratedSystemThemeJson p) async {
    final t = useTranslations(ref);
    final backup = DatabaseService.exportGameBackupJson();
    try {
      _levelCtrl.text = p.terminology.levelName;
      _expCtrl.text = p.terminology.expName;
      _currencyCtrl.text = p.terminology.currencyName;
      _voiceCtrl.text = p.terminology.systemName;
      _toneCtrl.text = t('custom_ai_generated_tone');
      _promptCtrl.text = p.aiPrompt;
      setState(() => _preset = _presetFromRaw(p.rulesPreset));

      final slug = _slugNormalize(_selectedSlug);
      await DatabaseService.setCustomSystemThemeNameForSlug(slug, p.themeName);
      await DatabaseService.setCustomSystemColorsHexForSlug(slug, {
        'background': _colorToHex(p.colors.background),
        'primary': _colorToHex(p.colors.primary),
        'surface': _colorToHex(p.colors.surface),
        'glow': _colorToHex(p.colors.glow),
      });

      await _save();

      // Активируем только что инициализированный мир и возвращаемся назад.
      await ref.read(activeSystemIdProvider.notifier).setCustomSystemSlug(slug);
      await DatabaseService.setSystemSelectionShown(true);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      await DatabaseService.importGameBackupJson(backup);
      ref.read(hunterProvider.notifier).reloadFromLocalDb();
      ref.read(questsProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('custom_ai_error')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final lab = _isLaboratoryUnlocked();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: t('back'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t('custom_system_title'),
                        style: GoogleFonts.manrope(
                          color: SoloLevelingColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Text(
                  t('custom_system_subtitle'),
                  style: GoogleFonts.manrope(
                    color: SoloLevelingColors.textSecondary,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!lab)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 22,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t(
                                'laboratory_restricted_banner',
                                params: {
                                  'level':
                                      '${ProgressionGates.laboratoryMinLevel}',
                                },
                              ),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                height: 1.4,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Каталог Custom-миров',
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSlug,
                                items: [
                                  for (final s in _customSlugs)
                                    DropdownMenuItem(
                                      value: s,
                                      child: Text(s == 'default' ? 'default' : s),
                                    ),
                                ],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  final next = _slugNormalize(v);
                                  await DatabaseService
                                      .setCustomSystemSlugExists(next);
                                  _customSlugs = DatabaseService.getCustomSystemSlugs();
                                  _selectedSlug = next;
                                  _slugCtrl.text = next;

                                  final cfg =
                                      DatabaseService.getCustomSystemConfigForSlug(next);
                                  final raw = DatabaseService
                                      .getCustomSystemDictionaryRawForSlug(next);
                                  _levelCtrl.text =
                                      raw['levelName'] ?? cfg.dictionary.levelName;
                                  _expCtrl.text =
                                      raw['experienceName'] ?? cfg.dictionary.experienceName;
                                  _currencyCtrl.text =
                                      raw['currencyName'] ?? cfg.dictionary.currencyName;
                                  _energyCtrl.text =
                                      raw['energyName'] ?? cfg.dictionary.energyName;
                                  _skillsCtrl.text =
                                      raw['skillsName'] ?? cfg.dictionary.skillsName;
                                  _voiceCtrl.text = DatabaseService
                                      .getCustomSystemAiVoiceNameForSlug(next);
                                  _toneCtrl.text =
                                      DatabaseService.getCustomSystemAiToneHintForSlug(next);
                                  _promptCtrl.text =
                                      DatabaseService.getCustomSystemAiUserPromptForSlug(next);
                                  _preset = CustomRulesPreset.fromValue(
                                      DatabaseService.getCustomSystemRulesPresetForSlug(next));
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  labelText: 'Выбранный мир',
                                  labelStyle: GoogleFonts.manrope(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: 'ID мира (slug)',
                                controller: _slugCtrl,
                                validator: _slugValidator,
                                readOnly: !lab,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: !lab
                                    ? null
                                    : () async {
                                  final next = _slugNormalize(_slugCtrl.text);
                                  await DatabaseService.setCustomSystemSlugExists(next);
                                  _customSlugs =
                                      DatabaseService.getCustomSystemSlugs();
                                  _selectedSlug = next;
                                  _slugCtrl.text = next;

                                  _bgPathCtrl.text = DatabaseService
                                          .getCustomSystemBackgroundAssetPathForSlug(next) ??
                                      '';
                                  _bgKind = switch (
                                      (DatabaseService.getCustomSystemBackgroundKindForSlug(
                                                  next) ??
                                              'grid')
                                          .toLowerCase()) {
                                    'parchment' => SystemBackgroundKind.parchment,
                                    'mist' => SystemBackgroundKind.mist,
                                    _ => SystemBackgroundKind.grid,
                                  };
                                  _particlesKind = switch (
                                      (DatabaseService.getCustomSystemParticlesKindForSlug(
                                                  next) ??
                                              'sparkles')
                                          .toLowerCase()) {
                                    'runes' => SystemParticlesKind.runes,
                                    'petals' => SystemParticlesKind.petals,
                                    'none' => SystemParticlesKind.none,
                                    _ => SystemParticlesKind.sparkles,
                                  };
                                  _panelRadius = (DatabaseService.getCustomSystemPanelRadiusForSlug(
                                              next) ??
                                          12)
                                      .clamp(10, 24)
                                      .toDouble();

                                  final cfg =
                                      DatabaseService.getCustomSystemConfigForSlug(next);
                                  final raw = DatabaseService
                                      .getCustomSystemDictionaryRawForSlug(next);
                                  _levelCtrl.text =
                                      raw['levelName'] ?? cfg.dictionary.levelName;
                                  _expCtrl.text =
                                      raw['experienceName'] ?? cfg.dictionary.experienceName;
                                  _currencyCtrl.text =
                                      raw['currencyName'] ?? cfg.dictionary.currencyName;
                                  _energyCtrl.text =
                                      raw['energyName'] ?? cfg.dictionary.energyName;
                                  _skillsCtrl.text =
                                      raw['skillsName'] ?? cfg.dictionary.skillsName;
                                  _voiceCtrl.text =
                                      DatabaseService.getCustomSystemAiVoiceNameForSlug(next);
                                  _toneCtrl.text =
                                      DatabaseService.getCustomSystemAiToneHintForSlug(next);
                                  _promptCtrl.text =
                                      DatabaseService.getCustomSystemAiUserPromptForSlug(next);
                                  _preset = CustomRulesPreset.fromValue(
                                      DatabaseService.getCustomSystemRulesPresetForSlug(next));

                                  setState(() {});
                                },
                                child: const Text('Переключить мир'),
                              ),
                            ],
                          ),
                        ),
                        if (lab) ...[
                        const SizedBox(height: 14),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Визуальный фон мира',
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<SystemBackgroundKind>(
                                initialValue: _bgKind,
                                items: const [
                                  DropdownMenuItem(
                                    value: SystemBackgroundKind.grid,
                                    child: Text('Grid (Solo)'),
                                  ),
                                  DropdownMenuItem(
                                    value: SystemBackgroundKind.parchment,
                                    child: Text('Parchment (Mage)'),
                                  ),
                                  DropdownMenuItem(
                                    value: SystemBackgroundKind.mist,
                                    child: Text('Mist (Cultivator)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _bgKind = v);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Тип фона (fallback)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<SystemParticlesKind>(
                                initialValue: _particlesKind,
                                items: const [
                                  DropdownMenuItem(
                                    value: SystemParticlesKind.sparkles,
                                    child: Text('Sparkles'),
                                  ),
                                  DropdownMenuItem(
                                    value: SystemParticlesKind.runes,
                                    child: Text('Runes'),
                                  ),
                                  DropdownMenuItem(
                                    value: SystemParticlesKind.petals,
                                    child: Text('Petals'),
                                  ),
                                  DropdownMenuItem(
                                    value: SystemParticlesKind.none,
                                    child: Text('None'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _particlesKind = v);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Частицы',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label:
                                    'Фон (assets/…, file://…, или https://…; пусто = только fallback)',
                                controller: _bgPathCtrl,
                                validator: (_) => null,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Радиус панелей: ${_panelRadius.toStringAsFixed(0)}',
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Slider(
                                value: _panelRadius,
                                min: 10,
                                max: 24,
                                divisions: 14,
                                onChanged: (v) => setState(() => _panelRadius = v),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Если фон не задан или не загрузился — приложение автоматически использует процедурный фон и всё продолжит работать.',
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textTertiary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t('custom_ai_lab_title'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('custom_ai_idea_label'),
                                controller: _ideaCtrl,
                                validator: (_) => null,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _aiBusy ? null : _generateAiWorld,
                                      child: Text(
                                        _aiBusy
                                            ? t('custom_ai_generating')
                                            : t('custom_ai_generate'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: (_aiBusy || _aiPreview == null)
                                          ? null
                                          : _generateAiWorld,
                                      child: Text(t('custom_ai_regenerate')),
                                    ),
                                  ),
                                ],
                              ),
                              if (_aiError != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _aiError!,
                                  style: GoogleFonts.manrope(
                                    color: SoloLevelingColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_aiPreview != null) ...[
                                const SizedBox(height: 14),
                                ProfileNeonCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              t('custom_ai_preview_title'),
                                              style: GoogleFonts.manrope(
                                                color: SoloLevelingColors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if (_isTooBright(_aiPreview!.colors.primary) ||
                                              _isTooBright(_aiPreview!.colors.glow))
                                            ProfilePillBadge(
                                              label: t('custom_ai_color_warning'),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _PreviewRow(
                                        label: t('custom_ai_preview_terms'),
                                        value:
                                            '${_aiPreview!.terminology.levelName} · ${_aiPreview!.terminology.expName} · ${_aiPreview!.terminology.currencyName}',
                                      ),
                                      const SizedBox(height: 8),
                                      _PreviewRow(
                                        label: t('custom_ai_voice_label'),
                                        value: _aiPreview!.terminology.systemName,
                                      ),
                                      const SizedBox(height: 8),
                                      _PreviewRow(
                                        label: t('custom_rules_preset_label'),
                                        value: _aiPreview!.rulesPreset,
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _ColorDot(
                                            label: t('custom_ai_color_bg'),
                                            color: _aiPreview!.colors.background,
                                          ),
                                          _ColorDot(
                                            label: t('custom_ai_color_primary'),
                                            color: _aiPreview!.colors.primary,
                                          ),
                                          _ColorDot(
                                            label: t('custom_ai_color_surface'),
                                            color: _aiPreview!.colors.surface,
                                          ),
                                          _ColorDot(
                                            label: t('custom_ai_color_glow'),
                                            color: _aiPreview!.colors.glow,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: _aiBusy
                                            ? null
                                            : () => _initializeFromPreview(_aiPreview!),
                                        child: Text(t('custom_ai_initialize')),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ],
                        const SizedBox(height: 14),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t('custom_terms_title'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: t('level'),
                                controller: _levelCtrl,
                                validator: _requiredShort,
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('experience'),
                                controller: _expCtrl,
                                validator: _requiredShort,
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('custom_currency_label'),
                                controller: _currencyCtrl,
                                validator: _requiredShort,
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('custom_energy_label'),
                                controller: _energyCtrl,
                                validator: _requiredShort,
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('skills'),
                                controller: _skillsCtrl,
                                validator: _requiredShort,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t('custom_rules_title'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<CustomRulesPreset>(
                                initialValue: _preset,
                                items: [
                                  for (final p in CustomRulesPreset.values)
                                    DropdownMenuItem(
                                      value: p,
                                      child: Text(t(_presetLabelKey(p))),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _preset = v);
                                },
                                decoration: InputDecoration(
                                  labelText: t('custom_rules_preset_label'),
                                  labelStyle: GoogleFonts.manrope(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('custom_rules_hint'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textTertiary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lab) ...[
                        const SizedBox(height: 14),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t('custom_ai_title'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: t('custom_ai_voice_label'),
                                controller: _voiceCtrl,
                                validator: _requiredShort,
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('custom_ai_tone_label'),
                                controller: _toneCtrl,
                                validator: _requiredShort,
                              ),
                              const SizedBox(height: 10),
                              _Field(
                                label: t('custom_ai_prompt_label'),
                                controller: _promptCtrl,
                                validator: _optionalLong,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('custom_ai_prompt_hint'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textTertiary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetToDefaults,
                                child: Text(t('custom_reset')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _save,
                                child: Text(t('custom_save')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.validator,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      style: GoogleFonts.manrope(color: SoloLevelingColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(color: SoloLevelingColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: SoloLevelingColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              color: SoloLevelingColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        color: color.withValues(alpha: 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: SoloLevelingColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

