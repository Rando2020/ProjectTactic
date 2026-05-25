export const ENEMIES = {
  // FRONTLINE / BRUISER
  null_drake: {
    id: 'null_drake',
    name: 'Null Drake',
    faction: 'void',
    role: 'Intro bruiser',
    aiProfile: 'aggressive_bruiser',
    level: 1,
    stats: {
      hp: 260,
      mp: 30,
      move: 4,
      jump: 2,
      speed: 6,
      physical: 46,
      magic: 16,
      temper: 90,
      ether: 45
    },
    affinities: ['dark'],
    weaknesses: ['holy', 'ice'],
    abilities: ['basic_attack', 'power_slash'],
    sprite: '/src/game/assets/placeholders/units/null_drake_idle.png',
    drops: { gold: 40, jp: 12, items: [] }
  },

  // RANGED / DISRUPTOR
  storm_imp: {
    id: 'storm_imp',
    name: 'Storm Imp',
    faction: 'void',
    role: 'Fast ranged caster',
    aiProfile: 'ranged_disruptor',
    level: 1,
    stats: {
      hp: 180,
      mp: 80,
      move: 5,
      jump: 2,
      speed: 9,
      physical: 18,
      magic: 42,
      temper: 35,
      ether: 75
    },
    affinities: ['thunder', 'dark'],
    weaknesses: ['earth'],
    abilities: ['basic_attack', 'spark_chain', 'thunderbolt'],
    sprite: '/src/game/assets/placeholders/units/storm_imp_idle.png',
    drops: { gold: 32, jp: 14, items: [] }
  },

  // TERRAIN / COMBO CASTER
  fen_wraith: {
    id: 'fen_wraith',
    name: 'Fen Wraith',
    faction: 'void',
    role: 'Terrain abuser',
    aiProfile: 'terrain_caster',
    level: 2,
    stats: {
      hp: 220,
      mp: 100,
      move: 4,
      jump: 2,
      speed: 7,
      physical: 22,
      magic: 52,
      temper: 45,
      ether: 110
    },
    affinities: ['water', 'dark'],
    weaknesses: ['holy', 'thunder'],
    abilities: ['basic_attack', 'frostbind', 'spark_chain', 'blizzaga'],
    sprite: '/src/game/assets/placeholders/units/fen_wraith_idle.png',
    drops: { gold: 55, jp: 18, items: ['resonance_phial'] }
  },

  // TANK / WALL
  void_golem: {
    id: 'void_golem',
    name: 'Void Golem',
    faction: 'void',
    role: 'Slow armor tank',
    aiProfile: 'slow_tank',
    level: 2,
    stats: {
      hp: 420,
      mp: 20,
      move: 3,
      jump: 1,
      speed: 4,
      physical: 60,
      magic: 12,
      temper: 180,
      ether: 60
    },
    affinities: ['earth', 'dark'],
    weaknesses: ['water', 'holy'],
    abilities: ['basic_attack', 'sunder_strike'],
    sprite: '/src/game/assets/placeholders/units/void_golem_idle.png',
    drops: { gold: 75, jp: 22, items: ['ironcore_shard'] }
  },

  // NEW: HEALER
  void_vessel: {
    id: 'void_vessel',
    name: 'Void Vessel',
    faction: 'void',
    role: 'Defensive support healer',
    aiProfile: 'defensive_healer',
    level: 2,
    stats: {
      hp: 200,
      mp: 140,
      move: 4,
      jump: 1,
      speed: 5,
      physical: 20,
      magic: 45,
      temper: 55,
      ether: 120
    },
    affinities: ['water', 'dark'],
    weaknesses: ['holy', 'thunder'],
    abilities: ['basic_attack', 'protect', 'mend', 'curaga'],
    sprite: '/src/game/assets/placeholders/units/void_vessel_idle.png',
    drops: { gold: 65, jp: 20, items: [] }
  },

  // NEW: PHYSICAL GLASS CANNON
  void_mantis: {
    id: 'void_mantis',
    name: 'Void Mantis',
    faction: 'void',
    role: 'Glass cannon physical damage',
    aiProfile: 'aggressive_dps',
    level: 2,
    stats: {
      hp: 160,
      mp: 40,
      move: 5,
      jump: 3,
      speed: 8,
      physical: 58,
      magic: 18,
      temper: 75,
      ether: 40
    },
    affinities: ['dark'],
    weaknesses: ['holy', 'earth'],
    abilities: ['basic_attack', 'power_slash', 'double_strike'],
    sprite: '/src/game/assets/placeholders/units/void_mantis_idle.png',
    drops: { gold: 48, jp: 16, items: [] }
  },

  // NEW: SPELL FOCUSED CASTER
  null_mage: {
    id: 'null_mage',
    name: 'Null Mage',
    faction: 'void',
    role: 'Spell-focused elemental caster',
    aiProfile: 'spell_focused',
    level: 2,
    stats: {
      hp: 170,
      mp: 130,
      move: 4,
      jump: 1,
      speed: 6,
      physical: 15,
      magic: 56,
      temper: 30,
      ether: 110
    },
    affinities: ['fire', 'dark'],
    weaknesses: ['water', 'earth'],
    abilities: ['basic_attack', 'firaga', 'inferno', 'flare'],
    sprite: '/src/game/assets/placeholders/units/null_mage_idle.png',
    drops: { gold: 58, jp: 19, items: [] }
  }
}

export const getEnemy = (enemyId) => ENEMIES[enemyId]

export function instantiateEnemy(enemyId, spawn = {}) {
  const template = getEnemy(enemyId)
  if (!template) return null

  return {
    ...template,
    team: 'enemy',
    hp: template.stats.hp,
    mp: template.stats.mp,
    temper: template.stats.temper,
    ether: template.stats.ether,
    x: spawn.x ?? 0,
    y: spawn.y ?? 0,
    facing: spawn.facing || 'S',
    ct: 0,
    statuses: []
  }
}

/**
 * Get valid enemy team compositions based on mission difficulty
 * Ensures variety: healers, mages, bruisers, tanks
 */
export function generateEnemyComposition(difficulty = 'normal', pool = Object.keys(ENEMIES)) {
  const compositions = {
    easy: [
      ['null_drake'],
      ['storm_imp'],
      ['null_drake', 'storm_imp'],
      ['null_mantis', 'null_drake']
    ],
    normal: [
      ['null_drake', 'void_golem'],
      ['storm_imp', 'fen_wraith', 'null_drake'],
      ['null_mantis', 'void_vessel'],
      ['null_mage', 'null_drake', 'storm_imp'],
      ['void_golem', 'null_mage'],
      ['fen_wraith', 'null_drake', 'void_vessel']
    ],
    hard: [
      ['null_mantis', 'null_mage', 'void_vessel', 'void_golem'],
      ['storm_imp', 'fen_wraith', 'null_mantis', 'void_vessel'],
      ['null_mage', 'null_mage', 'void_golem', 'null_drake'],
      ['null_mantis', 'void_vessel', 'fen_wraith', 'null_drake']
    ],
    extreme: [
      ['null_mantis', 'null_mage', 'null_mantis', 'void_vessel'],
      ['fen_wraith', 'null_mage', 'void_golem', 'null_mantis'],
      ['storm_imp', 'storm_imp', 'null_mage', 'void_vessel']
    ]
  }

  const options = compositions[difficulty] || compositions.normal
  return options[Math.floor(Math.random() * options.length)]
}
