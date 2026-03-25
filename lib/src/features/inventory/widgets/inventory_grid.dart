import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import 'item_slot_card.dart';

class InventoryGrid extends ConsumerWidget {
  const InventoryGrid({super.key});

  static const int _placeholderSlots = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(hunterProvider.select((h) => h?.inventory));
    final scheme = Theme.of(context).colorScheme;

    final items = inventory ?? const [];
    final total = items.isEmpty ? _placeholderSlots : items.length;

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100.0,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if (index < items.length) {
          final slot = items[index];
          return ItemSlotCard(slot: slot);
        }
        return _EmptySlotCard(
          border: scheme.secondary.withValues(alpha: 0.20),
          icon: scheme.onSurface.withValues(alpha: 0.22),
        );
      }, childCount: total),
    );
  }
}

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard({required this.border, required this.icon});
  final Color border;
  final Color icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.20),
      ),
      child: Center(
        child: Icon(Icons.inventory_2_outlined, color: icon, size: 34),
      ),
    );
  }
}
