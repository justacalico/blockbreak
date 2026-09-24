import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Particle {
  Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.life,
  });

  Offset pos;
  Offset vel;
  Color color;
  double size;
  double life;
  double age = 0;
}

class FloatText {
  FloatText({
    required this.pos,
    required this.text,
    required this.color,
    required this.big,
  });

  Offset pos;
  String text;
  Color color;
  bool big;
  double age = 0;
  static const life = 0.9;
}

/// Mutable list of active particles and floating texts, stepped by the
/// overlay's ticker.
class EffectsController extends ChangeNotifier {
  EffectsController({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;
  final List<Particle> particles = [];
  final List<FloatText> texts = [];

  /// Block-break burst of voxel chunks.
  void burst(Offset center, double radius, List<int> palette) {
    for (var i = 0; i < 18; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 60 + _rng.nextDouble() * 220;
      particles.add(Particle(
        pos: center +
            Offset((_rng.nextDouble() - 0.5) * radius,
                (_rng.nextDouble() - 0.5) * radius),
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 160),
        color: Color(palette[_rng.nextInt(palette.length)]),
        size: 4 + _rng.nextDouble() * 8,
        life: 0.6 + _rng.nextDouble() * 0.5,
      ));
    }
    notifyListeners();
  }

  /// Small chip spray on every hit.
  void chips(Offset at, List<int> palette) {
    for (var i = 0; i < 4; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * 2.4;
      final speed = 120 + _rng.nextDouble() * 160;
      particles.add(Particle(
        pos: at,
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: Color(palette[_rng.nextInt(palette.length)]),
        size: 3 + _rng.nextDouble() * 5,
        life: 0.4 + _rng.nextDouble() * 0.3,
      ));
    }
    notifyListeners();
  }

  void label(Offset pos, String text, Color color, {bool big = false}) {
    texts.add(FloatText(pos: pos, text: text, color: color, big: big));
    notifyListeners();
  }

  void tick(double dt) {
    var dirty = false;
    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.age += dt;
      if (p.age >= p.life) {
        particles.removeAt(i);
      } else {
        p.vel += const Offset(0, 900) * dt;
        p.pos += p.vel * dt;
      }
      dirty = true;
    }
    for (var i = texts.length - 1; i >= 0; i--) {
      final t = texts[i];
      t.age += dt;
      if (t.age >= FloatText.life) {
        texts.removeAt(i);
      } else {
        t.pos += const Offset(0, -70) * dt;
      }
      dirty = true;
    }
    if (dirty) notifyListeners();
  }
}

class EffectsOverlay extends StatefulWidget {
  const EffectsOverlay({super.key, required this.controller});

  final EffectsController controller;

  @override
  State<EffectsOverlay> createState() => _EffectsOverlayState();
}

class _EffectsOverlayState extends State<EffectsOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  bool get _active =>
      widget.controller.particles.isNotEmpty ||
      widget.controller.texts.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      if (dt > 0) widget.controller.tick(dt.clamp(0.0, 0.05));
    });
    widget.controller.addListener(_syncTicker);
  }

  /// The ticker only runs while there is something on screen to animate.
  void _syncTicker() {
    if (_active && !_ticker.isTicking) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!_active && _ticker.isTicking) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTicker);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _EffectsPainter(widget.controller),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  _EffectsPainter(this.fx) : super(repaint: fx);

  final EffectsController fx;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in fx.particles) {
      final t = 1 - p.age / p.life;
      paint.color = p.color.withValues(alpha: t.clamp(0.0, 1.0));
      final s = p.size * (0.4 + t * 0.6);
      canvas.drawRect(
        Rect.fromCenter(center: p.pos, width: s, height: s),
        paint,
      );
    }
    for (final t in fx.texts) {
      final k = t.age / FloatText.life;
      final opacity = (1 - k).clamp(0.0, 1.0);
      final builder = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: t.big ? 15 : 10,
            color: t.color.withValues(alpha: opacity),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: opacity * 0.8),
                offset: const Offset(1.5, 1.5),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      builder.paint(canvas, t.pos - Offset(builder.width / 2, 0));
    }
  }

  @override
  bool shouldRepaint(_EffectsPainter old) => true;
}
