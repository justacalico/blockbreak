import 'package:flutter/material.dart';

import '../format.dart';
import '../game/content.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'widgets.dart';

class GearSheet extends StatelessWidget {
  const GearSheet({super.key, required this.controller});

  final GameController controller;

  static void show(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => GearSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;

    return SheetFrame(
      title: 'Gear',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              '${fmt(engine.effectivePps)} picks/sec',
              style: BB.stat.copyWith(color: BB.leaf),
            ),
          ),
          for (final b in kBiomes) ..._biomeSection(engine, b),
        ],
        ),
      ),
    );
  }

  List<Widget> _biomeSection(GameEngine engine, BiomeDef b) {
    final unlocked = engine.state.biomesUnlocked.contains(b.id);
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 2),
        child: Row(
          children: [
            Text(b.name, style: BB.displaySm),
            if (!unlocked) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline, size: 14, color: BB.dim),
            ],
          ],
        ),
      ),
    ];
    for (final g in b.gear) {
      widgets.add(_gearTile(engine, b, g, unlocked));
    }
    return widgets;
  }

  Widget _gearTile(
      GameEngine engine, BiomeDef b, GearDef g, bool biomeUnlocked) {
    final state = engine.state;
    final owned = state.gearOwned.contains(g.id);
    final afford = biomeUnlocked && engine.canAfford(g.cost);
    return SheetTile(
      dimmed: !biomeUnlocked,
      child: Row(
        children: [
          Icon(
            owned ? Icons.settings : Icons.settings_outlined,
            color: owned ? BB.leaf : BB.dim,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name, style: BB.body),
                Text(g.desc, style: BB.bodyDim),
                const SizedBox(height: 2),
                Text('+${fmt(g.pps)} pps',
                    style: BB.stat.copyWith(
                        fontSize: 15, color: BB.leaf)),
                if (!owned && biomeUnlocked) ...[
                  const SizedBox(height: 6),
                  CostRow(cost: g.cost, inventory: state.inventory),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (owned)
            const Icon(Icons.check_circle, color: BB.leaf, size: 20)
          else if (biomeUnlocked)
            PixelButton(
              label: 'BUY',
              small: true,
              onPressed:
                  afford ? () => controller.buyGear(g.id) : null,
            )
          else
            const Icon(Icons.lock_outline, color: BB.dim, size: 18),
        ],
      ),
    );
  }
}
