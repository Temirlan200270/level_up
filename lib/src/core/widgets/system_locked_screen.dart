import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../promo_ui.dart';
import '../systems/system_id.dart';
import '../systems/system_rules.dart';
import '../theme.dart';
import '../../services/providers.dart';

/// Вариант оформления «запертого» контента под активную философию (Solo / Mage / Cultivator).
enum _LockSkin { solo, mage, cultivator }

_LockSkin _resolveLockSkin(SystemId id, SystemRules rules) {
  if (id == SystemId.custom) {
    final base = rules is CustomRules ? rules.base : rules;
    if (base is MageRules) return _LockSkin.mage;
    if (base is CultivatorRules) return _LockSkin.cultivator;
    return _LockSkin.solo;
  }
  return switch (id) {
    SystemId.solo => _LockSkin.solo,
    SystemId.mage => _LockSkin.mage,
    SystemId.cultivator => _LockSkin.cultivator,
    SystemId.custom => _LockSkin.solo,
  };
}

/// Экран-заглушка: раздел открывается с вкладки, но контент скрыт до нужного уровня.
/// Текст и визуал зависят от [activeSystemIdProvider] / [activeSystemRulesProvider].
class SystemLockedScreen extends ConsumerStatefulWidget {
  const SystemLockedScreen({
    super.key,
    required this.title,
    required this.requiredLevel,
    required this.currentLevel,
    this.rewardPreview,
  });

  /// Заголовок в AppBar (имя раздела в терминологии текущей системы).
  final String title;

  final int requiredLevel;
  final int currentLevel;

  /// Короткая интрига: что откроется после разблокировки (Curiosity Gap).
  final String? rewardPreview;

  @override
  ConsumerState<SystemLockedScreen> createState() => _SystemLockedScreenState();
}

class _SystemLockedScreenState extends ConsumerState<SystemLockedScreen> {
  int _interactionTick = 0;
  int _rippleTick = 0;

