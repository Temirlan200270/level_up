import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';

// Убедись, что пути правильные (зависят от твоей структуры папок)
import '../../data/items_data.dart';
import '../../services/providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = useTranslations(ref);
    // Получаем текущее количество золота (с защитой от null)
    final gold = ref.watch(hunterProvider.select((h) => h?.gold ?? 0));
    
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
                    color: Colors.amber
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              ],
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: shopItems.length,
        itemBuilder: (context, index) {
          final item = shopItems[index];
          final canAfford = gold >= item.buyPrice;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: canAfford ? Colors.grey.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                // ИКОНКА ПРЕДМЕТА
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      item.iconPath,
                      fit: BoxFit.contain,
                      // Если картинка не найдена, показываем заглушку
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.help_outline, color: Colors.grey);
                      },
                    ),
                  ),
                ),
                
                // ОПИСАНИЕ
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                    backgroundColor: canAfford ? Colors.amber : Colors.grey[800],
                    foregroundColor: canAfford ? Colors.black : Colors.grey,
                  ),
                  onPressed: canAfford
                      ? () {
                          // Логика покупки
                          ref.read(hunterProvider.notifier).buyItem(item);
                          
                          // Уведомление об успехе
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('item_bought', params: {'name': item.name})),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null, // Кнопка отключена, если нет денег
                  child: Text('${item.buyPrice} ${t('gold')}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}