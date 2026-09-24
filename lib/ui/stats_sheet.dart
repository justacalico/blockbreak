import 'package:flutter/material.dart';

import '../format.dart';
import '../game/content.dart';
import '../game/controller.dart';
import '../theme.dart';
import 'dialogs.dart';
import 'widgets.dart';

class StatsSheet extends StatelessWidget {
  const StatsSheet({super.key, required this.controller});

  final GameController controller;

  static void show(BuildContext context, GameController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatsSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;

    return SheetFrame(
      title: 'Stats',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final s = engine.state;
          final stats = s.stats;
          final abilities = s.biomesUnlocked
              .map(biomeDef)
              .map((b) => b.ability)
              .whereType<AbilityDef>()
              .toList();
          return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          _row('Swings', fmt(stats.totalTaps)),
          _row('Blocks broken', fmt(stats.totalBlocks)),
          _row('Critical hits', fmt(stats.totalCrits)),
          _row('Chests opened', fmt(stats.chestsOpened)),
          _row('Prestiges', fmt(s.prestigeCount)),
          _row('Damage / swing', fmt(engine.swingDamage)),
          _row('Picks / sec', fmt(engine.pps)),
          _row('Crit chance',
              '${(engine.critChance * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 18),
          const Text('Abilities', style: BB.displaySm),
          const SizedBox(height: 8),
          if (abilities.isEmpty)
            const Text(
                'Unlock new biomes to earn abilities.',
                style: BB.bodyDim)
          else
            for (final a in abilities)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high,
                        size: 16, color: BB.runic),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.name, style: BB.body)),
                    Text(a.desc, style: BB.bodyDim),
                  ],
                ),
              ),
          const SizedBox(height: 26),
          Center(
            child: PixelButton(
              label: 'RESET SAVE',
              color: BB.danger,
              small: true,
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Reset save?',
                  body: 'All progress will be permanently erased.',
                  confirmLabel: 'ERASE',
                );
                if (ok && context.mounted) {
                  controller.resetSave();
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: BB.bodyDim)),
          Text(value, style: BB.stat),
        ],
      ),
    );
  }
}
