import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/hunter_model.dart';
import '../../services/providers.dart';
import '../../services/database_service.dart';
import '../../models/ai_provider_model.dart';
import '../system/system_chat_page.dart';
import 'account_page.dart';
import 'cloud_sync_page.dart';
import '../../core/systems/system_id.dart';
import '../system/system_selection_screen.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsMetaRefreshProvider);
    final hunter = ref.watch(hunterProvider);
    final language = ref.watch(languageProvider);
    final systemId = ref.watch(activeSystemIdProvider);
    final t = useTranslations(ref);

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
                  t('settings'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hunter != null) ...[
                        profileSectionTitle(context, t('hunter_profile')),
                        const SizedBox(height: 10),
                        ProfileNeonCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              PromoSettingsTile(
                                icon: Icons.person_rounded,
                                title: t('hunter_name'),
                                subtitle: hunter.name,
                                onTap: () => _showChangeNameDialog(
                                  context,
                                  ref,
                                  hunter.name,
                                  t,
                                ),
                              ),
                              const PromoDivider(),
                              PromoSettingsTile(
                                icon: Icons.refresh_rounded,
                                title: t('reset_progress'),
                                iconColor: SoloLevelingColors.warning,
                                titleColor: SoloLevelingColors.warning,
                                onTap: () =>
                                    _showResetProgressDialog(context, ref, t),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      profileSectionTitle(context, t('account_title')),
                      const SizedBox(height: 10),
                      ProfileNeonCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            PromoSettingsTile(
                              icon: Icons.person_outline_rounded,
                              title: t('account_title'),
                              subtitle: t('account_subtitle'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AccountPage(),
                                  ),
                                );
                              },
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.auto_awesome_rounded,
                              title: t('system_philosophy'),
                              subtitle: t(_systemIdKey(systemId)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SystemSelectionScreen(),
                                  ),
                                );
                              },
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.cloud_outlined,
                              title: t('cloud_sync_title'),
                              subtitle: t('cloud_sync_subtitle'),
                              iconColor: SoloLevelingColors.textSecondary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const CloudSyncPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      profileSectionTitle(context, t('general')),
                      const SizedBox(height: 10),
                      ProfileNeonCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            PromoSettingsTile(
                              icon: Icons.language_rounded,
                              title: t('language'),
                              subtitle: _getLanguageName(language, t),
                              onTap: () => _showLanguagePicker(
                                context,
                                ref,
                                language,
                                t,
                              ),
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.smart_toy_outlined,
                              title: t('system'),
                              subtitle: t('ai_chat'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SystemChatPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      profileSectionTitle(context, t('customization_section')),
                      const SizedBox(height: 10),
                      ProfileNeonCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            PromoSettingsTile(
                              icon: Icons.palette_outlined,
                              title: t('theme_skin'),
                              subtitle: t(
                                'theme_skin_${ref.watch(themeSkinIdProvider)}',
                              ),
                              onTap: () =>
                                  _showThemeSkinDialog(context, ref, t),
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.label_outline_rounded,
                              title: t('stat_labels_custom'),
                              subtitle: t('stat_labels_custom_hint'),
                              onTap: () =>
                                  _showStatLabelsDialog(context, ref, t),
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.upload_file_rounded,
                              title: t('export_backup'),
                              onTap: () => _showExportBackupDialog(context, t),
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.download_rounded,
                              title: t('import_backup'),
                              onTap: () =>
                                  _showImportBackupDialog(context, ref, t),
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.local_offer_outlined,
                              title: t('tag_stats_title'),
                              subtitle: t('tag_stats_subtitle'),
                              onTap: () => _showTagStatsDialog(context, t),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      profileSectionTitle(context, t('ai_settings')),
                      const SizedBox(height: 10),
                      const _AiSettingsCard(),
                      const SizedBox(height: 28),
                      if (hunter != null) ...[
                        profileSectionTitle(context, t('statistics')),
                        const SizedBox(height: 10),
                        _buildHunterStatisticsCard(context, ref, hunter),
                        const SizedBox(height: 28),
                      ] else ...[
                        profileSectionTitle(context, t('statistics')),
                        const SizedBox(height: 10),
                        ProfileNeonCard(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_off_rounded,
                                size: 56,
                                color: SoloLevelingColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t('hunter_not_created'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: SoloLevelingColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('create_hunter_in_profile'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: SoloLevelingColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      profileSectionTitle(context, t('about')),
                      const SizedBox(height: 10),
                      ProfileNeonCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            PromoSettingsTile(
                              icon: Icons.info_outline_rounded,
                              title: t('version'),
                              subtitle: '1.0.0',
                              showChevron: false,
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.code_rounded,
                              title: t('developed_with'),
                              subtitle: 'Flutter ${_getFlutterVersion()}',
                              showChevron: false,
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
      ),
    );
  }

  String _systemIdKey(SystemId id) {
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

  // quick-pick bottomsheet intentionally removed (replaced by carousel screen)

  // Карточка статистики охотника
  Widget _buildHunterStatisticsCard(
    BuildContext context,
    WidgetRef ref,
    Hunter hunter,
  ) {
    final t = useTranslations(ref);
    final dict = ref.watch(activeSystemProvider).dictionary;
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedQuests = ref.watch(completedQuestsProvider);

    return ProfileNeonCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                dict.levelName,
                '${hunter.level}',
                Icons.star,
                SoloLevelingColors.neonBlue,
              ),
              _buildStatItem(
                context,
                dict.experienceName,
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
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        ProfileGradientText(
          text: value,
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SoloLevelingColors.textSecondary,
          ),
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
            labelStyle: const TextStyle(
              color: SoloLevelingColors.textSecondary,
            ),
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
                  await ref
                      .read(hunterProvider.notifier)
                      .updateHunter(
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
  void _showResetProgressDialog(
    BuildContext context,
    WidgetRef ref,
    String Function(String) t,
  ) {
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
                currentLanguage == 'ru'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
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
                currentLanguage == 'en'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
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

  void _showTagStatsDialog(BuildContext context, String Function(String) t) {
    final raw = DatabaseService.getTagCounts();
    final entries = raw.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('tag_stats_title'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: entries.isEmpty
              ? Text(
                  t('tag_stats_empty'),
                  style: const TextStyle(
                    color: SoloLevelingColors.textSecondary,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                color: SoloLevelingColors.neonBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }

  void _showThemeSkinDialog(
    BuildContext context,
    WidgetRef ref,
    String Function(String) t,
  ) {
    var selected = ref.read(themeSkinIdProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: SoloLevelingColors.surface,
            title: Text(
              t('theme_skin'),
              style: const TextStyle(color: SoloLevelingColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['solo', 'cultivation', 'archmage'].map((id) {
                final isOn = id == selected;
                return ListTile(
                  leading: Icon(
                    isOn ? Icons.check_circle : Icons.circle_outlined,
                    color: isOn
                        ? SoloLevelingColors.neonBlue
                        : SoloLevelingColors.textTertiary,
                  ),
                  title: Text(
                    t('theme_skin_$id'),
                    style: const TextStyle(
                      color: SoloLevelingColors.textPrimary,
                    ),
                  ),
                  onTap: () async {
                    setLocal(() => selected = id);
                    await ref.read(themeSkinIdProvider.notifier).setSkin(id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showStatLabelsDialog(
    BuildContext context,
    WidgetRef ref,
    String Function(String) t,
  ) {
    final o = DatabaseService.getStatLabelOverrides();
    final cStrength = TextEditingController(text: o['strength'] ?? '');
    final cAgility = TextEditingController(text: o['agility'] ?? '');
    final cInt = TextEditingController(text: o['intelligence'] ?? '');
    final cVit = TextEditingController(text: o['vitality'] ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('stat_labels_custom'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cStrength,
                style: const TextStyle(color: SoloLevelingColors.textPrimary),
                decoration: InputDecoration(
                  labelText: '${t('strength')} →',
                  labelStyle: const TextStyle(
                    color: SoloLevelingColors.textSecondary,
                  ),
                ),
              ),
              TextField(
                controller: cAgility,
                style: const TextStyle(color: SoloLevelingColors.textPrimary),
                decoration: InputDecoration(
                  labelText: '${t('agility')} →',
                  labelStyle: const TextStyle(
                    color: SoloLevelingColors.textSecondary,
                  ),
                ),
              ),
              TextField(
                controller: cInt,
                style: const TextStyle(color: SoloLevelingColors.textPrimary),
                decoration: InputDecoration(
                  labelText: '${t('intelligence')} →',
                  labelStyle: const TextStyle(
                    color: SoloLevelingColors.textSecondary,
                  ),
                ),
              ),
              TextField(
                controller: cVit,
                style: const TextStyle(color: SoloLevelingColors.textPrimary),
                decoration: InputDecoration(
                  labelText: '${t('vitality')} →',
                  labelStyle: const TextStyle(
                    color: SoloLevelingColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final m = <String, String>{};
              void put(String key, String v) {
                final s = v.trim();
                if (s.isNotEmpty) m[key] = s;
              }

              put('strength', cStrength.text);
              put('agility', cAgility.text);
              put('intelligence', cInt.text);
              put('vitality', cVit.text);
              await DatabaseService.setStatLabelOverrides(m);
              ref.read(settingsMetaRefreshProvider.notifier).state++;
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(t('save')),
          ),
        ],
      ),
    ).then((_) {
      cStrength.dispose();
      cAgility.dispose();
      cInt.dispose();
      cVit.dispose();
    });
  }

  void _showExportBackupDialog(
    BuildContext context,
    String Function(String) t,
  ) {
    final jsonStr = DatabaseService.exportGameBackupJson();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('export_backup'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(
                color: SoloLevelingColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('close')),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonStr));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t('backup_copied'))));
              }
            },
            child: Text(t('copy')),
          ),
        ],
      ),
    );
  }

  void _showImportBackupDialog(
    BuildContext context,
    WidgetRef ref,
    String Function(String) t,
  ) {
    final c = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('import_backup'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: TextField(
          controller: c,
          maxLines: 8,
          style: const TextStyle(
            color: SoloLevelingColors.textPrimary,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: t('paste_backup_json'),
            hintStyle: const TextStyle(color: SoloLevelingColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseService.importGameBackupJson(c.text);
                ref.read(hunterProvider.notifier).refresh();
                ref.read(questsProvider.notifier).refresh();
                ref.read(themeSkinIdProvider.notifier).reloadFromDb();
                ref.read(settingsMetaRefreshProvider.notifier).state++;
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(t('import_done'))));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${t('error')}: $e'),
                      backgroundColor: SoloLevelingColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(t('import_action')),
          ),
        ],
      ),
    ).then((_) {
      c.dispose();
    });
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

    return ProfileNeonCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('ai_provider').toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: SoloLevelingColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AIProvider.values.map((provider) {
              final isSelected = provider == currentProvider;
              return FilterChip(
                selected: isSelected,
                label: Text(
                  AIModels.getProviderName(provider),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onSelected: (selected) async {
                  if (selected) {
                    await ref
                        .read(aiProviderProvider.notifier)
                        .setProvider(provider);
                    ref.read(aiModelProvider.notifier).refresh();
                    ref.read(aiApiKeyProvider(provider).notifier).refresh();
                  }
                },
                selectedColor: SoloLevelingColors.neonBlue.withValues(
                  alpha: 0.3,
                ),
                checkmarkColor: SoloLevelingColors.neonBlue,
                side: BorderSide(
                  color: isSelected
                      ? SoloLevelingColors.neonBlue
                      : SoloLevelingColors.textTertiary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Text(
            t('model').toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: SoloLevelingColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _modelCtrl,
            focusNode: _modelFocus,
            style: GoogleFonts.manrope(
              color: SoloLevelingColors.textPrimary,
              fontSize: 15,
            ),
            decoration: promoInputDecoration(
              hintText: t('enter_model_name'),
              borderAccent: SoloLevelingColors.neonBlue,
              suffixIcon: models.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (model) async {
                        _modelCtrl?.text = model;
                        await ref
                            .read(aiModelProvider.notifier)
                            .setModel(model);
                      },
                      itemBuilder: (context) => models.map((model) {
                        return PopupMenuItem(value: model, child: Text(model));
                      }).toList(),
                    )
                  : null,
            ),
            onChanged: (value) {
              _modelDebounce?.cancel();
              _modelDebounce = Timer(
                const Duration(milliseconds: 500),
                () async {
                  if (!mounted) return;
                  if (_modelCtrl?.text == value) {
                    await ref.read(aiModelProvider.notifier).setModel(value);
                  }
                },
              );
            },
          ),
          if (models.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              t('or_select_from_list'),
              style: GoogleFonts.manrope(
                fontSize: 12,
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
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
          const SizedBox(height: 22),
          Text(
            t('api_key').toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: SoloLevelingColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                hasKey ? Icons.key_rounded : Icons.key_off_rounded,
                color: hasKey
                    ? SoloLevelingColors.neonGreen
                    : SoloLevelingColors.warning,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${AIModels.getProviderName(currentProvider)} · ${t('api_key')}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasKey
                        ? SoloLevelingColors.neonGreen
                        : SoloLevelingColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _keyCtrl,
            focusNode: _keyFocus,
            style: GoogleFonts.manrope(
              color: SoloLevelingColors.textPrimary,
              fontSize: 15,
            ),
            decoration: promoInputDecoration(
              hintText: _apiKeyHint(currentProvider),
              borderAccent: hasKey
                  ? SoloLevelingColors.neonGreen
                  : SoloLevelingColors.neonBlue,
              suffixIcon: currentKey.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _keyCtrl?.clear();
                        ref
                            .read(aiApiKeyProvider(currentProvider).notifier)
                            .setKey('');
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
                  await ref
                      .read(aiApiKeyProvider(currentProvider).notifier)
                      .setKey(value);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
