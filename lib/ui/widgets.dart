import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import 'block_painter.dart';

/// Block face + amount, used anywhere a cost or reward is shown.
class CostChip extends StatelessWidget {
  const CostChip({
    super.key,
    required this.blockId,
    required this.amount,
    this.owned,
    this.compact = false,
  });

  final String blockId;
  final num amount;
  final num? owned;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enough = owned == null || owned! >= amount;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: BB.ink.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enough ? BB.edge : BB.danger.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlockIcon(blockId: blockId, size: compact ? 14 : 18),
          const SizedBox(width: 4),
          Text(
            owned == null
                ? fmt(amount)
                : '${fmt(owned!)}/${fmt(amount)}',
            style: BB.stat.copyWith(
              fontSize: compact ? 14 : 16,
              color: enough ? BB.cream : BB.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class CostRow extends StatelessWidget {
  const CostRow({super.key, required this.cost, required this.inventory});

  final Map<String, int> cost;
  final Map<String, double> inventory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final e in cost.entries)
          CostChip(
            blockId: e.key,
            amount: e.value,
            owned: inventory[e.key] ?? 0,
          ),
      ],
    );
  }
}

/// Chunky pixel-styled button.
class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = BB.gold,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: enabled ? color : BB.panel2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 10 : 16,
              vertical: small ? 7 : 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.35),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              label,
              style: BB.displaySm.copyWith(
                color: enabled ? BB.ink : BB.dim,
                fontSize: small ? 8 : 9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet frame with drag handle and title.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: BB.edge,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: BB.display),
            ),
          ),
          const Divider(height: 1, color: BB.edge),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Row container used by every sheet list.
class SheetTile extends StatelessWidget {
  const SheetTile({super.key, required this.child, this.dimmed = false});

  final Widget child;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dimmed ? BB.panel.withValues(alpha: 0.5) : BB.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BB.edge),
      ),
      child: child,
    );
  }
}

/// Little square icon button for the top bar.
class HudButton extends StatelessWidget {
  const HudButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: BB.cream, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: BB.panel.withValues(alpha: 0.8),
        side: const BorderSide(color: BB.edge),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
