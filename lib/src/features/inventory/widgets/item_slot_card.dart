import 'package:flutter/material.dart';
import '../../../models/hunter_model.dart';
import '../../../core/item_rarity_style.dart';
import '../../../core/system_visuals_extension.dart';
import 'item_detail_popup.dart';

class ItemSlotCard extends StatelessWidget {
  final InventorySlot slot;

  const ItemSlotCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final rc = ItemRarityStyle.color(
      slot.item.rarity,
      theme: Theme.of(context),
    );
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => ItemDetailPopup(slot: slot),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.worldCardRadius),
          border: Border.all(color: rc, width: 2),
          boxShadow: ItemRarityStyle.glow(
            slot.item.rarity,
            theme: Theme.of(context),
          ),
        ),
        child: Stack(
          children: [
            Center(child: Icon(Icons.inventory_2, color: rc, size: 40)),
            if (slot.quantity > 1)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  'x${slot.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
