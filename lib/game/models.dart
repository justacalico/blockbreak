/// Serializable game state. Pure Dart, no Flutter imports.
library;

class PickaxeState {
  PickaxeState({this.owned = false, this.level = 0});

  bool owned;
  int level;

  Map<String, dynamic> toJson() => {'owned': owned, 'level': level};

  static PickaxeState fromJson(Map<String, dynamic> j) =>
      PickaxeState(owned: j['owned'] as bool, level: j['level'] as int);
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
        totalTaps: j['totalTaps'] as int,
        totalBlocks: j['totalBlocks'] as int,
        totalCrits: j['totalCrits'] as int,
        chestsOpened: j['chestsOpened'] as int,
      );
}

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
  Stats stats;

  /// Milliseconds since epoch when this state was saved.
  int savedAt;

  double get blockCount =>
      inventory.values.fold(0.0, (sum, v) => sum + v);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'picks': picks,
        'runic': runic,
        'inventory': inventory,
        'pickaxes':
            pickaxes.map((k, v) => MapEntry(k, v.toJson())),
        'equippedPickaxe': equippedPickaxe,
        'biomesUnlocked': biomesUnlocked.toList(),
        'currentBiome': currentBiome,
        'gearOwned': gearOwned.toList(),
        'smallChestsOpened': smallChestsOpened,
        'prestigeCount': prestigeCount,
        'currentBlockId': currentBlockId,
        'currentBlockHp': currentBlockHp,
        'stats': stats.toJson(),
        'savedAt': savedAt,
      };

  static GameState fromJson(Map<String, dynamic> j) {
    final inv = <String, double>{};
    (j['inventory'] as Map<String, dynamic>).forEach((k, v) {
      inv[k] = (v as num).toDouble();
    });
    final picks = <String, PickaxeState>{};
    (j['pickaxes'] as Map<String, dynamic>).forEach((k, v) {
      picks[k] = PickaxeState.fromJson(v as Map<String, dynamic>);
    });
    return GameState(
      picks: (j['picks'] as num).toDouble(),
      runic: (j['runic'] as num).toDouble(),
      inventory: inv,
      pickaxes: picks,
      equippedPickaxe: j['equippedPickaxe'] as String,
      biomesUnlocked:
          (j['biomesUnlocked'] as List).cast<String>().toSet(),
      currentBiome: j['currentBiome'] as String,
      gearOwned: (j['gearOwned'] as List).cast<String>().toSet(),
      smallChestsOpened: j['smallChestsOpened'] as int,
      prestigeCount: j['prestigeCount'] as int,
      currentBlockId: j['currentBlockId'] as String,
      currentBlockHp: (j['currentBlockHp'] as num).toDouble(),
      stats: Stats.fromJson(j['stats'] as Map<String, dynamic>),
      savedAt: j['savedAt'] as int,
    );
  }
}
