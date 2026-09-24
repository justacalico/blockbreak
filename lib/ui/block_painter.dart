import 'dart:math';

import 'package:flutter/material.dart';

import '../game/content.dart';

/// Deterministic pixel texture for a block. Renders a chunky 14x14 voxel
/// face with per-block patterns and a crack overlay driven by remaining HP.
class BlockPainter extends CustomPainter {
  BlockPainter({
    required this.block,
    required this.hpFraction,
    this.seed = 0,
  });

  static const int grid = 14;

  final BlockDef block;

  /// 1.0 = pristine, approaching 0 = nearly broken.
  final double hpFraction;

  /// Varies the texture so consecutive copies of a block differ.
  final int seed;

  int _hash(int x, int y) {
    var h = x * 73856093 ^ y * 19349663 ^ seed * 83492791;
    for (final c in block.id.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h & 0x7FFFFFFF;
  }

  Color _cellColor(int x, int y) {
    final p = block.palette;
    final h = _hash(x, y);
    switch (block.texture) {
      case TextureKind.stripes:
        final band = (y ~/ 3) % 2;
        return Color(h % 9 == 0 ? p[2] : p[band]);
      case TextureKind.rings:
        final d = max((x - grid / 2).abs(), (y - grid / 2).abs()).toInt();
        return Color(d % 3 == 0 ? p[3] : p[h % 3]);
      case TextureKind.speckled:
        if (h % 11 == 0) return Color(p[3 % p.length]);
        if (h % 5 == 0) return Color(p[1]);
        return Color(p[h % 3 == 0 ? 2 : 0]);
      case TextureKind.gems:
        if (h % 13 == 0) return Color(p[2]);
        if (h % 6 == 0) return Color(p[1]);
        return Color(p[h % 4 == 0 ? 3 : 0]);
      case TextureKind.cracks:
        if (h % 7 == 0) return Color(p[1]);
        return Color(p[h % 3 == 0 ? 2 : 0]);
      case TextureKind.plain:
        if (h % 6 == 0) return Color(p[1]);
        if (h % 10 == 0) return Color(p[2]);
        return Color(p[0]);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / grid;
    final paint = Paint();
    for (var y = 0; y < grid; y++) {
      for (var x = 0; x < grid; x++) {
        paint.color = _cellColor(x, y);
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }

    // Voxel lighting: bright top/left rim, dark bottom/right rim.
    final rim = size.width * 0.05;
    final light = Paint()..color = const Color(0x38FFFFFF);
    final shade = Paint()..color = const Color(0x4D000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rim), light);
    canvas.drawRect(Rect.fromLTWH(0, 0, rim, size.height), light);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - rim, size.width, rim), shade);
    canvas.drawRect(
        Rect.fromLTWH(size.width - rim, 0, rim, size.height), shade);

    _paintCracks(canvas, size);
  }

  void _paintCracks(Canvas canvas, Size size) {
    final damage = (1 - hpFraction).clamp(0.0, 1.0);
    if (damage <= 0) return;
    final lines = (damage * 7).ceil();
    final paint = Paint()
      ..color = const Color(0xB0000000)
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < lines; i++) {
      final sx = (_hash(i, 0) % 100) / 100 * size.width;
      final sy = (_hash(i, 7) % 100) / 100 * size.height;
      path.moveTo(sx, sy);
      var px = sx;
      var py = sy;
      for (var s = 0; s < 4; s++) {
        px += ((_hash(i, s * 3 + 1) % 100) / 100 - 0.5) * size.width * 0.5;
        py += ((_hash(i, s * 3 + 2) % 100) / 100 - 0.4) * size.height * 0.35;
        path.lineTo(px.clamp(0.0, size.width), py.clamp(0.0, size.height));
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BlockPainter old) =>
      old.block != block ||
      old.hpFraction != hpFraction ||
      old.seed != seed;
}

/// Small square chip showing a block's face, used in lists and costs.
class BlockIcon extends StatelessWidget {
  const BlockIcon({super.key, required this.blockId, this.size = 22});

  final String blockId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BlockPainter(
          block: blockDef(blockId),
          hpFraction: 1,
        ),
      ),
    );
  }
}
