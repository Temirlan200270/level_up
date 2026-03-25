import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';

class GoldDisplay extends ConsumerWidget {
  const GoldDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunter = ref.watch(hunterProvider);
    final gold = hunter?.gold ?? 0;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$gold',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.monetization_on, color: scheme.secondary, size: 24),
        ],
      ),
    );
  }
}
