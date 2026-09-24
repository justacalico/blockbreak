import 'package:blockbreak/game/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fresh state has sane defaults', () {
    final s = GameState();
    expect(s.pickaxes['wood']!.owned, isTrue);
    expect(s.biomesUnlocked, {'plains'});
    expect(s.equippedPickaxe, 'wood');
    expect(s.currentBiome, 'plains');
    expect(s.blockCount, 0);
  });

  test('json round trip preserves everything', () {
    final s = GameState()
      ..picks = 1234.5
      ..runic = 42
      ..inventory['dirt'] = 77
      ..inventory['sapphire'] = 3
      ..pickaxes['stone'] = PickaxeState(owned: true, level: 3)
      ..equippedPickaxe = 'stone'
      ..biomesUnlocked.add('desert')
      ..currentBiome = 'desert'
      ..gearOwned.add('hopper')
      ..smallChestsOpened = 4
      ..prestigeCount = 2
      ..currentBlockId = 'sand'
      ..currentBlockHp = 12
      ..savedAt = 999;
    s.stats.totalTaps = 500;
    s.stats.totalBlocks = 120;
    s.stats.totalCrits = 40;
    s.stats.chestsOpened = 6;

    final back = GameState.fromJson(s.toJson());
    expect(back.picks, 1234.5);
    expect(back.runic, 42);
    expect(back.inventory['dirt'], 77);
    expect(back.pickaxes['stone']!.level, 3);
    expect(back.pickaxes['stone']!.owned, isTrue);
    expect(back.equippedPickaxe, 'stone');
    expect(back.biomesUnlocked, contains('desert'));
    expect(back.currentBiome, 'desert');
    expect(back.gearOwned, contains('hopper'));
    expect(back.smallChestsOpened, 4);
    expect(back.prestigeCount, 2);
    expect(back.currentBlockId, 'sand');
    expect(back.currentBlockHp, 12);
    expect(back.savedAt, 999);
    expect(back.stats.totalTaps, 500);
    expect(back.stats.totalBlocks, 120);
    expect(back.stats.totalCrits, 40);
    expect(back.stats.chestsOpened, 6);
    expect(back.blockCount, 80);
  });

group('save sanitization', () {
  test('missing fields fall back to defaults', () {
    final s = GameState.fromJson(const <String, dynamic>{});
    expect(s.picks, 0);
    expect(s.biomesUnlocked, {'plains'});
    expect(s.currentBiome, 'plains');
    expect(s.equippedPickaxe, 'wood');
    expect(s.pickaxes['wood']!.owned, isTrue);
    expect(s.currentBlockId, 'dirt');
  });

  test('unknown ids are dropped everywhere', () {
    final s = GameState.fromJson({
      'inventory': {'dirt': 5, 'alien_rock': 9, 'clay': 'bad'},
      'pickaxes': {
        'stone': {'owned': true, 'level': 2},
        'lightsaber': {'owned': true},
        'iron': 'junk',
      },
      'equippedPickaxe': 'lightsaber',
      'biomesUnlocked': ['plains', 'narnia'],
      'currentBiome': 'narnia',
      'gearOwned': ['hopper', 'death_star'],
      'currentBlockId': 'alien_rock',
    });
    expect(s.inventory, {'dirt': 5.0});
    expect(s.pickaxes.keys, containsAll(['wood', 'stone']));
    expect(s.pickaxes.containsKey('lightsaber'), isFalse);
    expect(s.equippedPickaxe, 'wood');
    expect(s.biomesUnlocked, {'plains'});
    expect(s.currentBiome, 'plains');
    expect(s.gearOwned, {'hopper'});
    expect(s.currentBlockId, 'dirt');
  });

  test('gapped biome chain truncates to the contiguous prefix', () {
    final s = GameState.fromJson({
      'biomesUnlocked': ['plains', 'desert', 'caves'],
      'currentBiome': 'caves',
    });
    expect(s.biomesUnlocked, {'plains', 'desert'});
    expect(s.currentBiome, 'plains');
  });

  test('unowned equipped pickaxe falls back to wood', () {
    final s = GameState.fromJson({
      'equippedPickaxe': 'diamond',
      'pickaxes': {'diamond': {'owned': false, 'level': 9}},
    });
    expect(s.equippedPickaxe, 'wood');
  });

  test('partial stats map still parses', () {
    final s = GameState.fromJson({
      'stats': {'totalTaps': 12},
    });
    expect(s.stats.totalTaps, 12);
    expect(s.stats.totalBlocks, 0);
  });
});
}
