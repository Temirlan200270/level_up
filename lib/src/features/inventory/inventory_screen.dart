import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';

import 'widgets/equipment_panel.dart';
import 'widgets/gold_display.dart';
import 'widgets/inventory_grid.dart';
import '../../services/providers.dart';
import '../../core/promo_ui.dart';
import '../../core/progression_gates.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../quests/quests_page.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final hunter = ref.watch(hunterProvider);
    final level = hunter?.level ?? 0;
    final unlockLevel = ProgressionGates.inventoryMinLevel;

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
      final scheme = Theme.of(context).colorScheme;
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
                            Icon(
                              Icons.lock_rounded,
                              color: scheme.tertiary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t('inventory_locked_title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: scheme.onSurface,
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
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 200,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.45),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 52,
                                color: scheme.outline.withValues(alpha: 0.55),
                              ),
                            ),
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

    final visuals = context.systemVisuals;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(t('inventory')),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: WorldSurfacePanel(
          visuals: visuals,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: const CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: EquipmentPanel()),
              SliverToBoxAdapter(child: GoldDisplay()),
              SliverPadding(
                padding: EdgeInsets.all(8.0),
                sliver: InventoryGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
