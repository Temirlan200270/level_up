import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/enums.dart';
import '../../../models/hunter_model.dart';
import '../../../services/providers.dart';
import '../../../core/system_visuals_extension.dart';
import '../../../core/translations.dart';
import '../../../core/item_rarity_style.dart';
import '../../../core/economy_scale.dart';

/// Модальное окно с деталями предмета
class ItemDetailPopup extends ConsumerWidget {
  final InventorySlot slot;

  const ItemDetailPopup({super.key, required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = slot.item;
    final scheme = Theme.of(context).colorScheme;
    final sheetTopR = (context.worldCardRadius * 1.35).clamp(18.0, 28.0);
    final thumbR = (context.worldCardRadius * 0.65).clamp(8.0, 16.0);
    final rarityColor = ItemRarityStyle.color(
      item.rarity,
      theme: Theme.of(context),
    );
    final t = useTranslations(ref);
    final hunter = ref.watch(hunterProvider);
    final sellLevel = hunter?.level ?? 1;
    final baseSellUnit =
        item.effects?['sellPrice'] as int? ?? item.buyPrice ~/ 2;
    final sellUnitPrice =
        EconomyScale.scaledShopSellUnitPrice(baseSellUnit, sellLevel);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetTopR)),
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(sheetTopR),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(thumbR),
                      border: Border.all(color: rarityColor, width: 2),
                    ),
                    child: Icon(
                      Icons.inventory_2,
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
                          style: GoogleFonts.manrope(
                            color: rarityColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (slot.quantity > 1)
                          Text(
                            '${t('quantity')}: ${slot.quantity}',
                            style: GoogleFonts.manrope(
                              color: scheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          t('rarity_${item.rarity.name}'),
                          style: GoogleFonts.manrope(
                            color: rarityColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                style: GoogleFonts.manrope(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
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
                      style: GoogleFonts.manrope(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatEffect(entry.key, entry.value),
                              style: GoogleFonts.manrope(
                                color: scheme.onSurfaceVariant,
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
                              content: Text(
                                t('item_used', params: {'name': item.name}),
                              ),
                              backgroundColor: scheme.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_fix_high),
                        label: Text(t('use')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                      ),
                    ),

                  // Кнопка "Экипировать" (для экипировки)
                  if (item.type == ItemType.equipment && item.slot != null) ...[
                    if (item.type == ItemType.consumable)
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(hunterProvider.notifier).equipItem(item);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t('item_equipped', params: {'name': item.name}),
                              ),
                              backgroundColor: scheme.secondary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: Text(t('equip')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.secondary,
                          foregroundColor: scheme.onSecondary,
                        ),
                      ),
                    ),
                  ],

                  // Кнопка "Продать" (для материалов и лишних предметов)
                  if (item.type == ItemType.material ||
                      item.type == ItemType.consumable) ...[
                    if (item.type == ItemType.equipment)
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final totalPrice = sellUnitPrice * slot.quantity;

                          // Используем атомарный метод продажи
                          await ref
                              .read(hunterProvider.notifier)
                              .sellItem(item.id, slot.quantity, sellUnitPrice);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t(
                                    'sold_for',
                                    params: {'amount': totalPrice.toString()},
                                  ),
                                ),
                                backgroundColor: scheme.tertiary,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.sell),
                        label: Text(t('sell')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.tertiary,
                          foregroundColor: scheme.onTertiary,
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
