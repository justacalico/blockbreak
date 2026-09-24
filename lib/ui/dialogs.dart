import 'package:flutter/material.dart';

import '../format.dart';
import '../game/content.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'block_painter.dart';
import 'pickaxe_painter.dart';
import 'widgets.dart';

Future<void> showChestReward(BuildContext context, ChestReward reward) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Loot', style: BB.display),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reward.pickaxeId != null) ...[
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CustomPaint(
                    painter: PickaxePainter(
                        def: pickaxeDef(reward.pickaxeId!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pickaxeDef(reward.pickaxeId!).name}!',
                    style: BB.displaySm.copyWith(color: BB.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (reward.runic > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('+${fmt(reward.runic)} runic',
                  style: BB.stat.copyWith(color: BB.runic)),
            ),
          if (reward.blocks.isEmpty && reward.pickaxeId == null &&
              reward.runic == 0)
            const Text('Nothing this time.', style: BB.bodyDim)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in reward.blocks.entries)
                  CostChip(
                      blockId: e.key, amount: e.value, compact: true),
              ],
            ),
        ],
      ),
      actions: [
        PixelButton(
          label: 'NICE',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

Future<void> showOfflineReport(BuildContext context, OfflineReport r) {
  final hours = r.seconds ~/ 3600;
  final mins = (r.seconds % 3600) ~/ 60;
  final away =
      hours > 0 ? '${hours}h ${mins}m' : '${mins}m ${r.seconds % 60}s';
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Welcome back', style: BB.display),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your gear kept digging for $away.',
              style: BB.bodyDim),
          const SizedBox(height: 14),
          Text('+${fmt(r.picks)} picks',
              style: BB.stat.copyWith(color: BB.gold)),
          const SizedBox(height: 8),
          if (r.blocks.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in r.blocks.entries)
                  CostChip(
                      blockId: e.key, amount: e.value, compact: true),
              ],
            )
          else
            const Text('No blocks auto-mined.', style: BB.bodyDim),
        ],
      ),
      actions: [
        PixelButton(
          label: 'COLLECT',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: BB.display),
      content: Text(body, style: BB.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: BB.bodyDim),
        ),
        PixelButton(
          label: confirmLabel,
          color: BB.danger,
          small: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Read-only block face + name + count, for inventory lists.
Widget inventoryRow(String blockId, double count) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        BlockIcon(blockId: blockId, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(blockDef(blockId).name, style: BB.body),
        ),
        Text(fmt(count), style: BB.stat),
      ],
    ),
  );
}
