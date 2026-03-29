import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../models/title_def.dart';
import '../../data/titles_data.dart';
import '../../services/providers.dart';

class TitlesPage extends ConsumerWidget {
  const TitlesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunter = ref.watch(hunterProvider);

    if (hunter == null) return const SizedBox.shrink();

    // Разделяем титулы на полученные и не полученные (но не скрытые)
    final unlocked = allTitles.where((title) => hunter.unlockedTitleIds.contains(title.id)).toList();
    final locked = allTitles.where((title) => !hunter.unlockedTitleIds.contains(title.id) && !title.isHidden).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Титулы и Достижения',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SoloLevelingColors.textPrimary,
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (unlocked.isNotEmpty) ...[
                        Text(
                          'Полученные титулы',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SoloLevelingColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...unlocked.map((title) => _TitleCard(
                              title: title,
                              isUnlocked: true,
                              isEquipped: hunter.equippedTitleId == title.id,
                              onEquip: () {
                                if (hunter.equippedTitleId == title.id) {
                                  ref.read(hunterProvider.notifier).equipTitle('');
                                } else {
                                  ref.read(hunterProvider.notifier).equipTitle(title.id);
                                }
                              },
                            )),
                        const SizedBox(height: 24),
                      ],
                      if (locked.isNotEmpty) ...[
                        Text(
                          'Неоткрытые титулы',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SoloLevelingColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...locked.map((title) => _TitleCard(
                              title: title,
                              isUnlocked: false,
                              isEquipped: false,
                            )),
                      ],
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

class _TitleCard extends StatelessWidget {
  final TitleDef title;
  final bool isUnlocked;
  final bool isEquipped;
  final VoidCallback? onEquip;

  const _TitleCard({
    required this.title,
    required this.isUnlocked,
    required this.isEquipped,
    this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    Color getRarityColor(String rarity) {
      switch (rarity) {
        case 'rare':
          return SoloLevelingColors.neonBlue;
        case 'epic':
          return SoloLevelingColors.neonPurple;
        case 'legendary':
          return SoloLevelingColors.warning;
        default:
          return Colors.grey.shade400;
      }
    }

    final rarityColor = getRarityColor(title.rarity);
    final opacity = isUnlocked ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ProfileNeonCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech, color: rarityColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUnlocked ? title.name : '???',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                  ),
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rarityColor),
                      ),
                      child: Text(
                        'Экипирован',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rarityColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (isUnlocked || !title.isHidden) ...[
                const SizedBox(height: 8),
                Text(
                  title.description,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: SoloLevelingColors.textPrimary,
                  ),
                ),
                if (title.effects.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: title.effects.entries.map((e) {
                      String effectText = '';
                      if (e.key == 'xp_bonus') {
                        effectText = '+${(e.value * 100).toInt()}% EXP';
                      } else if (e.key.startsWith('stat_')) {
                        final statName = e.key.replaceFirst('stat_', '');
                        effectText = '+$e.value $statName';
                      } else {
                        effectText = '${e.key}: ${e.value}';
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          effectText,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: SoloLevelingColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (isUnlocked) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onEquip,
                      style: TextButton.styleFrom(
                        foregroundColor: isEquipped ? SoloLevelingColors.textSecondary : SoloLevelingColors.neonBlue,
                      ),
                      child: Text(isEquipped ? 'Снять' : 'Экипировать'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
