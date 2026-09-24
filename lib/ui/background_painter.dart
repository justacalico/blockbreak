import 'dart:math';

import 'package:flutter/material.dart';

import '../game/content.dart';

/// Sky gradient plus simple per-biome silhouettes behind the mine area.
class BiomeBackgroundPainter extends CustomPainter {
  BiomeBackgroundPainter({required this.biome});

  final BiomeDef biome;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(biome.sky[0]), Color(biome.sky[1])],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    _scene(canvas, size);

    // Ground strip at the bottom.
    final groundTop = size.height * 0.78;
    final ground = Paint()..color = Color(biome.ground);
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, size.height - groundTop),
      ground,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, 3),
      Paint()..color = const Color(0x30FFFFFF),
    );
  }

  void _scene(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (biome.id) {
      case 'plains':
        _hills(canvas, size, const Color(0xFF5C8A3E));
        _sun(canvas, Offset(w * 0.82, h * 0.14), w * 0.06,
            const Color(0xFFFFF2B8));
      case 'desert':
        _sun(canvas, Offset(w * 0.5, h * 0.18), w * 0.1,
            const Color(0xFFFFF0C0));
        _pyramid(canvas, size, w * 0.2, const Color(0xFFD4AC6A));
        _pyramid(canvas, size, w * 0.66, const Color(0xFFC49A58));
      case 'tundra':
        _pines(canvas, size, const Color(0xFF9FC4D8));
      case 'caves':
      case 'deep_caverns':
        _stalactites(canvas, size, const Color(0xFF23262E));
        if (biome.id == 'deep_caverns') {
          _stars(canvas, size, const Color(0xFF4FD8E0), 18);
        }
      case 'mesa':
        _mesa(canvas, size, const Color(0xFF9E5233));
      case 'jungle':
        _pines(canvas, size, const Color(0xFF1E4630), round: true);
      case 'ocean':
        _waves(canvas, size, const Color(0xFF17406B));
      case 'lava_fields':
        _lava(canvas, size);
      case 'nether':
        _stalactites(canvas, size, const Color(0xFF2A0A10));
        _lavaGlow(canvas, size, const Color(0x66F4622E));
      case 'moon':
        _stars(canvas, size, Colors.white, 40);
        _moon(canvas, size);
      case 'the_end':
        _stars(canvas, size, const Color(0xFFB48CF2), 50);
        _islands(canvas, size);
    }
  }

  void _sun(Canvas c, Offset center, double r, Color color) {
    c.drawCircle(center, r, Paint()..color = color);
    c.drawCircle(center, r * 1.5, Paint()..color = color.withValues(alpha: 0.25));
  }

  void _hills(Canvas c, Size s, Color color) {
    final p = Path()
      ..moveTo(0, s.height * 0.78)
      ..quadraticBezierTo(
          s.width * 0.2, s.height * 0.6, s.width * 0.42, s.height * 0.78)
      ..quadraticBezierTo(
          s.width * 0.66, s.height * 0.58, s.width, s.height * 0.76)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _pyramid(Canvas c, Size s, double x, Color color) {
    final base = s.height * 0.78;
    final p = Path()
      ..moveTo(x, base)
      ..lineTo(x + s.width * 0.16, s.height * 0.48)
      ..lineTo(x + s.width * 0.32, base)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _pines(Canvas c, Size s, Color color, {bool round = false}) {
    final base = s.height * 0.78;
    final paint = Paint()..color = color;
    for (var i = 0; i < 6; i++) {
      final x = s.width * (0.08 + i * 0.16);
      final th = s.height * (0.14 + (i % 3) * 0.05);
      if (round) {
        c.drawCircle(Offset(x, base - th), s.width * 0.05, paint);
        c.drawRect(
            Rect.fromLTWH(x - 2, base - th, 4, th), paint);
      } else {
        final p = Path()
          ..moveTo(x - s.width * 0.045, base)
          ..lineTo(x, base - th)
          ..lineTo(x + s.width * 0.045, base)
          ..close();
        c.drawPath(p, paint);
      }
    }
  }

  void _stalactites(Canvas c, Size s, Color color) {
    final paint = Paint()..color = color;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height * 0.05), paint);
    for (var i = 0; i < 7; i++) {
      final x = s.width * (i * 0.15 + 0.03);
      final depth = s.height * (0.08 + (i % 3) * 0.06);
      final p = Path()
        ..moveTo(x, s.height * 0.05)
        ..lineTo(x + s.width * 0.05, s.height * 0.05)
        ..lineTo(x + s.width * 0.025, s.height * 0.05 + depth)
        ..close();
      c.drawPath(p, paint);
    }
  }

  void _mesa(Canvas c, Size s, Color color) {
    final base = s.height * 0.78;
    final paint = Paint()..color = color;
    for (final spec in [(0.05, 0.22, 0.34), (0.6, 0.3, 0.2)]) {
      final x = s.width * spec.$1;
      final w = s.width * spec.$2;
      final top = base - s.height * spec.$3;
      c.drawRect(Rect.fromLTWH(x, top, w, base - top), paint);
      c.drawRect(
          Rect.fromLTWH(x - w * 0.15, top, w * 1.3, 6), paint);
    }
  }

  void _waves(Canvas c, Size s, Color color) {
    final base = s.height * 0.78;
    final paint = Paint()..color = color.withValues(alpha: 0.8);
    for (var i = 0; i < 4; i++) {
      final y = base - i * s.height * 0.05;
      final p = Path()..moveTo(0, y);
      for (var x = 0.0; x <= s.width; x += s.width / 8) {
        p.quadraticBezierTo(
            x + s.width / 16, y - 10 - i * 2, x + s.width / 8, y);
      }
      p.lineTo(s.width, base);
      p.lineTo(0, base);
      c.drawPath(p, paint);
    }
  }

  void _lava(Canvas c, Size s) {
    final base = s.height * 0.78;
    _stalactites(c, s, const Color(0xFF2A0E08));
    final lava = Paint()..color = const Color(0xFFF4622E);
    final p = Path()..moveTo(0, base);
    for (var x = 0.0; x <= s.width; x += s.width / 6) {
      p.lineTo(x, base - (x / s.width * 14 % 18));
    }
    p.lineTo(s.width, base + 8);
    p.lineTo(0, base + 8);
    c.drawPath(p, lava);
    _lavaGlow(c, s, const Color(0x55F4622E));
  }

  void _lavaGlow(Canvas c, Size s, Color color) {
    c.drawRect(
      Rect.fromLTWH(0, s.height * 0.6, s.width, s.height * 0.18),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(
            Rect.fromLTWH(0, s.height * 0.6, s.width, s.height * 0.18)),
    );
  }

  void _stars(Canvas c, Size s, Color color, int count) {
    final paint = Paint()..color = color;
    final rnd = Random(7);
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = rnd.nextDouble() * s.height * 0.6;
      c.drawRect(
          Rect.fromLTWH(x, y, 2, 2),
          paint..color = color.withValues(alpha: 0.4 + rnd.nextDouble() * 0.6));
    }
  }

  void _moon(Canvas c, Size s) {
    _sun(c, Offset(s.width * 0.78, s.height * 0.16), s.width * 0.09,
        const Color(0xFFE8EAF2));
    final craters = Paint()..color = const Color(0xFFB8BECC);
    c.drawCircle(
        Offset(s.width * 0.75, s.height * 0.14), s.width * 0.02, craters);
    c.drawCircle(
        Offset(s.width * 0.82, s.height * 0.19), s.width * 0.015, craters);
  }

  void _islands(Canvas c, Size s) {
    final paint = Paint()..color = const Color(0xFF3A2E58);
    final top = Paint()..color = const Color(0xFF8E94B0);
    for (final spec in [(0.15, 0.3, 0.2), (0.6, 0.18, 0.26), (0.45, 0.5, 0.14)]) {
      final x = s.width * spec.$1;
      final y = s.height * spec.$2;
      final w = s.width * spec.$3;
      c.drawRect(Rect.fromLTWH(x, y, w, 8), top);
      final p = Path()
        ..moveTo(x, y + 8)
        ..lineTo(x + w, y + 8)
        ..lineTo(x + w * 0.5, y + 8 + w * 0.5)
        ..close();
      c.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(BiomeBackgroundPainter old) => old.biome != biome;
}
