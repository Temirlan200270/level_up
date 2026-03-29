import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/translations.dart';
import '../../core/systems/system_id.dart';
import '../../core/systems/systems_catalog.dart';
import 'custom_system_builder_page.dart';
import 'system_lore_fullscreen_page.dart';
import '../../core/progression_gates.dart';
import '../../services/database_service.dart';
import '../../services/providers.dart';

class SystemSelectionScreen extends ConsumerStatefulWidget {
  const SystemSelectionScreen({
    super.key,
    this.isFirstRun = false,
    this.onClose,
    this.showBackButton = true,
  });

  final bool isFirstRun;
  final VoidCallback? onClose;
  final bool showBackButton;

  @override
  ConsumerState<SystemSelectionScreen> createState() =>
      _SystemSelectionScreenState();
}

class _SystemSelectionScreenState extends ConsumerState<SystemSelectionScreen> {
  late final PageController _controller;

  static const _systems = <SystemId>[
    SystemId.solo,
    SystemId.mage,
    SystemId.cultivator,
    SystemId.custom,
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(activeSystemIdProvider);
    final initialIndex = _systems.indexOf(current).clamp(0, _systems.length - 1);
    _controller = PageController(viewportFraction: 0.9, initialPage: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _nameKey(SystemId id) {
    switch (id) {
      case SystemId.solo:
        return 'system_solo';
      case SystemId.mage:
        return 'system_mage';
      case SystemId.cultivator:
        return 'system_cultivator';
      case SystemId.custom:
        return 'system_custom';
    }
  }

  Future<void> _showLoreDialog(
    BuildContext context,
    String Function(String, {Map<String, String>? params}) t,
    SystemId id,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SystemLoreFullscreenPage(
          systemId: id,
          title: t(_nameKey(id)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(activeSystemIdProvider);
    final activeCustomSlug = ref.watch(activeCustomSlugProvider);

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
                    if (widget.showBackButton)
                      IconButton(
                        onPressed: () {
                          final onClose = widget.onClose;
                          if (onClose != null) {
                            onClose();
                            return;
                          }
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: t('back'),
                      )
                    else
                      const SizedBox(width: 48),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t('system_philosophy'),
                        style: GoogleFonts.manrope(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // баланс симметрии
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Text(
                  t('system_philosophy_subtitle'),
                  style: GoogleFonts.manrope(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _systems.length,
                  itemBuilder: (context, index) {
                    final id = _systems[index];
                    final cfg = id == SystemId.custom
                        ? DatabaseService.getCustomSystemConfigForSlug(
                            activeCustomSlug,
                          )
                        : SystemsCatalog.forId(id);
                    final isActive = id == current;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: ProfileNeonCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.secondary,
                                        Theme.of(context).colorScheme.primary,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t(_nameKey(id)),
                                    style: GoogleFonts.manrope(
                                      color: scheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  ProfilePillBadge(label: t('active')),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${cfg.aiVoiceName} · ${cfg.aiToneHint}',
                              style: GoogleFonts.manrope(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (id == SystemId.custom) ...[
                              Text(
                                DatabaseService.getCustomSystemThemeNameForSlug(
                                  activeCustomSlug,
                                ),
                                style: GoogleFonts.manrope(
                                  color: scheme.outline,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            _TermRow(
                              label: t('level'),
                              value: cfg.dictionary.levelName,
                            ),
                            const SizedBox(height: 10),
                            _TermRow(
                              label: t('experience'),
                              value: cfg.dictionary.experienceName,
                            ),
                            const SizedBox(height: 10),
                            _TermRow(
                              label: t('gold'),
                              value: cfg.dictionary.currencyName,
                            ),
                            const SizedBox(height: 10),
                            _TermRow(
                              label: t('skills'),
                              value: cfg.dictionary.skillsName,
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: isActive
                                  ? null
                                  : () async {
                                      await ref
                                          .read(activeSystemIdProvider.notifier)
                                          .setSystem(id);
                                      await DatabaseService
                                          .setSystemSelectionShown(true);
                                      if (widget.isFirstRun) {
                                        await DatabaseService.setOnboardingStep(
                                          OnboardingStep.needMasterEncounter,
                                        );
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${t('system_philosophy')}: ${t(_nameKey(id))}',
                                            ),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                        final onClose = widget.onClose;
                                        if (onClose != null) {
                                          onClose();
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                              child: Text(
                                isActive ? t('active') : t('apply'),
                              ),
                            ),
                            if (id == SystemId.custom) ...[
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CustomSystemBuilderPage(
                                        philosophyPickerIsFirstRun:
                                            widget.isFirstRun,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(t('custom_configure')),
                              ),
                              if (!widget.isFirstRun)
                                _LaboratoryLockedHint(translate: t),
                            ],
                            if (widget.isFirstRun) ...[
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () {
                                  _showLoreDialog(
                                    context,
                                    t,
                                    id,
                                  );
                                },
                                child: Text(t('read_lore')),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () async {
                                  await DatabaseService.setSystemSelectionShown(true);
                                  await DatabaseService.setOnboardingStep(
                                    OnboardingStep.needMasterEncounter,
                                  );
                                  if (!context.mounted) return;
                                  final onClose = widget.onClose;
                                  if (onClose != null) {
                                    onClose();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Text(t('skip')),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Text(
                  t('system_selection_hint'),
                  style: GoogleFonts.manrope(
                    color: scheme.outline,
                    fontSize: 12,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Подсказка под кнопкой кастом-мира: условия Лаборатории (не онбординг).
class _LaboratoryLockedHint extends ConsumerWidget {
  const _LaboratoryLockedHint({required this.translate});

  final String Function(String key, {Map<String, String>? params}) translate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunter = ref.watch(hunterProvider);
    final completed = ref.watch(completedQuestsProvider);
    final gate10 =
        completed.any((q) => q.tags.contains('story_gate_10'));
    final open = ProgressionGates.canOpenLaboratory(
      hunterLevel: hunter?.level ?? 0,
      philosophyPickerIsFirstRun: false,
      completedStoryGate10: gate10,
    );
    if (open) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        translate(
          'laboratory_locked_hint',
          params: {'level': '${ProgressionGates.laboratoryMinLevel}'},
        ),
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 11,
          height: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

