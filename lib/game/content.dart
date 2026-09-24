/// All static game data: blocks, biomes, pickaxes, gear, chests, abilities.
///
/// Pure Dart, no Flutter imports. Colors are stored as ARGB ints and mapped
/// to [Color] at the paint layer.
library;

enum TextureKind { plain, speckled, rings, stripes, cracks, gems }

class BlockDef {
  const BlockDef({
    required this.id,
    required this.name,
    required this.palette,
    required this.hp,
    required this.weight,
    this.texture = TextureKind.plain,
  });

  final String id;
  final String name;

  /// 3-5 ARGB colors, darkest first is not required; index 0 is the base.
  final List<int> palette;
  final double hp;
  final int weight;
  final TextureKind texture;
}

class GearDef {
  const GearDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.cost,
    required this.pps,
  });

  final String id;
  final String name;
  final String desc;
  final Map<String, int> cost;
  final double pps;
}

class AbilityDef {
  const AbilityDef({
    required this.id,
    required this.name,
    required this.desc,
    this.dmgMul = 1.0,
    this.ppsMul = 1.0,
    this.pickMul = 1.0,
    this.critAdd = 0.0,
    this.dropAdd = 0.0,
  });

  final String id;
  final String name;
  final String desc;
  final double dmgMul;
  final double ppsMul;
  final double pickMul;
  final double critAdd;
  final double dropAdd;
}

class BiomeDef {
  const BiomeDef({
    required this.id,
    required this.name,
    required this.sky,
    required this.ground,
    required this.accent,
    required this.blocks,
    required this.unlockCost,
    required this.gear,
    required this.unlockLabel,
    this.ability,
  });

  final String id;
  final String name;

  /// [top, bottom] sky gradient colors.
  final List<int> sky;
  final int ground;
  final int accent;
  final List<BlockDef> blocks;

  /// Blocks required to unlock; empty for the starting biome.
  final Map<String, int> unlockCost;

  /// Human readable source hint, e.g. "Dirt and Clay from the Plains".
  final String unlockLabel;
  final List<GearDef> gear;
  final AbilityDef? ability;
}

class PickaxeDef {
  const PickaxeDef({
    required this.id,
    required this.name,
    required this.head,
    required this.handle,
    required this.strength,
    required this.crit,
    required this.cost,
    this.free = false,
  });

  final String id;
  final String name;
  final int head;
  final int handle;
  final double strength;

  /// Base critical chance, 0..1.
  final double crit;
  final Map<String, int> cost;
  final bool free;
}

const kCritMult = 3.0;
const kTapFraction = 0.01;
const kAutoDmgRate = 0.05;
const kPrestigeRunicCap = 250;
const kOfflineCapSeconds = 8 * 3600;

const kPickaxes = <PickaxeDef>[
  PickaxeDef(
    id: 'wood',
    name: 'Wooden Pickaxe',
    head: 0xFF8A5A2B,
    handle: 0xFF5C3A1A,
    strength: 2,
    crit: 0.05,
    cost: {},
    free: true,
  ),
  PickaxeDef(
    id: 'stone',
    name: 'Stone Pickaxe',
    head: 0xFF8D8D93,
    handle: 0xFF5C3A1A,
    strength: 6,
    crit: 0.06,
    cost: {'dirt': 60, 'clay': 30},
  ),
  PickaxeDef(
    id: 'iron',
    name: 'Iron Pickaxe',
    head: 0xFFD8D8DE,
    handle: 0xFF4E463E,
    strength: 22,
    crit: 0.08,
    cost: {'sandstone': 80, 'terracotta': 40},
  ),
  PickaxeDef(
    id: 'gold',
    name: 'Golden Pickaxe',
    head: 0xFFF4C531,
    handle: 0xFF4E463E,
    strength: 80,
    crit: 0.10,
    cost: {'packed_ice': 100, 'sapphire': 40},
  ),
  PickaxeDef(
    id: 'diamond',
    name: 'Diamond Pickaxe',
    head: 0xFF4FD8E0,
    handle: 0xFF3A3A44,
    strength: 300,
    crit: 0.12,
    cost: {'iron_ore': 120, 'lapis_ore': 50},
  ),
  PickaxeDef(
    id: 'emerald',
    name: 'Emerald Pickaxe',
    head: 0xFF35D07F,
    handle: 0xFF3A3A44,
    strength: 1100,
    crit: 0.14,
    cost: {'gold_ore': 100, 'diamond_ore': 40},
  ),
  PickaxeDef(
    id: 'ruby',
    name: 'Ruby Pickaxe',
    head: 0xFFE0455A,
    handle: 0xFF33262E,
    strength: 4200,
    crit: 0.16,
    cost: {'copper_ore': 120, 'topaz': 50},
  ),
  PickaxeDef(
    id: 'pearl',
    name: 'Pearl Pickaxe',
    head: 0xFFF1E8DC,
    handle: 0xFF2E3A4E,
    strength: 16000,
    crit: 0.18,
    cost: {'jade': 90, 'pearl': 60},
  ),
  PickaxeDef(
    id: 'obsidian',
    name: 'Obsidian Pickaxe',
    head: 0xFF3B2E5A,
    handle: 0xFF1E1626,
    strength: 65000,
    crit: 0.22,
    cost: {'obsidian': 80, 'ancient_debris': 30},
  ),
  PickaxeDef(
    id: 'endstone',
    name: 'Endstone Pickaxe',
    head: 0xFFDCE3A8,
    handle: 0xFF6A5ACD,
    strength: 260000,
    crit: 0.25,
    cost: {'endstone': 120, 'dragon_scale': 40},
  ),
];

