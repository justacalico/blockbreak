import 'package:flutter/material.dart';

import '../format.dart';
import '../game/content.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'pickaxe_painter.dart';
import 'widgets.dart';

class PickaxesSheet extends StatelessWidget {
  const PickaxesSheet({super.key, required this.controller});

  final GameController controller;

  static void show(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PickaxesSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;

    return SheetFrame(
      title: 'Pickaxes',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          for (final def in kPickaxes) _tile(context, engine, def),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Max level ${engine.maxPickaxeLevel} (prestige to raise)',
              style: BB.bodyDim,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, GameEngine engine, PickaxeDef def) {
    final state = engine.state;
    final st = state.pickaxes[def.id];
    final owned = st?.owned ?? false;
    final equipped = state.equippedPickaxe == def.id;
    final level = st?.level ?? 0;
    final str = engine.pickaxeStrength(def.id);
    final crit = engine.critChanceFor(def.id);

    return SheetTile(
      dimmed: !owned && !engine.canAfford(def.cost),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CustomPaint(painter: PickaxePainter(def: def)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${def.name}${level > 0 ? ' +$level' : ''}',
                  style: BB.body,
                ),
                const SizedBox(height: 3),
                Text(
                  '${fmt(str)} dmg  ·  ${(crit * 100).toStringAsFixed(0)}% crit',
                  style: BB.bodyDim,
                ),
                if (!owned && !def.free) ...[
                  const SizedBox(height: 6),
                  CostRow(cost: def.cost, inventory: state.inventory),
                ],
                if (owned && level < engine.maxPickaxeLevel) ...[
                  const SizedBox(height: 6),
                  CostRow(
                      cost: engine.upgradeCost(def.id),
                      inventory: state.inventory),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!owned)
                PixelButton(
                  label: 'BUY',
                  small: true,
                  onPressed: engine.canAfford(def.cost)
                      ? () => controller.buyPickaxe(def.id)
                      : null,
                )
              else if (equipped)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('EQUIPPED', style: BB.displaySm),
                )
              else
                PixelButton(
                  label: 'EQUIP',
                  small: true,
                  color: BB.leaf,
                  onPressed: () => controller.equipPickaxe(def.id),
                ),
              if (owned && level < engine.maxPickaxeLevel) ...[
                const SizedBox(height: 6),
                PixelButton(
                  label: 'UPGRADE',
                  small: true,
                  color: BB.runic,
                  onPressed:
                      engine.canAfford(engine.upgradeCost(def.id))
                          ? () => controller.upgradePickaxe(def.id)
                          : null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
