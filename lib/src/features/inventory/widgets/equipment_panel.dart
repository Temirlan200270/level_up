import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/translations.dart';

import '../../../models/item_model.dart';
import '../../../services/providers.dart';

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
          _buildEquipmentSlot(context, equipment?['accessory'], t('accessory'), t),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlot(BuildContext context, Item? item, String placeholder, String Function(String) t) {
    return GestureDetector(
      onTap: () {
        // TODO: Показать детали предмета или список для экипировки
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Center(
          child: item != null
              ? Image.asset(item.iconPath) // TODO: Заменить на реальную иконку
              : Text(
                  placeholder,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
        ),
      ),
    );
  }
}