  void _onLockedTap(_LockSkin skin) {
    HapticFeedback.mediumImpact();
    setState(() {
      _interactionTick++;
      if (skin == _LockSkin.mage) _rippleTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemId = ref.watch(activeSystemIdProvider);
    final rules = ref.watch(activeSystemRulesProvider);
    final skin = _resolveLockSkin(systemId, rules);
    final scheme = Theme.of(context).colorScheme;

    final accent = switch (skin) {
      _LockSkin.solo => scheme.error,
      _LockSkin.mage => scheme.secondary,
      _LockSkin.cultivator => SoloLevelingColors.legendaryOrange,
    };

    final title = widget.title;
    final need = widget.requiredLevel;

    final headline = switch (skin) {
      _LockSkin.solo => 'ДОСТУП ЗАКРЫТ',
      _LockSkin.mage => '$title запечатан до достижения уровня $need.',
      _LockSkin.cultivator => '«$title» под небесной печатью',
    };

    final body = switch (skin) {
      _LockSkin.solo =>
        '«$title».\nТребования Системы не выполнены.\nНеобходим уровень $need.',
      _LockSkin.mage =>
        'Ваша искра пока не держит эту нить силы.\nУкрепите круг — запись откроется, когда уровень сравняется с требованием.',
      _LockSkin.cultivator =>
        'Сосуд не готов вместить эти знания.\nПечать сорвётся на $need ступени.',
    };

    final defaultTeaser = switch (skin) {
      _LockSkin.solo =>
        'За шифрованием — инструменты охотника следующего ранга: слоты, обмен и ускорение прогресса.',
      _LockSkin.mage =>
        'За барьером — ритуальные ячейки, артефакты и записи, которых нет в базовом гримуаре.',
      _LockSkin.cultivator =>
        'За туманом — техники, небесная карта и артефакты; печать снимается лишь с окрепшим сосудом.',
    };

    final teaser = widget.rewardPreview ?? defaultTeaser;

    final iconData = switch (skin) {
      _LockSkin.solo => Icons.lock_rounded,
      _LockSkin.mage => Icons.auto_fix_high_rounded,
      _LockSkin.cultivator => Icons.workspace_premium_rounded,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  widget.title,
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onLockedTap(skin),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ProfileNeonCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LockIconBlock(
                              skin: skin,
                              accent: accent,
                              iconData: iconData,
                              interactionTick: _interactionTick,
                              rippleTick: _rippleTick,
                            ),
                            const SizedBox(height: 22),
                            Text(
                              headline,
                              style: GoogleFonts.manrope(
                                color: accent,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: skin == _LockSkin.solo ? 1.2 : 0.6,
                                shadows: [
                                  Shadow(
                                    color: accent.withValues(alpha: 0.55),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              body,
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textSecondary,
                                height: 1.45,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Сейчас: ${widget.currentLevel} · цель: ${widget.requiredLevel}',
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: accent.withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  teaser,
                                  style: GoogleFonts.manrope(
                                    color: SoloLevelingColors.textPrimary
                                        .withValues(alpha: 0.88),
                                    height: 1.5,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              switch (skin) {
                                _LockSkin.solo =>
                                  'Нажмите на экран — ответ Системы',
                                _LockSkin.mage =>
                                  'Нажмите на экран — пульс Кодекса',
                                _LockSkin.cultivator =>
                                  'Нажмите на экран — отклик Дао',
                              },
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textTertiary,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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

class _LockIconBlock extends StatelessWidget {
  const _LockIconBlock({
    required this.skin,
    required this.accent,
    required this.iconData,
    required this.interactionTick,
    required this.rippleTick,
  });

  final _LockSkin skin;
  final Color accent;
  final IconData iconData;
  final int interactionTick;
  final int rippleTick;

  @override
  Widget build(BuildContext context) {
    final soloChains = skin == _LockSkin.solo;
    final mageBarrier = skin == _LockSkin.mage;
    final cultMist = skin == _LockSkin.cultivator;

    Widget core = Icon(
      iconData,
      size: 72,
      color: accent,
    );

    // Пульс «дыхания»
    core = core
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.92,
          end: 1.06,
          duration: 2200.ms,
          curve: Curves.easeInOut,
        );

    if (soloChains) {
      core = Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.link_rounded,
            size: 96,
            color: accent.withValues(alpha: 0.22),
          ),
          core,
        ],
      );
    }

    if (cultMist) {
      core = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _MistHalo(color: accent),
          core,
        ],
      );
    }

    if (mageBarrier) {
      core = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _RuneRing(color: accent),
          if (rippleTick > 0)
            KeyedSubtree(
              key: ValueKey<int>(rippleTick),
              child: _MageRippleBurst(color: accent),
            ),
          core,
        ],
      );
    }

    // Тряска / глитч / отталкивание по тапу (через смену ключа)
    final effects = <Effect<dynamic>>[
      ShakeEffect(
        duration: 480.ms,
        hz: skin == _LockSkin.solo ? 7 : 5,
        offset: skin == _LockSkin.solo ? const Offset(7, 0) : const Offset(0, 6),
        rotation: skin == _LockSkin.cultivator ? math.pi / 28 : math.pi / 40,
      ),
    ];

    if (skin == _LockSkin.solo) {
      effects.add(
        TintEffect(
          duration: 280.ms,
          color: Colors.redAccent,
          begin: 0,
          end: 0.45,
          curve: Curves.easeOut,
        ),
      );
      effects.add(
        SlideEffect(
          duration: 120.ms,
          begin: const Offset(0.012, 0),
          end: Offset.zero,
          curve: Curves.linear,
        ),
      );
    } else if (skin == _LockSkin.mage) {
      effects.add(
        TintEffect(
          duration: 320.ms,
          color: accent,
          begin: 0,
          end: 0.35,
          curve: Curves.easeOut,
        ),
      );
    } else {
      effects.add(
        TintEffect(
          duration: 400.ms,
          color: const Color(0xFFFFE082),
          begin: 0,
          end: 0.38,
          curve: Curves.easeOut,
        ),
      );
    }

    if (interactionTick > 0) {
      core = Animate(
        key: ValueKey<int>(interactionTick),
        effects: effects,
        child: core,
      );
    }

    return Center(child: core);
  }
}

/// Лёгкое «облако» за печатью культиватора.
class _MistHalo extends StatelessWidget {
  const _MistHalo({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1.08, 1.08),
                duration: 3.2.seconds,
                curve: Curves.easeInOut,
              ),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.35),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuneRing extends StatelessWidget {
  const _RuneRing({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: 1.6,
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(
            begin: -0.04,
            end: 0.04,
            duration: 2.4.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}

/// Короткий «рывок» барьера при тапе (маг).
class _MageRippleBurst extends StatelessWidget {
  const _MageRippleBurst({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.0)),
          ),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.65, 0.65),
            end: const Offset(1.35, 1.35),
            duration: 520.ms,
            curve: Curves.easeOut,
          )
          .fadeOut(duration: 520.ms, curve: Curves.easeOut)
          .tint(
            color: color,
            begin: 0.55,
            end: 0.0,
            duration: 520.ms,
          ),
    );
  }
}
