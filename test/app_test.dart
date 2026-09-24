import 'package:blockbreak/app.dart';
import 'package:blockbreak/game/content.dart';
import 'package:blockbreak/game/controller.dart';
import 'package:blockbreak/game/engine.dart';
import 'package:blockbreak/ui/dialogs.dart';
import 'package:blockbreak/game/models.dart';
import 'package:blockbreak/game/save.dart';
import 'package:blockbreak/main.dart' as app;
import 'package:blockbreak/ui/mine_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<GameController> pumpApp(
  WidgetTester tester, {
  GameState? state,
  ScriptedRandom? rng,
}) async {
  final c = GameController(
    engine: GameEngine(state ?? GameState(), rng: rng ?? ScriptedRandom())
      ..ensureBlock(),
    store: MemoryStore(),
  );
  await tester.pumpWidget(BlockBreakApp(controller: c));
  await tester.pump();
  return c;
}

/// The game loop notifies every 100ms, so pumpAndSettle never returns.
/// Pump a fixed number of frames instead.
Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openSheet(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await settle(tester);
}

void main() {
  testWidgets('main() boots the real app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await app.main();
      await tester.pump();
    });
    expect(find.byType(BlockBreakApp), findsOneWidget);
  });

  testWidgets('HUD shows biome, picks and nav', (tester) async {
    await pumpApp(tester);
    expect(find.text('PLAINS'), findsOneWidget);
    expect(find.text('Biomes'), findsOneWidget);
    expect(find.text('Pickaxes'), findsOneWidget);
    expect(find.text('Gear'), findsOneWidget);
    expect(find.text('Chests'), findsOneWidget);
    expect(find.text('Bag'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('tapping the block swings the pickaxe and earns picks',
      (tester) async {
    final c = await pumpApp(tester);
    expect(c.state.picks, 0);
    await tester.tap(find.byType(MineView));
    await tester.pump();
    expect(c.state.picks, greaterThan(0));
    expect(c.state.stats.totalTaps, 1);
    // Mid-swing frame, then let every effect decay so the ticker stops.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester, 30);
  });

  testWidgets('holding the block auto-swings', (tester) async {
    final c = await pumpApp(tester);
    final g = await tester.startGesture(
        tester.getCenter(find.byType(MineView)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 800));
    await g.up();
    await tester.pump();
    expect(c.state.stats.totalTaps, greaterThan(1));
  });

  testWidgets('breaking a block pops the next one and shakes',
      (tester) async {
    final c = await pumpApp(tester);
    c.state.currentBlockHp = 1;
    await tester.tap(find.byType(MineView));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.state.stats.totalBlocks, 1);
    await settle(tester, 30);
  });

  testWidgets('renders every biome backdrop and block texture',
      (tester) async {
    final c = await pumpApp(tester);
    for (final b in kBiomes) {
      c.state.biomesUnlocked.add(b.id);
      c.engine.travelTo(b.id);
      c.notifyListeners();
      await tester.pump();
    }
    // Cycle through blocks to paint every texture kind.
    for (final b in kBiomes) {
      for (final blk in b.blocks) {
        c.state.currentBlockId = blk.id;
        c.state.currentBlockHp = blk.hp;
        c.notifyListeners();
        await tester.pump();
      }
    }
    c.engine.travelTo('plains');
    c.notifyListeners();
    await settle(tester);
  });

  testWidgets('biomes sheet unlocks and travels', (tester) async {
    final c = await pumpApp(tester);
    await openSheet(tester, 'Biomes');
    expect(find.text('Desert'), findsOneWidget);
    expect(find.text('Unknown land'), findsWidgets);
    expect(find.text('HERE'), findsOneWidget);

    c.state.inventory.addAll({'dirt': 100, 'clay': 50});
    c.notifyListeners();
    await tester.pump();
    await tester.tap(find.text('UNLOCK'));
    await settle(tester);
    expect(c.state.biomesUnlocked, contains('desert'));

    await openSheet(tester, 'Biomes');
    await tester.tap(find.text('GO').first);
    await settle(tester);
    expect(c.state.currentBiome, 'desert');
    expect(find.text('DESERT'), findsOneWidget);
  });

  testWidgets('prestige card resets the run', (tester) async {
    final state = GameState()
      ..biomesUnlocked.addAll(kBiomes.map((b) => b.id))
      ..currentBiome = 'the_end'
      ..inventory['dirt'] = 500;
    state.pickaxes['endstone'] = PickaxeState(owned: true);
    final c = await pumpApp(tester, state: state);

    await openSheet(tester, 'Biomes');
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await settle(tester, 4);
    await tester.tap(find.text('PRESTIGE'));
    await settle(tester);
    expect(find.text('Prestige?'), findsOneWidget);
    await tester.tap(find.text('DO IT'));
    await settle(tester);
    expect(c.state.prestigeCount, 1);
    expect(c.state.runic, greaterThan(0));
    expect(c.state.currentBiome, 'plains');
  });

  testWidgets('prestige confirm can be cancelled', (tester) async {
    final state = GameState()
      ..biomesUnlocked.addAll(kBiomes.map((b) => b.id))
      ..currentBiome = 'the_end';
    state.pickaxes['endstone'] = PickaxeState(owned: true);
    final c = await pumpApp(tester, state: state);
    await openSheet(tester, 'Biomes');
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await settle(tester, 4);
    await tester.tap(find.text('PRESTIGE'));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(c.state.prestigeCount, 0);
  });

  testWidgets('pickaxes sheet buys, equips and upgrades',
      (tester) async {
    final c = await pumpApp(tester);
    c.state.inventory.addAll({'dirt': 10000, 'clay': 10000});
    c.state.prestigeCount = 1;
    await openSheet(tester, 'Pickaxes');
    expect(find.text('Wooden Pickaxe'), findsOneWidget);
    expect(find.text('EQUIPPED'), findsOneWidget);

    await tester.tap(find.text('BUY').first);
    await tester.pump();
    expect(c.state.pickaxes['stone']!.owned, isTrue);
    expect(c.state.equippedPickaxe, 'stone');

    await tester.pump();
    // The free wooden pickaxe has no upgrade path; stone's is the only one.
    await tester.tap(find.text('UPGRADE').last);
    await tester.pump();
    expect(c.state.pickaxes['stone']!.level, 1);
    expect(c.state.pickaxes['wood']!.level, 0);

    // Equip the wooden pickaxe back; it is the first tile.
    await tester.tap(find.text('EQUIP'));
    await tester.pump();
    expect(c.state.equippedPickaxe, 'wood');
    await settle(tester);
  });

  testWidgets('gear sheet buys pps gear', (tester) async {
    final c = await pumpApp(tester);
    c.state.inventory['dirt'] = 100;
    c.notifyListeners();
    await openSheet(tester, 'Gear');
    expect(find.text('Hopper'), findsOneWidget);
    await tester.tap(find.text('BUY').first);
    await tester.pump();
    expect(c.state.gearOwned, contains('hopper'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    await settle(tester);
  });

  testWidgets('chests sheet opens a small chest and shows loot',
      (tester) async {
    final c = await pumpApp(tester);
    c.state.picks = 100000;
    c.notifyListeners();
    await openSheet(tester, 'Chests');
    expect(find.text('Small Chest'), findsOneWidget);
    expect(find.text('Large Chest'), findsOneWidget);
    await tester.tap(find.text('OPEN').first);
    await settle(tester);
    expect(find.text('Loot'), findsOneWidget);
    await tester.tap(find.text('NICE'));
    await settle(tester);
    expect(c.state.stats.chestsOpened, 1);
  });

  testWidgets('large chest spends runic', (tester) async {
    final c =
        await pumpApp(tester, rng: ScriptedRandom(doubleValue: 0.0));
    c.state.runic = 100;
    c.notifyListeners();
    await openSheet(tester, 'Chests');
    await tester.tap(find.text('OPEN').last);
    await settle(tester);
    expect(find.text('Loot'), findsOneWidget);
    await tester.tap(find.text('NICE'));
    await settle(tester);
    expect(c.state.runic, lessThan(100));
  });

  testWidgets('bag lists inventory', (tester) async {
    final c = await pumpApp(tester);
    await openSheet(tester, 'Bag');
    expect(find.text('Empty. Start swinging.'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    c.state.inventory['dirt'] = 42;
    c.notifyListeners();
    await openSheet(tester, 'Bag');
    expect(find.text('Dirt'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('stats sheet shows numbers and resets the save',
      (tester) async {
    final c = await pumpApp(tester);
    c.state.stats.totalTaps = 123;
    c.notifyListeners();
    await tester.tap(find.byIcon(Icons.bar_chart));
    await settle(tester);
    expect(find.text('Swings'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('Unlock new biomes to earn abilities.'),
        findsOneWidget);

    await tester.tap(find.text('RESET SAVE'));
    await settle(tester);
    expect(find.text('Reset save?'), findsOneWidget);
    await tester.tap(find.text('ERASE'));
    await settle(tester);
    expect(c.state.stats.totalTaps, 0);
  });

  testWidgets('abilities list shows unlocked powers', (tester) async {
    final state = GameState()..biomesUnlocked.add('desert');
    await pumpApp(tester, state: state);
    await tester.tap(find.byIcon(Icons.bar_chart));
    await settle(tester);
    expect(find.text('Sharpened Edge'), findsOneWidget);
    expect(find.text('+15% swing damage'), findsOneWidget);
  });

  testWidgets('offline report appears and dismisses', (tester) async {
    final c = GameController(
      engine: GameEngine(GameState()..gearOwned.add('hopper'))
        ..ensureBlock(),
      store: MemoryStore(),
    );
    c.applyOfflineProgress(600);
    await tester.pumpWidget(BlockBreakApp(controller: c));
    await tester.pump();
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('COLLECT'));
    await settle(tester);
    expect(c.pendingOfflineReport, isNull);
  });

  testWidgets('empty chest dialog shows a fallback', (tester) async {
    await pumpApp(tester);
    final ctx = tester.element(find.byType(Scaffold));
    showChestReward(ctx, ChestReward());
    await settle(tester);
    expect(find.text('Nothing this time.'), findsOneWidget);
    await tester.tap(find.text('NICE'));
    await settle(tester);
  });

  testWidgets('offline report with no block drops', (tester) async {
    final c = GameController(
      engine: GameEngine(GameState()..gearOwned.add('hopper'))
        ..ensureBlock(),
      store: MemoryStore(),
    );
    // 30s at 0.15 dmg/sec never finishes even a Dirt block.
    c.applyOfflineProgress(30);
    await tester.pumpWidget(BlockBreakApp(controller: c));
    await tester.pump();
    await tester.pump();
    expect(find.text('No blocks auto-mined.'), findsOneWidget);
    await tester.tap(find.text('COLLECT'));
    await settle(tester);
  });

  testWidgets('multi-touch keeps mining until all fingers lift',
      (tester) async {
    final c = await pumpApp(tester);
    final center = tester.getCenter(find.byType(MineView));
    final g1 = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 100));
    final g2 = await tester
        .startGesture(center - const Offset(50, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await g1.up();
    // First finger lifted, second still down: auto-swing keeps going.
    await tester.pump(const Duration(milliseconds: 700));
    await g2.up();
    await tester.pump();
    expect(c.state.stats.totalTaps, greaterThan(3));
    await settle(tester, 5);
  });

  testWidgets('auto-breaks from gear drive bursts and throttled haptics',
      (tester) async {
    final c = await pumpApp(tester,
        state: GameState()..gearOwned.add('dragon_perch'));
    await settle(tester, 6);
    expect(c.state.stats.totalBlocks, greaterThan(0));
  });

  testWidgets('runic chip shows only when runic held', (tester) async {
    final c = await pumpApp(tester);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    c.state.runic = 5;
    c.notifyListeners();
    await tester.pump();
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
  });

  testWidgets('app saves on pause lifecycle', (tester) async {
    final store = MemoryStore();
    final c = GameController(
      engine: GameEngine(GameState()..picks = 55)..ensureBlock(),
      store: store,
    );
    await tester.pumpWidget(BlockBreakApp(controller: c));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.detached);
    final saved = await store.load();
    expect(saved!.picks, 55);
  });
}
