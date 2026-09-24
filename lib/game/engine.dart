import 'dart:math';

import 'content.dart';
import 'models.dart';

class SwingResult {
  const SwingResult({
    required this.damage,
    required this.crit,
    required this.broke,
    required this.picks,
    this.brokenBlockId,
    this.drops = 0,
  });

  final double damage;
  final bool crit;
  final bool broke;
  final double picks;
  final String? brokenBlockId;
  final int drops;
}

class TickResult {
  TickResult({this.picks = 0, List<String>? broken})
      : broken = broken ?? [];

  double picks;
  final List<String> broken;
}

class ChestReward {
  ChestReward({
    Map<String, double>? blocks,
    this.pickaxeId,
    this.runic = 0,
  }) : blocks = blocks ?? {};

  final Map<String, double> blocks;
  String? pickaxeId;
  double runic;

  bool get isEmpty => blocks.isEmpty && pickaxeId == null && runic == 0;
}

class OfflineReport {
  OfflineReport({
    required this.seconds,
    required this.picks,
    Map<String, double>? blocks,
  }) : blocks = blocks ?? {};

  final int seconds;
  final double picks;
  final Map<String, double> blocks;

  bool get isEmpty => picks < 1 && blocks.isEmpty;
}

enum ChestKind { small, large }

/// Pure game logic. Deterministic when given a seeded [Random].
class GameEngine {
  GameEngine(this.state, {Random? rng}) : _rng = rng ?? Random();

  final GameState state;
  final Random _rng;

  BiomeDef get biome => biomeDef(state.currentBiome);
  PickaxeDef get pickaxe => pickaxeDef(state.equippedPickaxe);

  PickaxeState _pickaxeState(String id) =>
      state.pickaxes.putIfAbsent(id, PickaxeState.new);

  int biomeIndex(String id) => kBiomes.indexWhere((b) => b.id == id);

  int get _highestBiomeIndex =>
      state.biomesUnlocked.map(biomeIndex).fold(0, max);

  String? get nextBiomeId {
    final next = _highestBiomeIndex + 1;
    return next < kBiomes.length ? kBiomes[next].id : null;
  }

  // -- derived stats ------------------------------------------------------

  Iterable<AbilityDef> get _abilities =>
      state.biomesUnlocked.map(biomeDef).map((b) => b.ability).whereType();

  double get dmgMul =>
      _abilities.fold(1.0, (m, a) => m * a.dmgMul);

  double get ppsMul =>
      _abilities.fold(1.0, (m, a) => m * a.ppsMul);

  double get pickMul =>
      _abilities.fold(1.0, (m, a) => m * a.pickMul);

  double get critChance => critChanceFor(state.equippedPickaxe);

  double critChanceFor(String id) =>
      (pickaxeDef(id).crit +
              0.01 * pickaxeLevel(id) +
              _abilities.fold(0.0, (s, a) => s + a.critAdd))
          .clamp(0.0, 0.95);

  int get dropBonus =>
      _abilities.fold(0, (s, a) => s + a.dropAdd.round());

  int pickaxeLevel(String id) => _pickaxeState(id).level;

  int get maxPickaxeLevel => 1 + state.prestigeCount;

  double pickaxeStrength(String id) {
    final def = pickaxeDef(id);
    return def.strength * (1 + 0.3 * _pickaxeState(id).level);
  }

  double get pps {
    var sum = 0.0;
    for (final b in kBiomes) {
      for (final g in b.gear) {
        if (state.gearOwned.contains(g.id)) sum += g.pps;
      }
    }
    return sum * ppsMul;
  }

  double get blockMaxHp => blockDef(state.currentBlockId).hp;

  double get swingDamage =>
      pickaxeStrength(state.equippedPickaxe) * dmgMul +
      blockMaxHp * kTapFraction;

  double get autoDamagePerSecond => pps * kAutoDmgRate;

  // -- mining -------------------------------------------------------------

