/// Serializable game state. Pure Dart, no Flutter imports.
library;

import 'content.dart';

class PickaxeState {
  PickaxeState({this.owned = false, this.level = 0});

  bool owned;
  int level;

  Map<String, dynamic> toJson() => {'owned': owned, 'level': level};

  static PickaxeState fromJson(Map<String, dynamic> j) => PickaxeState(
        owned: j['owned'] == true,
        level: _int(j['level']),
      );
}

class Stats {
  Stats({
    this.totalTaps = 0,
    this.totalBlocks = 0,
    this.totalCrits = 0,
    this.chestsOpened = 0,
  });

  int totalTaps;
  int totalBlocks;
  int totalCrits;
  int chestsOpened;

  Map<String, dynamic> toJson() => {
        'totalTaps': totalTaps,
        'totalBlocks': totalBlocks,
        'totalCrits': totalCrits,
        'chestsOpened': chestsOpened,
      };

  static Stats fromJson(Map<String, dynamic> j) => Stats(
        totalTaps: _int(j['totalTaps']),
        totalBlocks: _int(j['totalBlocks']),
        totalCrits: _int(j['totalCrits']),
        chestsOpened: _int(j['chestsOpened']),
      );
}

double _dbl(Object? v) => v is num ? v.toDouble() : 0;

int _int(Object? v) => v is num ? v.toInt() : 0;

final _knownBlocks = {
  for (final b in kBiomes) for (final blk in b.blocks) blk.id,
};
final _knownPickaxes = {for (final p in kPickaxes) p.id};
final _knownGear = {
  for (final b in kBiomes) for (final g in b.gear) g.id,
};

class GameState {
  GameState({
    this.picks = 0,
    this.runic = 0,
    Map<String, double>? inventory,
    Map<String, PickaxeState>? pickaxes,
    this.equippedPickaxe = 'wood',
    Set<String>? biomesUnlocked,
    this.currentBiome = 'plains',
    Set<String>? gearOwned,
    this.smallChestsOpened = 0,
    this.prestigeCount = 0,
    this.currentBlockId = 'dirt',
    this.currentBlockHp = 0,
    this.blocksThisRun = 0,
    Stats? stats,
    this.savedAt = 0,
  })  : inventory = inventory ?? {},
        pickaxes = pickaxes ?? {'wood': PickaxeState(owned: true)},
        biomesUnlocked = biomesUnlocked ?? {'plains'},
        gearOwned = gearOwned ?? {},
        stats = stats ?? Stats();

  double picks;
  double runic;
  Map<String, double> inventory;
  Map<String, PickaxeState> pickaxes;
  String equippedPickaxe;
  Set<String> biomesUnlocked;
  String currentBiome;
  Set<String> gearOwned;
  int smallChestsOpened;
  int prestigeCount;
  String currentBlockId;
  double currentBlockHp;

  /// Blocks broken since the last prestige; feeds the runic payout.
  int blocksThisRun;
  Stats stats;

  /// Milliseconds since epoch when this state was saved.
  int savedAt;

  double get blockCount => inventory.values.fold(0.0, (sum, v) => sum + v);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'picks': picks,
        'runic': runic,
        'inventory': inventory,
        'pickaxes': pickaxes.map((k, v) => MapEntry(k, v.toJson())),
        'equippedPickaxe': equippedPickaxe,
        'biomesUnlocked': biomesUnlocked.toList(),
        'currentBiome': currentBiome,
        'gearOwned': gearOwned.toList(),
        'smallChestsOpened': smallChestsOpened,
        'prestigeCount': prestigeCount,
        'currentBlockId': currentBlockId,
        'currentBlockHp': currentBlockHp,
        'blocksThisRun': blocksThisRun,
        'stats': stats.toJson(),
        'savedAt': savedAt,
      };

  /// Tolerant load: missing fields default, unknown ids are dropped, and a
  /// gapped biome chain is truncated to its contiguous prefix so unlocks
  /// can never dead-end.
  static GameState fromJson(Map<String, dynamic> j) {
    final inv = <String, double>{};
    (j['inventory'] as Map?)?.forEach((k, v) {
      if (v is num && _knownBlocks.contains(k)) inv[k] = v.toDouble();
    });

    final picks = <String, PickaxeState>{};
    (j['pickaxes'] as Map?)?.forEach((k, v) {
      if (v is Map && _knownPickaxes.contains(k)) {
        picks[k] = PickaxeState.fromJson(v.cast<String, dynamic>());
      }
    });
    if (!(picks['wood']?.owned ?? false)) {
      picks['wood'] = PickaxeState(owned: true);
    }

    // Keep the longest contiguous prefix of the biome chain.
    final claimed = (j['biomesUnlocked'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final biomes = <String>{};
    for (final b in kBiomes) {
      if (!claimed.contains(b.id)) break;
      biomes.add(b.id);
    }
    if (biomes.isEmpty) biomes.add('plains');

    var equipped = j['equippedPickaxe'];
    equipped = equipped is String ? equipped : 'wood';
    if (!(picks[equipped]?.owned ?? false)) equipped = 'wood';

    var biome = j['currentBiome'];
    biome = biome is String ? biome : 'plains';
    if (!biomes.contains(biome)) biome = 'plains';

    final gear = (j['gearOwned'] as List? ?? const [])
        .whereType<String>()
        .where(_knownGear.contains)
        .toSet();

    var block = j['currentBlockId'];
    block = block is String ? block : 'dirt';
    if (!_knownBlocks.contains(block)) block = 'dirt';

    final statsRaw = j['stats'];
    final stats = statsRaw is Map
        ? Stats.fromJson(statsRaw.cast<String, dynamic>())
        : Stats();

    return GameState(
      picks: _dbl(j['picks']),
      runic: _dbl(j['runic']),
      inventory: inv,
      pickaxes: picks,
      equippedPickaxe: equipped,
      biomesUnlocked: biomes,
      currentBiome: biome,
      gearOwned: gear,
      smallChestsOpened: _int(j['smallChestsOpened']),
      prestigeCount: _int(j['prestigeCount']),
      currentBlockId: block,
      currentBlockHp: _dbl(j['currentBlockHp']),
      blocksThisRun: _int(j['blocksThisRun']),
      stats: stats,
      savedAt: _int(j['savedAt']),
    );
  }
}
