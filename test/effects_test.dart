import 'package:blockbreak/ui/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('burst, chips and label populate and decay', () {
    final fx = EffectsController(rng: ScriptedRandom());
    fx.burst(Offset.zero, 50, const [0xFF112233]);
    expect(fx.particles.length, 18);
    fx.chips(Offset.zero, const [0xFF112233]);
    expect(fx.particles.length, 22);
    fx.label(Offset.zero, '+5', const Color(0xFFFFFFFF), big: true);
    expect(fx.texts.single.big, isTrue);

    // Simulate ~2s of frames at 50ms steps.
    for (var i = 0; i < 40; i++) {
      fx.tick(0.05);
    }
    expect(fx.particles, isEmpty);
    expect(fx.texts, isEmpty);
  });

  test('burst is capped when particles flood', () {
    final fx = EffectsController(rng: ScriptedRandom());
    for (var i = 0; i < 20; i++) {
      fx.burst(Offset.zero, 10, const [0xFF112233]);
    }
    expect(fx.particles.length, greaterThan(300));
    final before = fx.particles.length;
    fx.burst(Offset.zero, 10, const [0xFF112233]);
    expect(fx.particles.length, before);
    fx.dispose();
  });
}
