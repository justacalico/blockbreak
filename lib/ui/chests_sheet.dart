import 'package:flutter/material.dart';

import '../format.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'dialogs.dart';
import 'widgets.dart';

class ChestsSheet extends StatelessWidget {
  const ChestsSheet({super.key, required this.controller});

  final GameController controller;

  static void show(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChestsSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;

    return SheetFrame(
      title: 'Chests',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = engine.state;
          final smallCost = engine.smallChestCost;
          return ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          _chestCard(
            context,
            icon: Icons.inventory_2,
            color: BB.gold,
            name: 'Small Chest',
            desc: 'A handful of blocks from the lands you know. '
                'Small chance of runic or a pickaxe.',
            costLabel: '${fmt(smallCost)} picks',
            enabled: state.picks >= smallCost,
            onOpen: () => _open(context, ChestKind.small),
          ),
          _chestCard(
            context,
            icon: Icons.card_giftcard,
            color: BB.runic,
            name: 'Large Chest',
            desc: 'Heavy with rare blocks. Good odds of a pickaxe '
                'and often some runic back.',
            costLabel: '${fmt(GameEngine.largeChestCost)} runic',
            enabled: state.runic >= GameEngine.largeChestCost,
            onOpen: () => _open(context, ChestKind.large),
          ),
        ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, ChestKind kind) {
    final reward = controller.openChest(kind);
    if (reward != null && context.mounted) {
      showChestReward(context, reward);
    }
  }

  Widget _chestCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String name,
    required String desc,
    required String costLabel,
    required bool enabled,
    required VoidCallback onOpen,
  }) {
    return SheetTile(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BB.body),
                const SizedBox(height: 3),
                Text(desc, style: BB.bodyDim),
                const SizedBox(height: 6),
                Text(costLabel,
                    style: BB.stat.copyWith(fontSize: 16, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PixelButton(
            label: 'OPEN',
            small: true,
            color: color,
            onPressed: enabled ? onOpen : null,
          ),
        ],
      ),
    );
  }
}
