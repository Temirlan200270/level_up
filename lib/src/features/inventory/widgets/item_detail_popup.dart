import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/enums.dart';
import '../../../models/hunter_model.dart';
import '../../../services/providers.dart';
import '../../../core/theme.dart';
import '../../../core/translations.dart';

/// Модальное окно с деталями предмета
class ItemDetailPopup extends ConsumerWidget {
  final InventorySlot slot;

  const ItemDetailPopup({super.key, required this.slot});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final item = slot.item;
    final rarityColor = _getRarityColor(item.rarity);
    final t = useTranslations(ref);

    return Container(
      decoration: BoxDecoration(
        color: SoloLevelingColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Заголовок с цветом редкости
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Иконка предмета
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: rarityColor, width: 2),
                  ),
                  child: Icon(
                    Icons.shield, // TODO: Заменить на Image.asset(item.iconPath)
                    color: rarityColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (slot.quantity > 1)
                        Text(
                          '${t('quantity')}: ${slot.quantity}',
                          style: TextStyle(
                            color: SoloLevelingColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Описание
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.description,
              style: TextStyle(
                color: SoloLevelingColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Эффекты/Статы
          if (item.effects != null && item.effects!.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t('effects')}:',
                    style: TextStyle(
                      color: SoloLevelingColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.effects!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: SoloLevelingColors.neonGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatEffect(entry.key, entry.value),
                            style: TextStyle(
                              color: SoloLevelingColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Кнопки действий
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Кнопка "Использовать" (для расходников)
                if (item.type == ItemType.consumable)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(hunterProvider.notifier).useItem(slot);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('item_used', params: {'name': item.name})),
                            backgroundColor: SoloLevelingColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(t('use')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoloLevelingColors.neonGreen,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),

                // Кнопка "Экипировать" (для экипировки)
                if (item.type == ItemType.equipment && item.slot != null) ...[
                  if (item.type == ItemType.consumable) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(hunterProvider.notifier).equipItem(item);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('item_equipped', params: {'name': item.name})),
                            backgroundColor: SoloLevelingColors.neonBlue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: Text(t('equip')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoloLevelingColors.neonBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],

                // Кнопка "Продать" (для материалов и лишних предметов)
                if (item.type == ItemType.material || item.type == ItemType.consumable) ...[
                  if (item.type == ItemType.equipment) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final sellPrice = item.effects?['sellPrice'] as int? ?? item.buyPrice ~/ 2;
                        final totalPrice = sellPrice * slot.quantity;
                        
                        // Используем атомарный метод продажи
                        await ref.read(hunterProvider.notifier).sellItem(
                          item.id,
                          slot.quantity,
                          sellPrice,
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('sold_for', params: {'amount': totalPrice.toString()})),
                              backgroundColor: SoloLevelingColors.warning,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.sell),
                      label: Text(t('sell')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoloLevelingColors.warning,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  String _formatEffect(String key, dynamic value) {
    switch (key) {
      case 'restore_streak':
        return 'Восстанавливает стрик задач';
      case 'xp_multiplier_2x':
        return 'Удваивает опыт (${(value as int? ?? 3600) ~/ 60} мин)';
      case 'xp_bonus':
        return '+${((value as num) * 100).toStringAsFixed(0)}% к опыту';
      case 'xp_hard_quest':
        return '+${((value as num) * 100).toStringAsFixed(0)}% к опыту за сложные задачи';
      case 'sellPrice':
        return 'Цена продажи: $value золота';
      default:
        return '$key: $value';
    }
  }
}

