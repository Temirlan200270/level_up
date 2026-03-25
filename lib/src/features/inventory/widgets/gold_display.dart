import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';

class GoldDisplay extends ConsumerWidget {
  const GoldDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunter = ref.watch(hunterProvider);
    final gold = hunter?.gold ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$gold',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
        ],
      ),
    );
  }
}
