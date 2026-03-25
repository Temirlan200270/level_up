import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';

import 'widgets/equipment_panel.dart';
import 'widgets/gold_display.dart';
import 'widgets/inventory_grid.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
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
