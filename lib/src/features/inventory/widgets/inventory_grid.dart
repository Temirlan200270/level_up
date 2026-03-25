import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/translations.dart';

import '../../../services/providers.dart';
import 'item_slot_card.dart';

class InventoryGrid extends ConsumerWidget {
  const InventoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final inventory = ref.watch(hunterProvider.select((h) => h?.inventory));

    if (inventory == null || inventory.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(t('inventory_empty')),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100.0,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final slot = inventory[index];
          return ItemSlotCard(slot: slot);
        },
        childCount: inventory.length,
      ),
    );
  }
}
