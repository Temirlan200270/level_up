import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/translations.dart';
import '../../../core/item_rarity_style.dart';
import '../../../core/system_visuals_extension.dart';

import '../../../models/item_model.dart';
import '../../../models/hunter_model.dart';
import '../../../services/providers.dart';
import 'item_detail_popup.dart';

class EquipmentPanel extends ConsumerWidget {
  const EquipmentPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final equipment = ref.watch(hunterProvider.select((h) => h?.equipment));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEquipmentSlot(context, equipment?['weapon'], t('weapon'), t),
          _buildEquipmentSlot(context, equipment?['armor'], t('armor'), t),
          _buildEquipmentSlot(
            context,
            equipment?['accessory'],
            t('accessory'),
            t,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlot(
    BuildContext context,
    Item? item,
    String placeholder,
    String Function(String) t,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final r = context.worldCardRadius;
    final borderColor = item != null
        ? ItemRarityStyle.color(
            item.rarity,
            theme: Theme.of(context),
          )
        : scheme.outline.withValues(alpha: 0.42);
    final glow = item != null
        ? ItemRarityStyle.glow(
            item.rarity,
            theme: Theme.of(context),
          )
        : <BoxShadow>[];

    return GestureDetector(
      onTap: item != null
          ? () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => ItemDetailPopup(
                  slot: InventorySlot(item: item, quantity: 1),
                ),
              );
            }
          : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: glow,
        ),
        child: Center(
          child: item != null
              ? Icon(Icons.inventory_2, color: borderColor, size: 36)
              : Text(
                  placeholder,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
