import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';

import 'widgets/equipment_panel.dart';
import 'widgets/gold_display.dart';
import 'widgets/inventory_grid.dart';
import '../../services/providers.dart';
import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../quests/quests_page.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final hunter = ref.watch(hunterProvider);
    final level = hunter?.level ?? 0;
    const unlockLevel = 5;

    if (hunter == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t('inventory')),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: Text('')),
      );
    }

    if (level < unlockLevel) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ProfileBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('inventory'),
                    style: promoAppBarTitleStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ProfileNeonCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              color: SoloLevelingColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t('inventory_locked_title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: SoloLevelingColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t(
                            'inventory_locked_body',
                            params: {'level': unlockLevel.toString()},
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: SoloLevelingColors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 240,
                          child: CustomScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            slivers: const [
                              SliverPadding(
                                padding: EdgeInsets.all(8),
                                sliver: InventoryGrid(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const QuestsPage(),
                              ),
                            );
                          },
                          child: Text(t('inventory_locked_cta')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('inventory')),
        backgroundColor: Colors.transparent,
      ),
      body: const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: EquipmentPanel()),
          SliverToBoxAdapter(child: GoldDisplay()),
          SliverPadding(padding: EdgeInsets.all(8.0), sliver: InventoryGrid()),
        ],
      ),
    );
  }
}
