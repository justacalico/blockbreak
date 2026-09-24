import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'engine.dart';
import 'models.dart';
import 'save.dart';

/// Wraps [GameEngine] with a game loop, autosave and event streams for the
/// UI layer (swing results, block breaks, offline report).
class GameController extends ChangeNotifier {
  GameController({
    required this.engine,
    required this.store,
    Duration? tickInterval,
    Duration? saveInterval,
  })  : _tickInterval =
            tickInterval ?? const Duration(milliseconds: 100),
        _saveInterval = saveInterval ?? const Duration(seconds: 5);

  final GameEngine engine;
  final SaveStore store;
  final Duration _tickInterval;
  final Duration _saveInterval;

  Timer? _ticker;
  Timer? _saver;
  DateTime _lastTick = DateTime.now();

  final _swings = StreamController<SwingResult>.broadcast();
  final _breaks = StreamController<String>.broadcast();
  final _chests = StreamController<ChestReward>.broadcast();

  Stream<SwingResult> get swings => _swings.stream;
  Stream<String> get breaks => _breaks.stream;
  Stream<ChestReward> get chests => _chests.stream;

  OfflineReport? pendingOfflineReport;

  GameState get state => engine.state;

  void start() {
    _lastTick = DateTime.now();
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
    _saver = Timer.periodic(_saveInterval, (_) => save());
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;
    final result = engine.tick(dt);
    for (final id in result.broken) {
      _breaks.add(id);
    }
    notifyListeners();
  }

  /// Manual swing. Returns the result so callers can animate.
  SwingResult tap() {
    final r = engine.tap();
    _swings.add(r);
    if (r.broke && r.brokenBlockId != null) {
      _breaks.add(r.brokenBlockId!);
    }
    notifyListeners();
    return r;
  }

  void buyPickaxe(String id) {
    if (engine.buyPickaxe(id)) notifyListeners();
  }

  void upgradePickaxe(String id) {
    if (engine.upgradePickaxe(id)) notifyListeners();
  }

  void equipPickaxe(String id) {
    if (engine.equipPickaxe(id)) notifyListeners();
  }

  void buyGear(String id) {
    if (engine.buyGear(id)) notifyListeners();
  }

  void unlockBiome(String id) {
    if (engine.unlockBiome(id)) notifyListeners();
  }

  void travelTo(String id) {
    if (engine.travelTo(id)) notifyListeners();
  }

  ChestReward? openChest(ChestKind kind) {
    final reward = engine.openChest(kind);
    if (reward != null) {
      _chests.add(reward);
      notifyListeners();
    }
    return reward;
  }

  double prestige() {
    final gained = engine.prestige();
    if (gained >= 0) notifyListeners();
    return gained;
  }

  void applyOfflineProgress(int elapsedSeconds) {
    final report = engine.applyOffline(elapsedSeconds);
    if (!report.isEmpty) {
      pendingOfflineReport = report;
      notifyListeners();
    }
  }

  void dismissOfflineReport() {
    pendingOfflineReport = null;
    notifyListeners();
  }

  /// Wipe all progress back to a fresh game and persist it.
  void resetSave() {
    final s = engine.state;
    s.picks = 0;
    s.runic = 0;
    s.inventory.clear();
    s.pickaxes
      ..clear()
      ..['wood'] = PickaxeState(owned: true);
    s.equippedPickaxe = 'wood';
    s.biomesUnlocked
      ..clear()
      ..add('plains');
    s.currentBiome = 'plains';
    s.gearOwned.clear();
    s.smallChestsOpened = 0;
    s.prestigeCount = 0;
    s.stats = Stats();
    engine.ensureBlock();
    notifyListeners();
    save();
  }

  Future<void> save() => store.save(engine.state);

  @override
  void dispose() {
    _ticker?.cancel();
    _saver?.cancel();
    _swings.close();
    _breaks.close();
    _chests.close();
    super.dispose();
  }
}

/// Loads a saved game (or a fresh one), applies offline progress, and
/// returns a ready-to-start controller.
Future<GameController> loadGame(
  SaveStore store, {
  Random? rng,
  int? nowMillis,
}) async {
  final loaded = await store.load();
  final state = loaded ?? GameState();
  final engine = GameEngine(state, rng: rng)..ensureBlock();
  final controller = GameController(engine: engine, store: store);
  if (loaded != null && loaded.savedAt > 0) {
    final now = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    final elapsed = (now - loaded.savedAt) ~/ 1000;
    if (elapsed > 30) {
      controller.applyOfflineProgress(elapsed);
    }
  }
  return controller;
}
