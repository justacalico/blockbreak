import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../game/content.dart';
import '../game/controller.dart';
import '../theme.dart';
import 'background_painter.dart';
import 'block_painter.dart';
import 'effects.dart';
import 'pickaxe_painter.dart';

/// The main mining area: biome backdrop, the block being mined, the pickaxe
/// swing, particles, floating damage numbers and screen shake.
class MineView extends StatefulWidget {
  const MineView({super.key, required this.controller});

  final GameController controller;

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> with TickerProviderStateMixin {
  final _fx = EffectsController();
  late final AnimationController _swing;
  late final AnimationController _pop;
  late final AnimationController _shake;
  StreamSubscription<String>? _breakSub;
  Timer? _holdTimer;
  int _spawnSeed = 0;

  @override
  void initState() {
    super.initState();
    _swing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _breakSub = widget.controller.breaks.listen(_onBreak);
  }

  @override
  void dispose() {
    _breakSub?.cancel();
    _holdTimer?.cancel();
    _swing.dispose();
    _pop.dispose();
    _shake.dispose();
    _fx.dispose();
    super.dispose();
  }

  Offset get _blockCenter {
    final size = context.size ?? Size.zero;
    return Offset(size.width / 2, size.height * 0.46);
  }

  void _onBreak(String blockId) {
    if (!mounted) return;
    final size = context.size;
    if (size == null) return;
    final blockSize = min(size.width, size.height) * 0.52;
    _fx.burst(_blockCenter, blockSize / 2, blockDef(blockId).palette);
    _fx.label(
      _blockCenter - Offset(0, blockSize * 0.62),
      '+${1 + widget.controller.engine.dropBonus} ${blockDef(blockId).name}',
      BB.leaf,
    );
    setState(() => _spawnSeed++);
    _pop.forward(from: 0);
    _shake.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _swingAt(Offset pos) {
    _swing.forward(from: _swing.value > 0.55 ? 0 : _swing.value);
    final hitBlockId = widget.controller.state.currentBlockId;
    final r = widget.controller.tap();
    _fx.chips(pos, blockDef(hitBlockId).palette);
    _fx.label(
      pos - const Offset(0, 26),
      '+${fmt(r.picks)}',
      r.crit ? BB.crit : BB.cream,
      big: r.crit,
    );
    HapticFeedback.lightImpact();
  }

  void _onTapDown(TapDownDetails d) {
    _swingAt(d.localPosition);
    _holdTimer?.cancel();
    _holdTimer = Timer(
      const Duration(milliseconds: 380),
      _startRepeat,
    );
  }

  void _startRepeat() {
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(
      const Duration(milliseconds: 230),
      (_) => _swingAt(_blockCenter),
    );
  }

  void _endHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.controller.engine;
    final state = engine.state;
    final block = blockDef(state.currentBlockId);
    final hpFraction =
        (state.currentBlockHp / engine.blockMaxHp).clamp(0.0, 1.0);
    final pick = engine.pickaxe;

    return LayoutBuilder(
      builder: (context, constraints) {
        final blockSize =
            min(constraints.maxWidth, constraints.maxHeight) * 0.52;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: (_) => _endHold(),
          onTapCancel: _endHold,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: BiomeBackgroundPainter(biome: engine.biome),
                ),
              ),
              // The block, with shake and spawn-pop.
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final t = _shake.value;
                  final mag = sin(t * pi * 8) * 7 * (1 - t);
                  return Transform.translate(
                    offset: Offset(mag, mag * 0.4),
                    child: child,
                  );
                },
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: constraints.maxHeight * 0.08),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _pop,
                        curve: Curves.easeOutBack,
                      ),
                      child: SizedBox(
                        width: blockSize,
                        height: blockSize,
                        child: CustomPaint(
                          painter: BlockPainter(
                            block: block,
                            hpFraction: hpFraction,
                            seed: _spawnSeed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Pickaxe, rotating onto the block.
              Positioned(
                left: constraints.maxWidth / 2 - blockSize * 0.1,
                top: constraints.maxHeight * 0.46 -
                    blockSize * 0.85,
                child: AnimatedBuilder(
                  animation: _swing,
                  builder: (context, child) {
                    final angle = _swingAngle(_swing.value);
                    return Transform.rotate(
                      angle: angle,
                      origin: Offset(
                          blockSize * 0.28 * 0.3, blockSize * 0.7 * 0.8),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: blockSize * 0.7,
                    height: blockSize * 0.7,
                    child: CustomPaint(
                      painter: PickaxePainter(def: pick),
                    ),
                  ),
                ),
              ),
              // HP bar under the block.
              Positioned(
                left: constraints.maxWidth / 2 - blockSize * 0.55,
                right: constraints.maxWidth / 2 - blockSize * 0.55,
                top: constraints.maxHeight * 0.46 + blockSize * 0.62,
                child: _HpBar(
                  fraction: hpFraction,
                  label:
                      '${block.name}  ·  ${fmt(state.currentBlockHp)} / ${fmt(engine.blockMaxHp)}',
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: EffectsOverlay(controller: _fx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Rest angle -0.95 rad, strikes to +0.3 through the first 40% of the
  /// animation, eases back afterwards.
  static double _swingAngle(double t) {
    if (t < 0.4) {
      return -0.95 + 1.25 * Curves.easeIn.transform(t / 0.4);
    }
    return 0.3 - 1.25 * Curves.easeOut.transform((t - 0.4) / 0.6);
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({required this.fraction, required this.label});

  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: BB.ink.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: BB.edge),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [BB.gold, BB.crit],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: BB.statDim),
      ],
    );
  }
}
