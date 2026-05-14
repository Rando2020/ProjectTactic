export const ENEMIES = {
  null_drake: {
    id: 'null_drake',
    name: 'Null Drake',
    faction: 'void',
    role: 'Intro bruiser that pressures Temper',
    level: 1,
    aiProfile: 'aggressive_bruiser',
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
  storm_imp: {
    id: 'storm_imp',
    name: 'Storm Imp',
    faction: 'void',
    role: 'Fast caster that teaches DEFLECT and ranged threat',
    level: 1,
    aiProfile: 'ranged_disruptor',
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
    abilities: ['basic_attack', 'spark_chain'],
    sprite: '/src/game/assets/placeholders/units/storm_imp_idle.png',
    drops: { gold: 32, jp: 14, items: [] }
  },
  fen_wraith: {
    id: 'fen_wraith',
    name: 'Fen Wraith',
    faction: 'void',
    role: 'Marsh enemy that abuses Wet and Ether pressure',
    level: 2,
    aiProfile: 'terrain_caster',
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
    abilities: ['basic_attack', 'frostbind', 'spark_chain'],
    sprite: '/src/game/assets/placeholders/units/fen_wraith_idle.png',
    drops: { gold: 55, jp: 18, items: ['resonance_phial'] }
  },
  void_golem: {
    id: 'void_golem',
    name: 'Void Golem',
    faction: 'void',
    role: 'Slow armor wall that forces Sunder usage',
    level: 2,
    aiProfile: 'slow_tank',
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
