import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/hunter_display.dart';
import '../../core/monarch_mode.dart';
import '../../models/hunter_model.dart';
import '../../models/achievement_model.dart';
import '../../core/systems/system_dictionary.dart';
import '../../services/providers.dart';
import '../../services/database_service.dart';
import '../shop/shop_screen.dart';
import 'widgets/profile_analytics_section.dart';
import '../../core/promo_ui.dart';

/// Локализованные строки с опциональными подстановками `{key}`.
typedef AppTr = String Function(String key, {Map<String, String>? params});

class HunterProfilePage extends ConsumerStatefulWidget {
  const HunterProfilePage({super.key});

  @override
  ConsumerState<HunterProfilePage> createState() => _HunterProfilePageState();
}

class _HunterProfilePageState extends ConsumerState<HunterProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  // Кинематографичный онбординг (Фаза 7.5) запускается глобально из `HomeShell`.

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hunter = ref.watch(hunterProvider);
    ref.watch(worldEventTickProvider);
    final t = useTranslations(ref);
    final dict = ref.watch(activeSystemProvider).dictionary;

    // Если охотника нет, показываем экран создания
    if (hunter == null) {
      return _buildCreateHunterScreen(context, ref);
    }

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
                  t('hunter_profile'),
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SoloLevelingColors.textPrimary,
                  ),
                ),
                centerTitle: true,
                actions: [
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
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLevelCard(context, hunter, t, dict),
                      if (hunter.activeBuffs.any(
                        (b) => b.effectId == 'penalty_zone' && !b.isExpired,
                      )) ...[
                        const SizedBox(height: 12),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.gpp_maybe_rounded,
                                color: SoloLevelingColors.error,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('penalty_zone_active_banner'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: SoloLevelingColors.error,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (DatabaseService.isBloodMoonActive) ...[
                        const SizedBox(height: 12),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                color: SoloLevelingColors.error
                                    .withValues(alpha: 0.95),
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('blood_moon_active_banner'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: SoloLevelingColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (MonarchMode.isUnlocked(hunter.level) &&
                          DatabaseService.isStoryGateCompleted(50)) ...[
                        const SizedBox(height: 12),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.whatshot_rounded,
                                color: SoloLevelingColors.neonPurple
                                    .withValues(alpha: 0.95),
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('monarch_mode_active_banner'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: SoloLevelingColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _buildStatsSectionHeader(context, hunter, t),
                      const SizedBox(height: 10),
                      _buildStatsPanel(context, hunter, t),
                      const SizedBox(height: 28),
                      ProfileAnalyticsSection(hunter: hunter),
                      const SizedBox(height: 28),
                      _buildAchievementsSection(context, ref, t),
                      const SizedBox(height: 28),
                      profileSectionTitle(context, t('info')),
                      const SizedBox(height: 10),
                      _buildInfoCard(context, hunter, t),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy: Awakening Scene dialog.
  // Фаза 7.5 заменила этот шаг на `OnboardingJourneyScreen`.

  // Экран создания охотника
  Widget _buildCreateHunterScreen(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: ProfileBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 28.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ProfilePillBadge(
                          label: t('profile_onboarding_badge'),
                        ),
                        const SizedBox(height: 28),
                        Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: SoloLevelingColors.neonBlue.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 28,
                                ),
                                BoxShadow(
                                  color: SoloLevelingColors.neonPurple
                                      .withValues(alpha: 0.25),
                                  blurRadius: 36,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: SoloLevelingColors.neonBlue,
                                  width: 2,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    SoloLevelingColors.neonPurple.withValues(
                                      alpha: 0.35,
                                    ),
                                    SoloLevelingColors.background,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                size: 44,
                                color: SoloLevelingColors.neonBlue,
                              ),
                            ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t('create_hunter'),
                          style: GoogleFonts.manrope(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: SoloLevelingColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t('enter_name'),
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: SoloLevelingColors.textSecondary,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(18),
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: SoloLevelingColors.surfaceLight
                                  .withValues(alpha: 0.5),
                              labelText: t('hunter_name'),
                              labelStyle: GoogleFonts.manrope(
                                color: SoloLevelingColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: SoloLevelingColors.neonBlue
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: SoloLevelingColors.neonBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: SoloLevelingColors.neonBlue.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: () async {
                                  if (_nameController.text.trim().isNotEmpty) {
                                    try {
                                      await ref
                                          .read(hunterProvider.notifier)
                                          .createHunter(
                                            _nameController.text.trim(),
                                          );
                                    } catch (e) {
                                      if (context.mounted) {
                                        final t = useTranslations(ref);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${t('hunter_creation_error')}: $e',
                                            ),
                                            backgroundColor:
                                                SoloLevelingColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      final t = useTranslations(ref);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(t('enter_hunter_name')),
                                          backgroundColor:
                                              SoloLevelingColors.warning,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              child: Text(t('start_journey').toUpperCase()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Подпись класса для интерфейса: скрытый класс или «нет».
  String _hunterClassLine(Hunter hunter, AppTr t) {
    final id = hunter.hiddenClassId;
    if (id == null || id.isEmpty) return t('hunter_class_none');
    if (id == 'coder') return t('hidden_class_coder');
    return id;
  }

  Widget _buildStatsSectionHeader(
    BuildContext context,
    Hunter hunter,
    AppTr t,
  ) {
    final ap = hunter.stats.availablePoints;
    final accent = SoloLevelingColors.warning;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: profileSectionTitle(context, t('stats'))),
        Text(
          '${t('stats_free_points_header')}: ',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: SoloLevelingColors.textSecondary,
          ),
        ),
        Text(
          '$ap',
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ap > 0 ? accent : SoloLevelingColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // Карточка уровня + прогресс опыта в одном блоке
  Widget _buildLevelCard(
    BuildContext context,
    Hunter hunter,
    AppTr t,
    SystemDictionary dict,
  ) {
    final rank = hunterRankCode(hunter.level);
    final titleKey = hunterTitleKeyForRank(rank);
    final monoNum = GoogleFonts.rajdhani(
      fontWeight: FontWeight.w800,
      color: SoloLevelingColors.textPrimary,
    );

    return ProfileNeonCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SoloLevelingColors.neonBlue.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: SoloLevelingColors.neonPurple.withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 26,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SoloLevelingColors.neonBlue,
                      width: 2,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        SoloLevelingColors.neonPurple.withValues(alpha: 0.4),
                        SoloLevelingColors.background,
                      ],
                    ),
                  ),
                  child: Center(
                    child: ProfileGradientText(
                      text: '${hunter.level}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hunter.name,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: SoloLevelingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t('hunter_rank_short')}: $rank',
                      style: monoNum.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('hunter_class_short')}: ${_hunterClassLine(hunter, t)}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SoloLevelingColors.neonBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('hunter_title_short')}: ${t(titleKey)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: SoloLevelingColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${dict.experienceName}: ${hunter.currentExp.toInt()} / ${hunter.experienceToNextLevel.toInt()}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: SoloLevelingColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${(hunter.levelProgress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: SoloLevelingColors.neonBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProfileGradientBar(value: hunter.levelProgress),
        ],
      ),
    );
  }

  String _statLabel(String key, AppTr t) {
    final o = DatabaseService.getStatLabelOverrides();
    final custom = o[key];
    if (custom != null && custom.isNotEmpty) return custom;
    return t(key);
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    WidgetRef ref,
    AppTr t,
  ) {
    final unlocked = ref.watch(unlockedAchievementIdsProvider).toSet();
    if (unlocked.isEmpty) return const SizedBox.shrink();

    final lang = ref.watch(languageProvider);
    final defs = kAllAchievements
        .where((a) => unlocked.contains(a.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        profileSectionTitle(context, t('achievements')),
        const SizedBox(height: 10),
        ProfileNeonCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...defs.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: SoloLevelingColors.neonPurple.withValues(
                            alpha: 0.15,
                          ),
                          border: Border.all(
                            color: SoloLevelingColors.neonBlue.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: SoloLevelingColors.neonBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == 'en' ? a.titleEn : a.titleRu,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: SoloLevelingColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang == 'en' ? a.descEn : a.descRu,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                height: 1.4,
                                color: SoloLevelingColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Панель статов
  Widget _buildStatsPanel(BuildContext context, Hunter hunter, AppTr t) {
    final d = hunter.displayStats;
    final b = hunter.stats;
    return ProfileNeonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatBar(
            context,
            _statLabel('strength', t),
            d.strength,
            b.strength,
            Icons.fitness_center,
            SoloLevelingColors.neonPink,
            'strength',
            hunter,
            t,
          ),
          const SizedBox(height: 12),
          _buildStatBar(
            context,
            _statLabel('agility', t),
            d.agility,
            b.agility,
            Icons.speed,
            SoloLevelingColors.neonGreen,
            'agility',
            hunter,
            t,
          ),
          const SizedBox(height: 12),
          _buildStatBar(
            context,
            _statLabel('intelligence', t),
            d.intelligence,
            b.intelligence,
            Icons.psychology,
            SoloLevelingColors.neonPurple,
            'intelligence',
            hunter,
            t,
          ),
          const SizedBox(height: 12),
          _buildStatBar(
            context,
            _statLabel('vitality', t),
            d.vitality,
            b.vitality,
            Icons.favorite,
            SoloLevelingColors.error,
            'vitality',
            hunter,
            t,
          ),
        ],
      ),
    );
  }

  // Строка характеристики: иконка, название, +, число (без мини-прогресс-бара)
  Widget _buildStatBar(
    BuildContext context,
    String label,
    int displayValue,
    int baseValue,
    IconData icon,
    Color color,
    String statName,
    Hunter hunter,
    AppTr t,
  ) {
    final hasAvailablePoints = hunter.stats.availablePoints > 0;
    final bonus = displayValue - baseValue;
    final valueStyle = GoogleFonts.rajdhani(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: SoloLevelingColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        hasAvailablePoints
                            ? Icons.add_circle
                            : Icons.add_circle_outline,
                        size: 24,
                        color: hasAvailablePoints
                            ? color
                            : color.withValues(alpha: 0.28),
                      ),
                      onPressed: hasAvailablePoints
                          ? () {
                              ref
                                  .read(hunterProvider.notifier)
                                  .allocateStatPoint(statName);
                            }
                          : null,
                      tooltip: hasAvailablePoints
                          ? t('add_point')
                          : t('no_points_available'),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '$displayValue',
                        textAlign: TextAlign.right,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
                if (bonus > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      t(
                        'equipment_stat_bonus',
                        params: {'n': bonus.toString()},
                      ),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: SoloLevelingColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Информационная карточка
  Widget _buildInfoCard(BuildContext context, Hunter hunter, AppTr t) {
    return ProfileNeonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            '${hunter.displayStats.total}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            t('daily_streak'),
            '${hunter.dailyQuestStreak}',
          ),
          if ((DatabaseService.getGuildName() ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              t('guild_name'),
              DatabaseService.getGuildName()!.trim(),
            ),
          ],
          if (hunter.hiddenClassId != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              t('hidden_class'),
              hunter.hiddenClassId == 'coder'
                  ? t('hidden_class_coder')
                  : hunter.hiddenClassId!,
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            t('record_level'),
            '${DatabaseService.getRecordBestLevel()}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            t('record_gold'),
            '${DatabaseService.getRecordBestGold()}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: SoloLevelingColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: SoloLevelingColors.neonBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
