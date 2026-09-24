import 'package:flutter/material.dart';

import '../format.dart';
import '../game/content.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'dialogs.dart';
import 'widgets.dart';

class BiomesSheet extends StatelessWidget {
  const BiomesSheet({super.key, required this.controller});

  final GameController controller;

  static void show(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BiomesSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;

    return SheetFrame(
      title: 'Biomes',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = engine.state;
          final nextId = engine.nextBiomeId;
          return ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          for (final b in kBiomes) ...[
            if (state.biomesUnlocked.contains(b.id))
              _unlockedTile(context, engine, b)
            else if (b.id == nextId)
              _unlockableTile(context, engine, b)
            else
              const SheetTile(
                dimmed: true,
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: BB.dim, size: 18),
                    SizedBox(width: 10),
                    Text('Unknown land', style: BB.bodyDim),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),
          _prestigeCard(context, engine),
        ],
          );
        },
      ),
    );
  }

  Widget _unlockedTile(
      BuildContext context, GameEngine engine, BiomeDef b) {
    final here = engine.state.currentBiome == b.id;
    return SheetTile(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(b.sky[0]), Color(b.ground)],
              ),
              border: Border.all(color: BB.edge),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name, style: BB.body),
                if (b.ability != null)
                  Text(b.ability!.name,
                      style: BB.bodyDim.copyWith(
                          fontSize: 11, color: BB.runic)),
              ],
            ),
          ),
          if (here)
            const Text('HERE', style: BB.displaySm)
          else
            PixelButton(
              label: 'GO',
              small: true,
              color: BB.leaf,
              onPressed: () {
                controller.travelTo(b.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _unlockableTile(
      BuildContext context, GameEngine engine, BiomeDef b) {
    final afford = engine.canAfford(b.unlockCost);
    return SheetTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_open, color: BB.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(b.name, style: BB.body)),
            ],
          ),
          const SizedBox(height: 4),
          Text(b.unlockLabel, style: BB.bodyDim),
          const SizedBox(height: 8),
          CostRow(cost: b.unlockCost, inventory: engine.state.inventory),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: PixelButton(
              label: 'UNLOCK',
              small: true,
              onPressed: afford
                  ? () {
                      controller.unlockBiome(b.id);
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prestigeCard(BuildContext context, GameEngine engine) {
    final can = engine.canPrestige;
    return SheetTile(
      dimmed: !can,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: BB.runic, size: 18),
              SizedBox(width: 10),
              Text('Prestige', style: BB.body),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            can
                ? 'Convert this run into ${fmt(engine.prestigeRunic)} runic. '
                    'Blocks, gear and biomes reset; pickaxes keep their levels.'
                : 'Reach The End and craft the Endstone Pickaxe to prestige.',
            style: BB.bodyDim,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: PixelButton(
              label: 'PRESTIGE',
              small: true,
              color: BB.runic,
              onPressed: can
                  ? () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Prestige?',
                        body:
                            'Your blocks, gear and biome progress reset. '
                            'You gain ${fmt(engine.prestigeRunic)} runic and +1 max pickaxe level.',
                        confirmLabel: 'DO IT',
                      );
                      if (ok && context.mounted) {
                        controller.prestige();
                        Navigator.of(context).pop();
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
