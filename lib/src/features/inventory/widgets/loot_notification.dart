import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Всплывающее уведомление о получении предмета с анимацией свечения
class LootNotification extends StatefulWidget {
  final String itemName;
  final String? itemRarity;
  final int? goldAmount;

  const LootNotification({
    super.key,
    required this.itemName,
    this.itemRarity,
    this.goldAmount,
  });

  @override
  State<LootNotification> createState() => _LootNotificationState();
}

class _LootNotificationState extends State<LootNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloLevelingColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SoloLevelingColors.neonBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SoloLevelingColors.neonBlue.withValues(alpha: _glowAnimation.value),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: SoloLevelingColors.neonBlue.withValues(alpha: _glowAnimation.value * 0.5),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SoloLevelingColors.neonBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.goldAmount != null
                ? const Icon(
                    Icons.monetization_on,
                    color: SoloLevelingColors.warning,
                    size: 28,
                  )
                : const Icon(
                    Icons.inventory_2,
                    color: SoloLevelingColors.neonBlue,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.goldAmount != null ? 'ПОЛУЧЕНО ЗОЛОТО' : 'ПРЕДМЕТ ПОЛУЧЕН',
                  style: TextStyle(
                    color: SoloLevelingColors.neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.goldAmount != null ? '${widget.goldAmount} золота' : widget.itemName,
                  style: const TextStyle(
                    color: SoloLevelingColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.itemRarity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.itemRarity!,
                    style: TextStyle(
                      color: SoloLevelingColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Иконка закрытия
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: SoloLevelingColors.textSecondary,
            onPressed: () {
              // Закрытие обрабатывается через ScaffoldMessenger
            },
          ),
        ],
      ),
        );
      },
    );
  }
}