const kBiomes = <BiomeDef>[
  BiomeDef(
    id: 'plains',
    name: 'Plains',
    sky: [0xFF7EC0EE, 0xFFCDE9F6],
    ground: 0xFF6FA04A,
    accent: 0xFF8A5A2B,
    unlockCost: {},
    unlockLabel: '',
    blocks: [
      BlockDef(
        id: 'dirt',
        name: 'Dirt',
        palette: [0xFF8A5A2B, 0xFF74491F, 0xFF9C6B35, 0xFF5F3C19],
        hp: 6,
        weight: 40,
      ),
      BlockDef(
        id: 'clay',
        name: 'Clay',
        palette: [0xFF9FA4B0, 0xFF8B90A0, 0xFFAFB4C0, 0xFF7A7F8F],
        hp: 9,
        weight: 30,
        texture: TextureKind.stripes,
      ),
      BlockDef(
        id: 'oak_log',
        name: 'Oak Log',
        palette: [0xFF6B4A26, 0xFF59391C, 0xFF7E5A30, 0xFFC9A06A],
        hp: 13,
        weight: 20,
        texture: TextureKind.rings,
      ),
      BlockDef(
        id: 'pumpkin',
        name: 'Pumpkin',
        palette: [0xFFDD7A1E, 0xFFC2690F, 0xFFF0912E, 0xFF5F8A2E],
        hp: 18,
        weight: 10,
        texture: TextureKind.stripes,
      ),
    ],
    gear: [
      GearDef(
        id: 'hopper',
        name: 'Hopper',
        desc: 'Collects blocks while you rest.',
        cost: {'dirt': 40},
        pps: 3,
      ),
      GearDef(
        id: 'furnace_cart',
        name: 'Furnace Cart',
        desc: 'A rattling cart that never stops hauling.',
        cost: {'clay': 60, 'oak_log': 40},
        pps: 14,
      ),
    ],
  ),
  BiomeDef(
    id: 'desert',
    name: 'Desert',
    sky: [0xFFF6C86B, 0xFFFBE7B2],
    ground: 0xFFE3C078,
    accent: 0xFFC2690F,
    unlockCost: {'dirt': 80, 'clay': 40},
    unlockLabel: 'Dirt and Clay from the Plains',
    blocks: [
      BlockDef(
        id: 'sand',
        name: 'Sand',
        palette: [0xFFE8D48A, 0xFFD9C273, 0xFFF4E2A0, 0xFFC4AE5E],
        hp: 30,
        weight: 40,
      ),
      BlockDef(
        id: 'sandstone',
        name: 'Sandstone',
        palette: [0xFFD8B96A, 0xFFC4A355, 0xFFE8CD82, 0xFFAE8F45],
        hp: 42,
        weight: 30,
        texture: TextureKind.stripes,
      ),
      BlockDef(
        id: 'cactus',
        name: 'Cactus',
        palette: [0xFF4E8A3C, 0xFF3F7330, 0xFF63A34E, 0xFFE8E4C8],
        hp: 55,
        weight: 20,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'terracotta',
        name: 'Terracotta',
        palette: [0xFF9E5B43, 0xFF8A4B36, 0xFFB26B52, 0xFF7A3F2E],
        hp: 70,
        weight: 10,
        texture: TextureKind.stripes,
      ),
    ],
    gear: [
      GearDef(
        id: 'sun_dial',
        name: 'Sun Dial',
        desc: 'Bakes ore loose in the noon glare.',
        cost: {'sandstone': 80},
        pps: 45,
      ),
      GearDef(
        id: 'sand_worm',
        name: 'Sand Worm',
        desc: 'Burrows for blocks beneath the dunes.',
        cost: {'cactus': 60, 'terracotta': 40},
        pps: 140,
      ),
    ],
    ability: AbilityDef(
      id: 'sharpened_edge',
      name: 'Sharpened Edge',
      desc: '+15% swing damage',
      dmgMul: 1.15,
    ),
  ),
  BiomeDef(
    id: 'tundra',
    name: 'Tundra',
    sky: [0xFFB8D8E8, 0xFFEAF4FA],
    ground: 0xFFEAF4FA,
    accent: 0xFF6BA8CC,
    unlockCost: {'sandstone': 70, 'terracotta': 30},
    unlockLabel: 'Sandstone and Terracotta from the Desert',
    blocks: [
      BlockDef(
        id: 'snow',
        name: 'Snow',
        palette: [0xFFF2F7FA, 0xFFE0EAF0, 0xFFFFFFFF, 0xFFC8D8E2],
        hp: 130,
        weight: 40,
      ),
      BlockDef(
        id: 'ice',
        name: 'Ice',
        palette: [0xFF9CCFE8, 0xFF82BCD8, 0xFFB8E2F4, 0xFF6BA8CC],
        hp: 180,
        weight: 30,
        texture: TextureKind.cracks,
      ),
      BlockDef(
        id: 'packed_ice',
        name: 'Packed Ice',
        palette: [0xFF6FA8D0, 0xFF5C92BC, 0xFF86BEE0, 0xFF4A7CA6],
        hp: 240,
        weight: 20,
        texture: TextureKind.cracks,
      ),
      BlockDef(
        id: 'sapphire',
        name: 'Sapphire',
        palette: [0xFF8B90A0, 0xFF2E5AE8, 0xFF4A78F4, 0xFF1E3EA8],
        hp: 320,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'ice_drill',
        name: 'Ice Drill',
        desc: 'Chews through permafrost.',
        cost: {'packed_ice': 90},
        pps: 420,
      ),
      GearDef(
        id: 'yak_train',
        name: 'Yak Train',
        desc: 'Shaggy, stubborn, unstoppable.',
        cost: {'ice': 120, 'sapphire': 30},
        pps: 1300,
      ),
    ],
    ability: AbilityDef(
      id: 'frozen_focus',
      name: 'Frozen Focus',
      desc: '+5% critical chance',
      critAdd: 0.05,
    ),
  ),
  BiomeDef(
    id: 'caves',
    name: 'Caves',
    sky: [0xFF2E3440, 0xFF4C566A],
    ground: 0xFF3B4252,
    accent: 0xFF8D8D93,
    unlockCost: {'packed_ice': 80, 'sapphire': 30},
    unlockLabel: 'Packed Ice and Sapphire from the Tundra',
    blocks: [
      BlockDef(
        id: 'stone',
        name: 'Stone',
        palette: [0xFF8D8D93, 0xFF7A7A80, 0xFF9FA0A6, 0xFF68686E],
        hp: 550,
        weight: 40,
      ),
      BlockDef(
        id: 'coal_ore',
        name: 'Coal Ore',
        palette: [0xFF8D8D93, 0xFF2B2B30, 0xFF3D3D44, 0xFF1A1A1E],
        hp: 750,
        weight: 30,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'iron_ore',
        name: 'Iron Ore',
        palette: [0xFF8D8D93, 0xFFC89A72, 0xFFD8B08A, 0xFFA87E58],
        hp: 1000,
        weight: 20,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'lapis_ore',
        name: 'Lapis Ore',
        palette: [0xFF8D8D93, 0xFF2E4AB8, 0xFF4060D8, 0xFF1E3488],
        hp: 1400,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'minecart',
        name: 'Minecart',
        desc: 'Hauls ore up the rails all night.',
        cost: {'iron_ore': 100},
        pps: 3800,
      ),
      GearDef(
        id: 'bat_colony',
        name: 'Bat Colony',
        desc: 'They see in the dark so you do not have to.',
        cost: {'coal_ore': 150, 'lapis_ore': 40},
        pps: 11000,
      ),
    ],
    ability: AbilityDef(
      id: 'torchlight',
      name: 'Torchlight',
      desc: '+25% picks from all sources',
      pickMul: 1.25,
    ),
  ),
  BiomeDef(
    id: 'deep_caverns',
    name: 'Deep Caverns',
    sky: [0xFF16181F, 0xFF2A2E3C],
    ground: 0xFF1F222C,
    accent: 0xFF4FD8E0,
    unlockCost: {'iron_ore': 90, 'lapis_ore': 35},
    unlockLabel: 'Iron and Lapis from the Caves',
    blocks: [
      BlockDef(
        id: 'deepslate',
        name: 'Deepslate',
        palette: [0xFF4A4E58, 0xFF3C404A, 0xFF585E6A, 0xFF30343C],
        hp: 3200,
        weight: 40,
        texture: TextureKind.stripes,
      ),
      BlockDef(
        id: 'gold_ore',
        name: 'Gold Ore',
        palette: [0xFF4A4E58, 0xFFF4C531, 0xFFFFDA6B, 0xFFC89A20],
        hp: 4200,
        weight: 30,
        texture: TextureKind.gems,
      ),
      BlockDef(
        id: 'diamond_ore',
        name: 'Diamond Ore',
        palette: [0xFF4A4E58, 0xFF4FD8E0, 0xFF8AECF0, 0xFF2EA8B8],
        hp: 5600,
        weight: 20,
        texture: TextureKind.gems,
      ),
      BlockDef(
        id: 'emerald_ore',
        name: 'Emerald Ore',
        palette: [0xFF4A4E58, 0xFF35D07F, 0xFF6AE8A8, 0xFF22A058],
        hp: 7600,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'auto_miner',
        name: 'Auto Miner',
        desc: 'A tireless clockwork digger.',
        cost: {'gold_ore': 120},
        pps: 34000,
      ),
      GearDef(
        id: 'resonator',
        name: 'Crystal Resonator',
        desc: 'Sings blocks out of the walls.',
        cost: {'diamond_ore': 80, 'emerald_ore': 30},
        pps: 100000,
      ),
    ],
    ability: AbilityDef(
      id: 'resonance',
      name: 'Resonance',
      desc: '+25% PPS',
      ppsMul: 1.25,
    ),
  ),
  BiomeDef(
    id: 'mesa',
    name: 'Mesa',
    sky: [0xFFE89060, 0xFFF6C89A],
    ground: 0xFFB2603C,
    accent: 0xFFE07A3C,
    unlockCost: {'gold_ore': 90, 'diamond_ore': 30},
    unlockLabel: 'Gold and Diamonds from the Deep Caverns',
    blocks: [
      BlockDef(
        id: 'red_sand',
        name: 'Red Sand',
        palette: [0xFFC06A3C, 0xFFA85A30, 0xFFD07A4C, 0xFF8E4A26],
        hp: 14000,
        weight: 40,
      ),
      BlockDef(
        id: 'red_terracotta',
        name: 'Red Terracotta',
        palette: [0xFF8E3E2C, 0xFF7A3222, 0xFFA24C38, 0xFF68281A],
        hp: 19000,
        weight: 30,
        texture: TextureKind.stripes,
      ),
      BlockDef(
        id: 'copper_ore',
        name: 'Copper Ore',
        palette: [0xFF8E3E2C, 0xFFE8865A, 0xFFF4A87A, 0xFFC06840],
        hp: 26000,
        weight: 20,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'topaz',
        name: 'Topaz',
        palette: [0xFF8E3E2C, 0xFFF4A020, 0xFFFFC45A, 0xFFC07808],
        hp: 36000,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'rail_line',
        name: 'Rail Line',
        desc: 'Ore trains on a five minute headway.',
        cost: {'copper_ore': 120},
        pps: 320000,
      ),
      GearDef(
        id: 'dust_devil',
        name: 'Dust Devil',
        desc: 'A tornado that owes you a favor.',
        cost: {'red_terracotta': 150, 'topaz': 40},
        pps: 950000,
      ),
    ],
    ability: AbilityDef(
      id: 'high_noon',
      name: 'High Noon',
      desc: '+30% swing damage',
      dmgMul: 1.3,
    ),
  ),
  BiomeDef(
    id: 'jungle',
    name: 'Jungle',
    sky: [0xFF4E8A5C, 0xFF9AC8A0],
    ground: 0xFF2E5A3A,
    accent: 0xFF35A04E,
    unlockCost: {'copper_ore': 90, 'topaz': 30},
    unlockLabel: 'Copper and Topaz from the Mesa',
    blocks: [
      BlockDef(
        id: 'mossy_stone',
        name: 'Mossy Stone',
        palette: [0xFF6A7A62, 0xFF586A50, 0xFF7E8C74, 0xFF485840],
        hp: 62000,
        weight: 40,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'jungle_log',
        name: 'Jungle Log',
        palette: [0xFF5A4A2E, 0xFF4A3C24, 0xFF6A583A, 0xFF3E8A4E],
        hp: 84000,
        weight: 30,
        texture: TextureKind.rings,
      ),
      BlockDef(
        id: 'cocoa_pod',
        name: 'Cocoa Pod',
        palette: [0xFF7A4A1E, 0xFF5E3A14, 0xFF965C2A, 0xFF4A2E0E],
        hp: 115000,
        weight: 20,
      ),
      BlockDef(
        id: 'jade',
        name: 'Jade',
        palette: [0xFF3E5A44, 0xFF2EE88A, 0xFF5AF4A8, 0xFF1EB868],
        hp: 160000,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'temple_trap',
        name: 'Temple Trap',
        desc: 'Ancient machinery, still hungry.',
        cost: {'jade': 80},
        pps: 3000000,
      ),
      GearDef(
        id: 'jaguar',
        name: 'Jaguar',
        desc: 'Hunts blocks. Do not ask how.',
        cost: {'jungle_log': 160, 'jade': 40},
        pps: 9000000,
      ),
    ],
    ability: AbilityDef(
      id: 'predator',
      name: 'Predator Instinct',
      desc: '+5% critical chance',
      critAdd: 0.05,
    ),
  ),
  BiomeDef(
    id: 'ocean',
    name: 'Ocean',
    sky: [0xFF2E6AA8, 0xFF7AB8D8],
    ground: 0xFF1E4A78,
    accent: 0xFF4FA8E0,
    unlockCost: {'jade': 80, 'jungle_log': 120},
    unlockLabel: 'Jade and Jungle Logs from the Jungle',
    blocks: [
      BlockDef(
        id: 'coral',
        name: 'Coral',
        palette: [0xFFE87A6A, 0xFFD06050, 0xFFF49284, 0xFFB04840],
        hp: 280000,
        weight: 40,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'prismarine',
        name: 'Prismarine',
        palette: [0xFF5A9A92, 0xFF4A847C, 0xFF6CB0A6, 0xFF3A6C66],
        hp: 380000,
        weight: 30,
        texture: TextureKind.cracks,
      ),
      BlockDef(
        id: 'sponge',
        name: 'Sponge',
        palette: [0xFFC8C04A, 0xFFAEA63A, 0xFFDCD45A, 0xFF928C2C],
        hp: 520000,
        weight: 20,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'pearl',
        name: 'Pearl',
        palette: [0xFF4A847C, 0xFFF1E8DC, 0xFFFFFFFF, 0xFFC8BCAE],
        hp: 720000,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'tide_engine',
        name: 'Tide Engine',
        desc: 'Runs on the moon pull.',
        cost: {'prismarine': 160},
        pps: 28000000,
      ),
      GearDef(
        id: 'kraken',
        name: 'Kraken',
        desc: 'Eight arms, eight pickaxes.',
        cost: {'pearl': 70, 'sponge': 120},
        pps: 85000000,
      ),
    ],
    ability: AbilityDef(
      id: 'undertow',
      name: 'Undertow',
      desc: '+30% PPS',
      ppsMul: 1.3,
    ),
  ),
  BiomeDef(
    id: 'lava_fields',
    name: 'Lava Fields',
    sky: [0xFF5A1E14, 0xFF9A3A1E],
    ground: 0xFF3A140E,
    accent: 0xFFF4622E,
    unlockCost: {'prismarine': 130, 'pearl': 50},
    unlockLabel: 'Prismarine and Pearls from the Ocean',
    blocks: [
      BlockDef(
        id: 'magma',
        name: 'Magma',
        palette: [0xFF4A1E12, 0xFFF4622E, 0xFFFF8A4A, 0xFF8A2E14],
        hp: 1300000,
        weight: 40,
        texture: TextureKind.cracks,
      ),
      BlockDef(
        id: 'basalt',
        name: 'Basalt',
        palette: [0xFF3A3638, 0xFF2C282A, 0xFF4A4448, 0xFF201C1E],
        hp: 1800000,
        weight: 30,
        texture: TextureKind.stripes,
      ),
      BlockDef(
        id: 'fire_crystal',
        name: 'Fire Crystal',
        palette: [0xFF4A1E12, 0xFFFFB02E, 0xFFFFD46B, 0xFFE87814],
        hp: 2500000,
        weight: 20,
        texture: TextureKind.gems,
      ),
      BlockDef(
        id: 'obsidian',
        name: 'Obsidian',
        palette: [0xFF1E1626, 0xFF14101C, 0xFF2E2440, 0xFF0C0812],
        hp: 3500000,
        weight: 10,
        texture: TextureKind.cracks,
      ),
    ],
    gear: [
      GearDef(
        id: 'magma_pump',
        name: 'Magma Pump',
        desc: 'Liquid rock in, blocks out.',
        cost: {'basalt': 160},
        pps: 260000000,
      ),
      GearDef(
        id: 'phoenix',
        name: 'Phoenix',
        desc: 'Burns, rebirths, brings you obsidian.',
        cost: {'fire_crystal': 100, 'obsidian': 40},
        pps: 800000000,
      ),
    ],
    ability: AbilityDef(
      id: 'molten_core',
      name: 'Molten Core',
      desc: '+40% swing damage',
      dmgMul: 1.4,
    ),
  ),
  BiomeDef(
    id: 'nether',
    name: 'Nether',
    sky: [0xFF3A0E14, 0xFF6E1E24],
    ground: 0xFF4A1218,
    accent: 0xFFB02E3C,
    unlockCost: {'basalt': 140, 'obsidian': 45},
    unlockLabel: 'Basalt and Obsidian from the Lava Fields',
    blocks: [
      BlockDef(
        id: 'netherrack',
        name: 'Netherrack',
        palette: [0xFF6E2E34, 0xFF5C242A, 0xFF7E3A40, 0xFF4C1C20],
        hp: 6500000,
        weight: 40,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'nether_quartz',
        name: 'Nether Quartz',
        palette: [0xFF6E2E34, 0xFFE8DCC8, 0xFFF4ECDC, 0xFFC8BAA4],
        hp: 8800000,
        weight: 30,
        texture: TextureKind.gems,
      ),
      BlockDef(
        id: 'nether_gold',
        name: 'Nether Gold',
        palette: [0xFF6E2E34, 0xFFF4C531, 0xFFFFDA6B, 0xFFC89A20],
        hp: 12000000,
        weight: 20,
        texture: TextureKind.gems,
      ),
      BlockDef(
        id: 'ancient_debris',
        name: 'Ancient Debris',
        palette: [0xFF4A3630, 0xFF3A2A24, 0xFF5C4438, 0xFF8A6A50],
        hp: 17000000,
        weight: 10,
        texture: TextureKind.speckled,
      ),
    ],
    gear: [
      GearDef(
        id: 'wither_cage',
        name: 'Wither Cage',
        desc: 'It mines because it cannot leave.',
        cost: {'nether_gold': 130},
        pps: 2500000000,
      ),
      GearDef(
        id: 'ghast_rig',
        name: 'Ghast Rig',
        desc: 'Tears condense into pure blocks.',
        cost: {'nether_quartz': 160, 'ancient_debris': 40},
        pps: 7500000000,
      ),
    ],
    ability: AbilityDef(
      id: 'soul_harvest',
      name: 'Soul Harvest',
      desc: '+50% picks from all sources',
      pickMul: 1.5,
    ),
  ),
  BiomeDef(
    id: 'moon',
    name: 'Moon',
    sky: [0xFF0C0E1A, 0xFF2A2E48],
    ground: 0xFF8A8E9C,
    accent: 0xFFB8BECC,
    unlockCost: {'nether_gold': 120, 'ancient_debris': 40},
    unlockLabel: 'Nether Gold and Debris from the Nether',
    blocks: [
      BlockDef(
        id: 'regolith',
        name: 'Regolith',
        palette: [0xFF9A9EAC, 0xFF868A98, 0xFFACB0BE, 0xFF70747F],
        hp: 30000000,
        weight: 40,
      ),
      BlockDef(
        id: 'moonstone',
        name: 'Moonstone',
        palette: [0xFFB8BECC, 0xFFA0A4B8, 0xFFCCD0DC, 0xFF8A8EA2],
        hp: 42000000,
        weight: 30,
        texture: TextureKind.cracks,
      ),
      BlockDef(
        id: 'meteor_iron',
        name: 'Meteor Iron',
        palette: [0xFF5C5A66, 0xFF4A4852, 0xFF6E6C78, 0xFFC89A72],
        hp: 58000000,
        weight: 20,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'lunarium',
        name: 'Lunarium',
        palette: [0xFF5C5A66, 0xFF9AE8F4, 0xFFC4F4FA, 0xFF5AC8DC],
        hp: 82000000,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'lander',
        name: 'Lunar Lander',
        desc: 'One small scoop, endlessly repeated.',
        cost: {'moonstone': 150},
        pps: 24000000000,
      ),
      GearDef(
        id: 'gravity_well',
        name: 'Gravity Well',
        desc: 'Blocks fall toward you now.',
        cost: {'meteor_iron': 130, 'lunarium': 40},
        pps: 70000000000,
      ),
    ],
    ability: AbilityDef(
      id: 'low_gravity',
      name: 'Low Gravity',
      desc: '+50% PPS',
      ppsMul: 1.5,
    ),
  ),
  BiomeDef(
    id: 'the_end',
    name: 'The End',
    sky: [0xFF0E0A18, 0xFF241A3C],
    ground: 0xFFDCE3A8,
    accent: 0xFF6A5ACD,
    unlockCost: {'moonstone': 140, 'lunarium': 45},
    unlockLabel: 'Moonstone and Lunarium from the Moon',
    blocks: [
      BlockDef(
        id: 'endstone',
        name: 'Endstone',
        palette: [0xFFDCE3A8, 0xFFC8CE8E, 0xFFEAEFBE, 0xFFAEb876],
        hp: 140000000,
        weight: 40,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'chorus',
        name: 'Chorus Fruit',
        palette: [0xFF8A5AA8, 0xFF724691, 0xFF9E6EBE, 0xFF5C3878],
        hp: 190000000,
        weight: 30,
        texture: TextureKind.speckled,
      ),
      BlockDef(
        id: 'purpur',
        name: 'Purpur',
        palette: [0xFFA87AB8, 0xFF9468A4, 0xFFBA8CC8, 0xFF80568F],
        hp: 260000000,
        weight: 20,
        texture: TextureKind.stripes,
      ),
      BlockDef(
        id: 'dragon_scale',
        name: 'Dragon Scale',
        palette: [0xFF2A1E3C, 0xFF6A5ACD, 0xFF8A7AE8, 0xFF1E1430],
        hp: 360000000,
        weight: 10,
        texture: TextureKind.gems,
      ),
    ],
    gear: [
      GearDef(
        id: 'ender_array',
        name: 'Ender Array',
        desc: 'Teleports blocks straight to your bags.',
        cost: {'purpur': 140},
        pps: 220000000000,
      ),
      GearDef(
        id: 'dragon_perch',
        name: 'Dragon Perch',
        desc: 'The dragon works for you now.',
        cost: {'chorus': 160, 'dragon_scale': 40},
        pps: 660000000000,
      ),
    ],
    ability: AbilityDef(
      id: 'ender_reach',
      name: 'Ender Reach',
      desc: '+1 block per break',
      dropAdd: 1,
    ),
  ),
];

BlockDef blockDef(String id) {
  for (final b in kBiomes) {
    for (final blk in b.blocks) {
      if (blk.id == id) return blk;
    }
  }
  throw ArgumentError('unknown block $id');
}

BiomeDef biomeDef(String id) => kBiomes.firstWhere((b) => b.id == id);

PickaxeDef pickaxeDef(String id) => kPickaxes.firstWhere((p) => p.id == id);

BiomeDef biomeOfBlock(String blockId) {
  for (final b in kBiomes) {
    if (b.blocks.any((blk) => blk.id == blockId)) return b;
  }
  throw ArgumentError('unknown block $blockId');
}
