import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/progression_gates.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../core/systems/system_id.dart';
import '../../services/database_service.dart';
import '../../services/providers.dart';
import '../social/hall_of_fame_screen.dart';
import '../social/leaderboards_screen.dart';

class GuildHubScreen extends ConsumerWidget {
  const GuildHubScreen({super.key});

  IconData _systemIcon(SystemId id) {
    return switch (id) {
      SystemId.solo => Icons.bolt_rounded,
      SystemId.mage => Icons.auto_awesome_rounded,
      SystemId.cultivator => Icons.spa_rounded,
      SystemId.custom => Icons.tune_rounded,
    };
  }

  Color _systemIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  Future<void> _showGuildNameDialog(
    BuildContext context,
    WidgetRef ref,
    String Function(String, {Map<String, String>? params}) t,
  ) async {
    final existingGuild = DatabaseService.getGuildName();
    final hunter = ref.read(hunterProvider);
    final level = hunter?.level ?? 0;

    if (hunter == null &&
        (existingGuild == null || existingGuild.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('guild_need_hunter'))),
      );
      return;
    }

    final canUseGuild =
        level >= ProgressionGates.guildMinLevel ||
        (existingGuild != null && existingGuild.trim().isNotEmpty);
    if (!canUseGuild) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'guild_locked_level',
              params: {'level': '${ProgressionGates.guildMinLevel}'},
            ),
          ),
        ),
      );
      return;
    }

    final c = TextEditingController(text: DatabaseService.getGuildName() ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          t('guild_name'),
          style: GoogleFonts.manrope(
            color: SoloLevelingColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: c,
          style: GoogleFonts.manrope(color: SoloLevelingColors.textPrimary),
          decoration: InputDecoration(
            hintText: t('guild_name_hint'),
            hintStyle: GoogleFonts.manrope(color: SoloLevelingColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              final name = c.text.trim();
              await DatabaseService.setGuildName(name.isEmpty ? null : name);
              ref.read(settingsMetaRefreshProvider.notifier).state++;
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
    c.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsMetaRefreshProvider);
    final t = useTranslations(ref);
    final hunter = ref.watch(hunterProvider);
    final systemId = ref.watch(activeSystemIdProvider);
    final guildName = (DatabaseService.getGuildName() ?? '').trim();

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
                  t('guild_hub_title'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: t('guild_hub_edit'),
                    onPressed: () => _showGuildNameDialog(context, ref, t),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileNeonCard(
                        padding: const EdgeInsets.all(16),
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
                                  child: Icon(
                                    Icons.groups_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    guildName.isEmpty ? t('guild_none') : guildName,
                                    style: GoogleFonts.manrope(
                                      color: SoloLevelingColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (guildName.isEmpty)
                                  OutlinedButton(
                                    onPressed: () => _showGuildNameDialog(context, ref, t),
                                    child: Text(t('guild_hub_create')),
                                  )
                                else
                                  ProfilePillBadge(label: t('active')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              t('guild_hub_subtitle'),
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textSecondary,
                                height: 1.35,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      profileSectionTitle(context, t('guild_hub_members')),
                      const SizedBox(height: 10),
                      ProfileNeonCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            PromoSettingsTile(
                              icon: _systemIcon(systemId),
                              iconColor: _systemIconColor(context),
                              title: hunter?.name ?? t('guild_hub_you'),
                              subtitle:
                                  '${t('guild_hub_your_system')} · ${t('system_${systemId.value}')}',
                              showChevron: false,
                              onTap: null,
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.emoji_events_outlined,
                              title: t('leaderboards_title'),
                              subtitle: t('leaderboards_subtitle'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LeaderboardsScreen(),
                                  ),
                                );
                              },
                            ),
                            const PromoDivider(),
                            PromoSettingsTile(
                              icon: Icons.search_rounded,
                              title: t('hall_of_fame_title'),
                              subtitle: t('hall_of_fame_subtitle'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const HallOfFameScreen(),
                                  ),
                                );
                              },
                            ),
                            const PromoDivider(),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                t('guild_hub_stub'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textTertiary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ProfileNeonCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t('guild_hub_next_title'),
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t('guild_hub_next_body'),
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textSecondary,
                                height: 1.35,
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
      ),
    );
  }
}

