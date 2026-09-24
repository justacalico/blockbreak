import 'package:blockbreak/game/controller.dart';
import 'package:blockbreak/game/engine.dart';
import 'package:blockbreak/game/models.dart';
import 'package:blockbreak/game/save.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

GameController makeController({GameState? state, ScriptedRandom? rng}) =>
    GameController(
      engine: GameEngine(state ?? GameState(), rng: rng),
      store: MemoryStore(),
      tickInterval: const Duration(milliseconds: 50),
    );

void main() {
  test('tap notifies and emits swing + break events', () async {
    final c = makeController();
    c.engine.ensureBlock();
    final breaks = <String>[];
    final sub = c.breaks.listen(breaks.add);
    addTearDown(() {
      sub.cancel();
      c.dispose();
    });

    var notified = 0;
    c.addListener(() => notified++);

    final r = c.tap();
    expect(r.damage, greaterThan(0));
    expect(notified, 1);

    c.state.currentBlockHp = 1;
    final broken = c.state.currentBlockId;
    c.tap();
    await Future<void>.delayed(Duration.zero);
    expect(breaks, contains(broken));
  });

  test('start runs the ticker which accrues pps', () async {
    final state = GameState()..gearOwned.add('hopper');
    final c = makeController(state: state);
    c.engine.ensureBlock();
    c.start();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    c.dispose();
    expect(c.state.picks, greaterThan(0));
  });

  test('ticker emits break events when auto damage breaks blocks',
      () async {
    final state = GameState()..gearOwned.add('dragon_perch');
    final c = makeController(state: state);
    c.engine.ensureBlock();
    final broken = <String>[];
    final sub = c.breaks.listen(broken.add);
    c.start();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    sub.cancel();
    c.dispose();
    expect(broken, isNotEmpty);
  });

  test('buy/equip/upgrade/travel/unlock delegate to engine', () {
    final c = makeController();
    c.engine.ensureBlock();
    var notified = 0;
    c.addListener(() => notified++);
    addTearDown(c.dispose);

    c.buyPickaxe('stone');
    expect(notified, 0);
    c.state.inventory.addAll({'dirt': 1000, 'clay': 1000});
    c.buyPickaxe('stone');
    expect(notified, 1);
    expect(c.state.equippedPickaxe, 'stone');

    c.equipPickaxe('wood');
    expect(c.state.equippedPickaxe, 'wood');
    c.equipPickaxe('diamond');
    expect(c.state.equippedPickaxe, 'wood');

    c.state.prestigeCount = 1;
    c.upgradePickaxe('stone');
    expect(c.state.pickaxes['stone']!.level, 1);
    // Wood is free and has no upgrade path.
    c.upgradePickaxe('wood');
    expect(c.state.pickaxes['wood']!.level, 0);
    // A failed upgrade must not invent a phantom state entry.
    c.upgradePickaxe('diamond');
    expect(c.state.pickaxes.containsKey('diamond'), isFalse);

    c.unlockBiome('tundra');
    expect(c.state.biomesUnlocked.contains('tundra'), isFalse);
    c.state.inventory.addAll({'dirt': 100, 'clay': 50});
    c.unlockBiome('desert');
    expect(c.state.biomesUnlocked.contains('desert'), isTrue);

    c.travelTo('the_end');
    expect(c.state.currentBiome, 'plains');
    c.travelTo('desert');
    expect(c.state.currentBiome, 'desert');

    c.state.inventory['dirt'] = 100;
    c.buyGear('hopper');
    expect(c.state.gearOwned, contains('hopper'));
    c.buyGear('furnace_cart');
    expect(c.state.gearOwned.contains('furnace_cart'), isFalse);
  });

  test('openChest emits reward event and notifies', () async {
    final c = makeController();
    c.engine.ensureBlock();
    c.state.picks = 100000;
    addTearDown(c.dispose);
    var notified = 0;
    c.addListener(() => notified++);
    final r = c.openChest(ChestKind.small);
    expect(r, isNotNull);
    expect(r!.blocks, isNotEmpty);
    expect(notified, 1);
    expect(c.openChest(ChestKind.large), isNull);
  });

  test('prestige notifies only on success', () {
    final c = makeController();
    c.engine.ensureBlock();
    var notified = 0;
    c.addListener(() => notified++);
    addTearDown(c.dispose);
    expect(c.prestige(), -1);
    expect(notified, 0);
    c.state.currentBiome = 'the_end';
    c.state.pickaxes['endstone'] = PickaxeState(owned: true);
    expect(c.prestige(), greaterThan(0));
    expect(notified, 1);
  });

  test('applyOfflineProgress stores a dismissible report', () {
    final c = makeController();
    c.engine.ensureBlock();
    c.state.gearOwned.add('hopper');
    c.applyOfflineProgress(600);
    expect(c.pendingOfflineReport, isNotNull);
    c.dismissOfflineReport();
    expect(c.pendingOfflineReport, isNull);
    c.dispose();
  });

  test('resetSave wipes progress and persists', () async {
    final store = MemoryStore();
    final state = GameState()
      ..picks = 5000
      ..inventory['dirt'] = 99
      ..biomesUnlocked.add('desert');
    final c = GameController(
      engine: GameEngine(state),
      store: store,
    );
    c.resetSave();
    expect(c.state.picks, 0);
    expect(c.state.inventory, isEmpty);
    expect(c.state.biomesUnlocked, {'plains'});
    expect(c.state.pickaxes.keys, ['wood']);
    final saved = await store.load();
    expect(saved!.picks, 0);
    c.dispose();
  });

  group('loadGame', () {
    test('creates a fresh state with a live block', () async {
      final c = await loadGame(MemoryStore());
      addTearDown(c.dispose);
      expect(c.state.currentBlockHp, greaterThan(0));
      expect(c.pendingOfflineReport, isNull);
    });

    test('restores a saved state', () async {
      final store = MemoryStore();
      final s = GameState()..picks = 321;
      await store.save(s);
      // Freshly saved: elapsed ~0, below the offline threshold.
      final c = await loadGame(store, nowMillis: s.savedAt + 5000);
      addTearDown(c.dispose);
      expect(c.state.picks, 321);
      expect(c.pendingOfflineReport, isNull);
      // No nowMillis: falls back to the wall clock, still under 30s.
      final c2 = await loadGame(store);
      addTearDown(c2.dispose);
      expect(c2.pendingOfflineReport, isNull);
    });

    test('applies offline earnings for stale saves', () async {
      final store = MemoryStore();
      final s = GameState()..gearOwned.add('hopper');
      await store.save(s);
      final c = await loadGame(
        store,
        nowMillis: s.savedAt + 3600 * 1000,
      );
      addTearDown(c.dispose);
      expect(c.pendingOfflineReport, isNotNull);
      expect(c.pendingOfflineReport!.picks, greaterThan(0));
    });
  });
}