  String _rollBlock(BiomeDef b, {bool rareBias = false}) {
    var total = 0;
    for (final blk in b.blocks) {
      total += rareBias ? blk.weight * blk.weight : blk.weight;
    }
    var roll = _rng.nextInt(total);
    var i = 0;
    while (i < b.blocks.length - 1) {
      final w =
          rareBias ? b.blocks[i].weight * b.blocks[i].weight : b.blocks[i].weight;
      if (roll < w) break;
      roll -= w;
      i++;
    }
    return b.blocks[i].id;
  }

  void _spawnBlock() {
    final id = _rollBlock(biome);
    state.currentBlockId = id;
    state.currentBlockHp = blockDef(id).hp;
  }

  void _collectDrops(String blockId, List<String>? into) {
    final count = 1 + dropBonus;
    state.inventory[blockId] = (state.inventory[blockId] ?? 0) + count;
    state.stats.totalBlocks++;
    into?.add(blockId);
  }

  SwingResult tap() {
    state.stats.totalTaps++;
    final crit = _rng.nextDouble() < critChance;
    var dmg = swingDamage;
    if (crit) {
      dmg *= kCritMult;
      state.stats.totalCrits++;
    }
    final earned = dmg * pickMul;
    state.picks += earned;

    var broke = false;
    String? brokenId;
    var drops = 0;
    state.currentBlockHp -= dmg;
    if (state.currentBlockHp <= 0) {
      broke = true;
      brokenId = state.currentBlockId;
      drops = 1 + dropBonus;
      _collectDrops(brokenId, null);
      _spawnBlock();
    }
    return SwingResult(
      damage: dmg,
      crit: crit,
      broke: broke,
      picks: earned,
      brokenBlockId: brokenId,
      drops: drops,
    );
  }

  TickResult tick(double dt) {
    final result = TickResult();
    final earned = pps * dt * pickMul;
    state.picks += earned;
    result.picks = earned;

    var dmgPool = autoDamagePerSecond * dt;
    var guard = 0;
    while (dmgPool > 0 && guard++ < 200) {
      if (dmgPool >= state.currentBlockHp) {
        dmgPool -= state.currentBlockHp;
        final brokenId = state.currentBlockId;
        _collectDrops(brokenId, result.broken);
        _spawnBlock();
      } else {
        state.currentBlockHp -= dmgPool;
        dmgPool = 0;
      }
    }
    return result;
  }

  // -- economy ------------------------------------------------------------

  bool canAfford(Map<String, int> cost) => cost.entries
      .every((e) => (state.inventory[e.key] ?? 0) >= e.value);

  void _pay(Map<String, int> cost) {
    for (final e in cost.entries) {
      state.inventory[e.key] = (state.inventory[e.key] ?? 0) - e.value;
    }
  }

  bool get canPrestige =>
      state.currentBiome == 'the_end' &&
      (_pickaxeState('endstone').owned);

  int get prestigeRunic =>
      min(kPrestigeRunicCap, 5 + (state.stats.totalBlocks ~/ 40));

  bool buyPickaxe(String id) {
    final def = pickaxeDef(id);
    final st = _pickaxeState(id);
    if (st.owned || !canAfford(def.cost)) return false;
    _pay(def.cost);
    st.owned = true;
    state.equippedPickaxe = id;
    return true;
  }

  Map<String, int> upgradeCost(String id) {
    final def = pickaxeDef(id);
    final level = _pickaxeState(id).level;
    return def.cost.map(
      (k, v) => MapEntry(k, (v * pow(1.6, level)).ceil()),
    );
  }

  bool upgradePickaxe(String id) {
    final st = _pickaxeState(id);
    if (!st.owned || st.level >= maxPickaxeLevel) return false;
    final cost = upgradeCost(id);
    if (!canAfford(cost)) return false;
    _pay(cost);
    st.level++;
    return true;
  }

  bool equipPickaxe(String id) {
    if (!_pickaxeState(id).owned) return false;
    state.equippedPickaxe = id;
    return true;
  }

  bool buyGear(String id) {
    for (final b in kBiomes) {
      for (final g in b.gear) {
        if (g.id == id) {
          if (state.gearOwned.contains(id) || !canAfford(g.cost)) {
            return false;
          }
          _pay(g.cost);
          state.gearOwned.add(id);
          return true;
        }
      }
    }
    return false;
  }

