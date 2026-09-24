import 'package:flutter/material.dart';

import '../game/content.dart';
import '../game/controller.dart';
import '../theme.dart';
import 'dialogs.dart';
import 'widgets.dart';

/// Inventory list: every block the player holds, in biome order.
class BagSheet extends StatelessWidget {
  const BagSheet({super.key, required this.controller});

  final GameController controller;

  static void show(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BagSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Bag',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final inv = controller.state.inventory;
          final order = <String>[
            for (final b in kBiomes)
              for (final blk in b.blocks) blk.id,
          ];
          final ids =
              order.where((id) => (inv[id] ?? 0) > 0).toList();
          return ids.isEmpty
              ? const Center(
                  child: Text(
                    'Empty. Start swinging.',
                    style: BB.bodyDim,
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  children: [
                    for (final id in ids)
                      inventoryRow(id, inv[id] ?? 0),
                  ],
                );
        },
      ),
    );
  }
}
