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
}
