import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/translations.dart';
import '../../core/item_rarity_style.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/economy_scale.dart';
import '../../core/widgets/world_material_chrome.dart';
import '../../core/widgets/world_surface_panel.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final visuals = Theme.of(context).extension<SystemVisuals>() ??
        const SystemVisuals(
          backgroundKind: SystemBackgroundKind.grid,
          backgroundAssetPath: '',
          particlesKind: SystemParticlesKind.none,
          panelRadius: 12,
          panelBorderWidth: 1,
          panelBlur: 0,
          titleLetterSpacing: 2.2,
          surfaceKind: SystemSurfaceKind.digital,
          glowIntensity: 0.35,
          borderRadiusScale: 1.0,
          shadowProfile: SystemShadowProfile.soft,
        );

    final shopItems = allGameItems;
    final cardRadius = context.worldCardRadius;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(t('shop')),
        centerTitle: true,
        actions: [
          // Виджет отображения золота
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(
                (visuals.panelRadius * visuals.borderRadiusScale * 0.75)
                    .clamp(8.0, 18.0),
              ),
              border: Border.all(
                color: scheme.secondary.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$gold',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.monetization_on,
                  color: scheme.secondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: WorldSurfacePanel(
          visuals: visuals,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: ListView.builder(
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
                  ItemRarityStyle.color(item.rarity, theme: theme);
              final borderCol = canAfford ? rarityC : scheme.error;
              final glow = visuals.glowIntensity.clamp(0.0, 1.0);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: switch (visuals.shadowProfile) {
                  SystemShadowProfile.none => 0,
                  SystemShadowProfile.soft => 3,
                  SystemShadowProfile.glow => 2,
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius),
                  side: BorderSide(
                    color: borderCol.withValues(alpha: canAfford ? 0.85 : 0.5),
                    width: 2,
                  ),
                ),
                shadowColor: canAfford
                    ? switch (visuals.shadowProfile) {
                        SystemShadowProfile.glow =>
                          rarityC.withValues(alpha: 0.28 + 0.2 * glow),
                        _ => rarityC.withValues(alpha: 0.22),
                      }
                    : null,
                child: WorldMaterialChrome(
                  visuals: visuals,
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(
                          (cardRadius * 0.55).clamp(6.0, 14.0),
                        ),
                        border: Border.all(color: rarityC, width: 1.5),
                        boxShadow: ItemRarityStyle.glow(
                          item.rarity,
                          theme: theme,
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

                    title: Text(
                      item.name,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: rarityC,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),

                    // КНОПКА ПОКУПКИ
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford
                            ? scheme.secondary
                            : scheme.surface.withValues(alpha: 0.9),
                        foregroundColor: canAfford
                            ? scheme.onSecondary
                            : scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      onPressed: canAfford
                          ? () {
                              ref.read(hunterProvider.notifier).buyItem(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t(
                                      'item_bought',
                                      params: {'name': item.name},
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: scheme.tertiary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text('$price ${dict.currencyName}'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