  bool unlockBiome(String id) {
    if (state.biomesUnlocked.contains(id) || id != nextBiomeId) {
      return false;
    }
    final def = biomeDef(id);
    if (!canAfford(def.unlockCost)) return false;
    _pay(def.unlockCost);
    state.biomesUnlocked.add(id);
    return true;
  }

  bool travelTo(String id) {
    if (!state.biomesUnlocked.contains(id)) return false;
    if (state.currentBiome != id) {
      state.currentBiome = id;
      _spawnBlock();
    }
    return true;
  }

  // -- chests ---------------------------------------------------------------

  double get smallChestCost =>
      500 * pow(2.5, state.smallChestsOpened).toDouble();

  static const double largeChestCost = 15;

  ChestReward? openChest(ChestKind kind) {
    if (kind == ChestKind.small) {
      if (state.picks < smallChestCost) return null;
      state.picks -= smallChestCost;
      state.smallChestsOpened++;
    } else {
      if (state.runic < largeChestCost) return null;
      state.runic -= largeChestCost;
    }
    state.stats.chestsOpened++;

    final reward = ChestReward();
    final unlocked =
        kBiomes.where((b) => state.biomesUnlocked.contains(b.id)).toList();
    final rolls =
        kind == ChestKind.small ? 3 + _rng.nextInt(4) : 10 + _rng.nextInt(10);
    for (var i = 0; i < rolls; i++) {
      final b = unlocked[_rng.nextInt(unlocked.length)];
      final blockId = _rollBlock(b, rareBias: kind == ChestKind.large);
      reward.blocks[blockId] = (reward.blocks[blockId] ?? 0) + 1;
      state.inventory[blockId] = (state.inventory[blockId] ?? 0) + 1;
    }

    final pickChance = kind == ChestKind.small ? 0.04 : 0.20;
    if (_rng.nextDouble() < pickChance) {
      final locked = kPickaxes
          .where((p) => !_pickaxeState(p.id).owned)
          .toList();
      if (locked.isNotEmpty) {
        final won = locked.first;
        _pickaxeState(won.id).owned = true;
        reward.pickaxeId = won.id;
      }
    }

    if (kind == ChestKind.small && _rng.nextDouble() < 0.08) {
      reward.runic = 1 + _rng.nextInt(3).toDouble();
    } else if (kind == ChestKind.large && _rng.nextDouble() < 0.5) {
      reward.runic = 3 + _rng.nextInt(4).toDouble();
    }
    state.runic += reward.runic;
    return reward;
  }

  // -- prestige ---------------------------------------------------------------

  /// Resets the run in exchange for runic. Returns runic gained, or -1 if
  /// prestige is not available.
  double prestige() {
    if (!canPrestige) return -1;
    final gained = prestigeRunic.toDouble();
    state.runic += gained;
    state.prestigeCount++;
    state.picks = 0;
    state.inventory.clear();
    state.biomesUnlocked
      ..clear()
      ..add('plains');
    state.currentBiome = 'plains';
    state.gearOwned.clear();
    _spawnBlock();
    return gained;
  }

  // -- offline ------------------------------------------------------------

  OfflineReport applyOffline(int elapsedSeconds) {
    final secs = min(elapsedSeconds, kOfflineCapSeconds);
    final earned = pps * secs * pickMul;
    state.picks += earned;
    final blocks = <String, double>{};

    var dmgPool = autoDamagePerSecond * secs;
    var guard = 0;
    while (guard++ < 500 && dmgPool >= state.currentBlockHp) {
      dmgPool -= state.currentBlockHp;
      final brokenId = state.currentBlockId;
      _collectDrops(brokenId, null);
      blocks[brokenId] = (blocks[brokenId] ?? 0) + 1 + dropBonus;
      _spawnBlock();
    }
    state.currentBlockHp = max(1, state.currentBlockHp - dmgPool);
    return OfflineReport(seconds: secs, picks: earned, blocks: blocks);
  }

  /// Ensure a fresh/loaded state has a live block. Called after load.
  void ensureBlock() {
    if (state.currentBlockHp <= 0 ||
        !biome.blocks.any((b) => b.id == state.currentBlockId)) {
      _spawnBlock();
    }
  }
}
