import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../core/item_rarity_style.dart';
import '../../core/theme.dart';
import '../../core/economy_scale.dart';

import '../../data/items_data.dart';
import '../../services/providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    final dict = ref.watch(activeSystemProvider).dictionary;
    // Получаем текущее количество золота (с защитой от null)
    final gold = ref.watch(hunterProvider.select((h) => h?.gold ?? 0));
    final hunterLevel = ref.watch(hunterProvider.select((h) => h?.level ?? 1));

    // Список товаров из файла данных
    final shopItems = allGameItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('shop')),
        centerTitle: true,
        actions: [
          // Виджет отображения золота
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Text(
                  '$gold',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: shopItems.length,
        itemBuilder: (context, index) {
          final item = shopItems[index];
          final price = EconomyScale.scaledShopBuyPrice(
            item.buyPrice,
            hunterLevel,
          );
          final canAfford = gold >= price;
          final rarityC =
              ItemRarityStyle.color(item.rarity, theme: Theme.of(context));
          final borderCol = canAfford ? rarityC : SoloLevelingColors.error;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: borderCol.withValues(alpha: canAfford ? 0.85 : 0.5),
                width: 2,
              ),
            ),
            shadowColor: canAfford ? rarityC.withValues(alpha: 0.35) : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityC, width: 1.5),
                    boxShadow: ItemRarityStyle.glow(
                      item.rarity,
                      theme: Theme.of(context),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      item.iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.inventory_2, color: rarityC);
                      },
                    ),
                  ),
                ),

                // ОПИСАНИЕ
                title: Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold, color: rarityC),
                ),
                subtitle: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),

                // КНОПКА ПОКУПКИ
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? Colors.amber
                        : Colors.grey[800],
                    foregroundColor: canAfford ? Colors.black : Colors.grey,
                  ),
                  onPressed: canAfford
                      ? () {
                          // Логика покупки
                          ref.read(hunterProvider.notifier).buyItem(item);

                          // Уведомление об успехе
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t('item_bought', params: {'name': item.name}),
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null, // Кнопка отключена, если нет денег
                  child: Text('$price ${dict.currencyName}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
