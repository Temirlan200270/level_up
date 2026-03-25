import 'package:flutter/material.dart';
import '../../../models/hunter_model.dart';
import '../../../models/enums.dart';
import 'item_detail_popup.dart';

class ItemSlotCard extends StatelessWidget {
  final InventorySlot slot;

  const ItemSlotCard({super.key, required this.slot});

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey.shade400;
      case ItemRarity.rare:
        return Colors.blue.shade300;
      case ItemRarity.epic:
        return Colors.purple.shade300;
      case ItemRarity.legendary:
        return Colors.orange.shade400;
      case ItemRarity.mythic:
        return Colors.red.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getRarityColor(slot.item.rarity), width: 2),
        ),
        child: Stack(
          children: [
            Center(
              // TODO: Заменить на Image.asset(slot.item.iconPath)
              // когда появятся ассеты
              child: Icon(
                Icons.shield, // Заглушка
                color: _getRarityColor(slot.item.rarity),
                size: 40,
              ),
            ),
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
