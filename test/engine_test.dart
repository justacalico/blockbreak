import 'package:blockbreak/game/content.dart';
import 'package:blockbreak/game/engine.dart';
import 'package:blockbreak/game/models.dart';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

GameEngine makeEngine({ScriptedRandom? rng, GameState? state}) =>
    GameEngine(state ?? GameState(), rng: rng ?? ScriptedRandom());

void main() {
  group('content tables', () {
    test('every cost block exists and every biome has gear', () {
      for (final p in kPickaxes) {
        for (final id in p.cost.keys) {
          expect(() => blockDef(id), returnsNormally);
        }
      }
      for (final b in kBiomes) {
        expect(b.gear, isNotEmpty);
        for (final id in b.unlockCost.keys) {
          expect(() => blockDef(id), returnsNormally);
        }
        for (final g in b.gear) {
          for (final id in g.cost.keys) {
            expect(() => blockDef(id), returnsNormally);
          }
        }
      }
    });

    test('unlock costs only reference previous biome blocks', () {
      for (var i = 1; i < kBiomes.length; i++) {
        final prevBlocks = kBiomes[i - 1].blocks.map((b) => b.id).toSet();
        for (final id in kBiomes[i].unlockCost.keys) {
          expect(prevBlocks, contains(id),
              reason: '${kBiomes[i].id} requires $id');
        }
      }
    });

    test('lookups resolve and throw on unknown ids', () {
      expect(biomeDef('plains').name, 'Plains');
      expect(pickaxeDef('wood').free, isTrue);
      expect(biomeOfBlock('obsidian').id, 'lava_fields');
      expect(() => blockDef('nope'), throwsArgumentError);
      expect(() => biomeOfBlock('nope'), throwsArgumentError);
    });
  });

  group('mining', () {
    test('ensureBlock spawns a block for a fresh state', () {
      final e = makeEngine();
      e.ensureBlock();
      expect(e.state.currentBlockId, isNotEmpty);
      expect(e.state.currentBlockHp, greaterThan(0));
    });

    test('ensureBlock respawns when the saved block is dead or foreign', () {
      final e = makeEngine();
      e.ensureBlock();
      e.state.currentBlockHp = 0;
      e.ensureBlock();
      expect(e.state.currentBlockHp, greaterThan(0));
      e.state.currentBlockId = 'ancient_debris';
      e.ensureBlock();
      expect(
        e.biome.blocks.any((b) => b.id == e.state.currentBlockId),
        isTrue,
      );
    });

    test('tap damages block, earns picks, counts stats', () {
      final e = makeEngine();
      e.ensureBlock();
      final hpBefore = e.state.currentBlockHp;
      final r = e.tap();
      expect(r.damage, closeTo(e.swingDamage, 1e-9));
      expect(e.state.currentBlockHp, lessThan(hpBefore));
      expect(e.state.picks, greaterThan(0));
      expect(e.state.stats.totalTaps, 1);
    });

    test('critical taps multiply damage and count', () {
      final rng = ScriptedRandom(doubleValue: 0.0);
      final e = makeEngine(rng: rng);
      e.ensureBlock();
      final r = e.tap();
      expect(r.crit, isTrue);
      expect(r.damage, closeTo(e.swingDamage * kCritMult, 1e-6));
      expect(e.state.stats.totalCrits, 1);
    });

    test('breaking a block drops loot and spawns the next one', () {
      final e = makeEngine();
      e.ensureBlock();
      e.state.currentBlockHp = 1;
      final broken = e.state.currentBlockId;
      final r = e.tap();
      expect(r.broke, isTrue);
      expect(r.brokenBlockId, broken);
      expect(e.state.inventory[broken], greaterThanOrEqualTo(1));
      expect(e.state.stats.totalBlocks, 1);
      expect(e.state.currentBlockId, isNotEmpty);
      expect(e.state.currentBlockHp, greaterThan(0));
    });

    test('tick adds picks from pps and auto-breaks blocks', () {
      final state = GameState();
      state.gearOwned.add('hopper');
      final e = makeEngine(state: state);
      e.ensureBlock();
      final r = e.tick(10);
      expect(r.picks, closeTo(e.pps * 10, 1e-6));
      expect(e.state.picks, greaterThan(0));
    });

    test('tick breaks multiple blocks when auto damage is huge', () {
      final state = GameState();
      state.gearOwned.add('dragon_perch');
      final e = makeEngine(state: state);
      e.ensureBlock();
      final r = e.tick(60);
      expect(r.broken, isNotEmpty);
      expect(e.state.stats.totalBlocks, r.broken.length);
    });

    test('tick with zero pps is a no-op', () {
      final e = makeEngine();
      e.ensureBlock();
      final r = e.tick(10);
      expect(r.picks, 0);
      expect(r.broken, isEmpty);
    });

    test('tick ignores non-positive and oversized deltas', () {
      final e = makeEngine();
      e.ensureBlock();
      expect(e.tick(0).picks, 0);
      expect(e.tick(-5).picks, 0);
    });

    test('effectivePps includes pick multipliers', () {
      final state = GameState()..gearOwned.add('hopper');
      state.biomesUnlocked.add('caves'); // Torchlight: +25% picks
      final e = makeEngine(state: state);
      expect(e.pps, closeTo(3, 1e-9));
      expect(e.effectivePps, closeTo(3.75, 1e-9));
    });
  });

  group('economy', () {
    test('buyPickaxe pays blocks, owns and equips', () {
      final e = makeEngine();
      e.state.inventory.addAll({'dirt': 100, 'clay': 50});
      expect(e.buyPickaxe('stone'), isTrue);
      expect(e.state.pickaxes['stone']!.owned, isTrue);
      expect(e.state.equippedPickaxe, 'stone');
      expect(e.state.inventory['dirt'], 40);
    });

    test('buyPickaxe fails without blocks or when owned', () {
      final e = makeEngine();
      expect(e.buyPickaxe('stone'), isFalse);
      e.state.pickaxes['iron'] = PickaxeState(owned: true);
      e.state.inventory.addAll({'sandstone': 500, 'terracotta': 500});
      expect(e.buyPickaxe('iron'), isFalse);
    });

    test('equip requires ownership', () {
      final e = makeEngine();
      expect(e.equipPickaxe('diamond'), isFalse);
      e.state.pickaxes['diamond'] = PickaxeState(owned: true);
      expect(e.equipPickaxe('diamond'), isTrue);
      expect(e.state.equippedPickaxe, 'diamond');
    });

    test('upgrade consumes scaled cost and respects max level', () {
      final e = makeEngine();
      e.state.pickaxes['stone'] = PickaxeState(owned: true);
      e.state.inventory.addAll({'dirt': 10000, 'clay': 10000});
      expect(e.upgradeCost('stone')['dirt'], 60);
      expect(e.upgradePickaxe('stone'), isTrue);
      expect(e.state.pickaxes['stone']!.level, 1);
      expect(e.upgradeCost('stone')['dirt'], 96);
      // level 1 == maxLevel at prestige 0, so further upgrades fail
      expect(e.upgradePickaxe('stone'), isFalse);
      e.state.prestigeCount = 2;
      expect(e.upgradePickaxe('stone'), isTrue);
    });

    test('upgrade fails when unowned or broke', () {
      final e = makeEngine();
      expect(e.upgradePickaxe('stone'), isFalse);
      e.state.pickaxes['stone'] = PickaxeState(owned: true);
      expect(e.upgradePickaxe('stone'), isFalse);
    });

    test('strength scales with level', () {
      final e = makeEngine();
      e.state.pickaxes['stone'] = PickaxeState(owned: true, level: 2);
      expect(e.pickaxeStrength('stone'), closeTo(6 * 1.6, 1e-9));
    });

    test('buyGear adds pps once', () {
      final e = makeEngine();
      e.state.inventory['dirt'] = 100;
      expect(e.buyGear('hopper'), isTrue);
      expect(e.pps, closeTo(3, 1e-9));
      expect(e.buyGear('hopper'), isFalse);
      expect(e.buyGear('nonexistent'), isFalse);
      expect(e.buyGear('furnace_cart'), isFalse);
    });

    test('buyGear refuses gear from locked biomes', () {
      final e = makeEngine();
      e.state.inventory['prismarine'] = 999;
      expect(e.buyGear('tide_engine'), isFalse);
      e.state.biomesUnlocked.addAll(kBiomes.map((b) => b.id));
      expect(e.buyGear('tide_engine'), isTrue);
    });

    test('free pickaxe cannot be upgraded', () {
      final e = makeEngine();
      e.state.prestigeCount = 5;
      expect(e.upgradePickaxe('wood'), isFalse);
    });

    test('unlockBiome enforces order and cost', () {
      final e = makeEngine();
      expect(e.unlockBiome('tundra'), isFalse);
      expect(e.unlockBiome('desert'), isFalse);
      e.state.inventory.addAll({'dirt': 100, 'clay': 50});
      expect(e.unlockBiome('desert'), isTrue);
      expect(e.unlockBiome('desert'), isFalse);
      expect(e.nextBiomeId, 'tundra');
    });

    test('travelTo only moves between unlocked biomes', () {
      final e = makeEngine();
      expect(e.travelTo('desert'), isFalse);
      e.state.biomesUnlocked.add('desert');
      expect(e.travelTo('desert'), isTrue);
      expect(e.state.currentBiome, 'desert');
      expect(e.travelTo('desert'), isTrue);
    });

    test('abilities stack from unlocked biomes', () {
      final e = makeEngine();
      expect(e.dmgMul, 1);
      e.state.biomesUnlocked.addAll(['desert', 'tundra']);
      expect(e.dmgMul, closeTo(1.15, 1e-9));
      expect(e.critChance, closeTo(0.05 + 0.05, 1e-9));
      e.state.biomesUnlocked.add('the_end');
      expect(e.dropBonus, 1);
    });
  });

  group('chests', () {
    test('small chest costs picks and pays out blocks', () {
      final rng = ScriptedRandom(doubleValue: 0.99);
      final e = makeEngine(rng: rng);
      e.ensureBlock();
      e.state.picks = 100000;
      final before = e.state.blockCount;
      final r = e.openChest(ChestKind.small);
      expect(r, isNotNull);
      expect(r!.blocks.values.fold(0.0, (a, b) => a + b),
          greaterThanOrEqualTo(3));
      expect(e.state.blockCount, greaterThan(before));
      expect(e.state.smallChestsOpened, 1);
      expect(e.openChest(ChestKind.small)!.blocks, isNotEmpty);
      expect(e.smallChestCost, greaterThan(500));
    });

    test('small chest can award pickaxe and runic', () {
      // doubleValue 0 => pickaxe roll hits, runic roll hits.
      final rng = ScriptedRandom(doubleValue: 0.0);
      final e = makeEngine(rng: rng);
      e.state.picks = 100000;
      final r = e.openChest(ChestKind.small)!;
      expect(r.pickaxeId, isNotNull);
      expect(r.runic, greaterThan(0));
      expect(e.state.pickaxes[r.pickaxeId]!.owned, isTrue);
    });

    test('chest refuses without funds', () {
      final e = makeEngine();
      expect(e.openChest(ChestKind.small), isNull);
      expect(e.openChest(ChestKind.large), isNull);
      e.state.runic = 100;
      final r = e.openChest(ChestKind.large);
      expect(r, isNotNull);
      expect(e.state.runic, lessThan(100));
      expect(r!.blocks.values.fold(0.0, (a, b) => a + b),
          greaterThanOrEqualTo(10));
    });

    test('large chests bias toward rare blocks', () {
      var rareSmall = 0, rareLarge = 0, totalSmall = 0, totalLarge = 0;
      // Pumpkin is the rare Plains block (weight 10 of 100).
      for (var i = 0; i < 60; i++) {
        final realSmall = GameEngine(GameState()..picks = 1e12,
            rng: Random(1000 + i));
        final rs = realSmall.openChest(ChestKind.small)!;
        totalSmall += rs.blocks.values.fold(0, (a, b) => a + b.toInt());
        rareSmall += (rs.blocks['pumpkin'] ?? 0).toInt();
        final realLarge = GameEngine(GameState()..runic = 1e9,
            rng: Random(5000 + i));
        final rl = realLarge.openChest(ChestKind.large)!;
        totalLarge += rl.blocks.values.fold(0, (a, b) => a + b.toInt());
        rareLarge += (rl.blocks['pumpkin'] ?? 0).toInt();
      }
      expect(rareLarge / totalLarge, greaterThan(rareSmall / totalSmall));
    });

    test('chest with all pickaxes owned skips the pickaxe roll', () {
      final rng = ScriptedRandom(doubleValue: 0.0);
      final state = GameState();
      for (final p in kPickaxes) {
        state.pickaxes[p.id] = PickaxeState(owned: true);
      }
      final e = makeEngine(state: state, rng: rng);
      e.state.picks = 100000;
      final r = e.openChest(ChestKind.small)!;
      expect(r.pickaxeId, isNull);
      expect(r.isEmpty, isFalse);
    });
  });

  group('prestige', () {
    test('requires the end biome and endstone pickaxe', () {
      final e = makeEngine();
      expect(e.canPrestige, isFalse);
      expect(e.prestige(), -1);
      e.state.currentBiome = 'the_end';
      expect(e.canPrestige, isFalse);
      e.state.pickaxes['endstone'] = PickaxeState(owned: true);
      expect(e.canPrestige, isTrue);
    });

    test('prestige resets run and grants runic', () {
      final e = makeEngine();
      e.state.currentBiome = 'the_end';
      e.state.biomesUnlocked.addAll(kBiomes.map((b) => b.id));
      e.state.pickaxes['endstone'] = PickaxeState(owned: true);
      e.state.inventory['dirt'] = 500;
      e.state.picks = 9999;
      e.state.gearOwned.add('hopper');
      e.state.blocksThisRun = 1000;
      e.state.smallChestsOpened = 7;
      final gained = e.prestige();
      expect(gained, 5 + 25);
      expect(e.state.runic, gained);
      expect(e.state.prestigeCount, 1);
      expect(e.state.currentBiome, 'plains');
      expect(e.state.biomesUnlocked, {'plains'});
      expect(e.state.inventory, isEmpty);
      expect(e.state.gearOwned, isEmpty);
      expect(e.state.picks, 0);
      expect(e.state.smallChestsOpened, 0);
      expect(e.state.blocksThisRun, 0);
      expect(e.state.currentBlockHp, greaterThan(0));
      expect(e.maxPickaxeLevel, 2);
    });

    test('prestige runic is capped', () {
      final e = makeEngine();
      e.state.blocksThisRun = 99999999;
      expect(e.prestigeRunic, kPrestigeRunicCap);
    });
  });

  group('offline', () {
    test('applies capped picks and block drops', () {
      final state = GameState();
      state.gearOwned.add('hopper');
      final e = makeEngine(state: state);
      e.ensureBlock();
      final r = e.applyOffline(3600 * 24);
      expect(r.seconds, kOfflineCapSeconds);
      expect(r.picks, closeTo(e.pps * kOfflineCapSeconds, 1e-3));
      expect(r.isEmpty, isFalse);
    });

    test('empty idle yields empty report', () {
      final e = makeEngine();
      e.ensureBlock();
      final r = e.applyOffline(100);
      expect(r.picks, 0);
    });

    test('negative elapsed clamps to zero', () {
      final e = makeEngine();
      e.ensureBlock();
      final r = e.applyOffline(-60);
      expect(r.seconds, 0);
      expect(r.picks, 0);
    });

    test('report constructors default their collections', () {
      final r = OfflineReport(seconds: 0, picks: 0);
      expect(r.blocks, isEmpty);
      expect(r.isEmpty, isTrue);
      final chest = ChestReward();
      expect(chest.blocks, isEmpty);
      expect(chest.isEmpty, isTrue);
    });
  });
}
