import 'package:flutter/material.dart';

import '../game/content.dart';

/// Pixel pickaxe on a 16x16 grid. The widget is drawn upright with the
/// handle running to the bottom-left; callers rotate it for swings.
class PickaxePainter extends CustomPainter {
  PickaxePainter({required this.def});

  static const int grid = 16;

  final PickaxeDef def;

  static const _headCells = [
    [2, 7], [3, 6], [4, 5], [5, 4], [6, 4], [7, 4], [8, 4], [9, 4],
    [10, 4], [11, 4], [12, 5], [13, 6], [14, 7], [5, 5], [6, 5],
    [7, 5], [8, 5], [9, 5], [10, 5], [11, 5],
  ];

  static const _handleCells = [
    [3, 12], [4, 12], [4, 13], [4, 11], [5, 11], [5, 10], [6, 10],
    [6, 9], [7, 9], [7, 8], [8, 8], [8, 7], [9, 7], [9, 6], [10, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / grid;
    final paint = Paint();
    final head = Color(def.head);
    final outline = const Color(0xFF14121A);

    void px(int x, int y, Color c, [double grow = 0.4]) {
      paint.color = c;
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell + grow, cell + grow),
        paint,
      );
    }

    // Outline pass: darken cells around head for readability.
    for (final c in _headCells) {
      px(c[0], c[1], outline, 1.2);
    }
    for (final c in _headCells) {
      px(c[0], c[1], head);
    }
    // Bright top edge on the head.
    for (final c in _headCells) {
      if (c[1] == 4) px(c[0], c[1], Color.lerp(head, Colors.white, 0.35)!);
    }
    for (final c in _handleCells) {
      px(c[0], c[1], outline, 1.2);
    }
    for (final c in _handleCells) {
      px(c[0], c[1], Color(def.handle));
    }
    // Grip highlight.
    px(5, 11, Color.lerp(Color(def.handle), Colors.white, 0.25)!);
    px(6, 10, Color.lerp(Color(def.handle), Colors.white, 0.25)!);
  }

  @override
  bool shouldRepaint(PickaxePainter old) => old.def != def;
}
