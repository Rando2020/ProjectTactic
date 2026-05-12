export const PLAYER_UNITS = {
  zane: {
    id: 'zane',
    name: 'Zane',
    faction: 'party',
    role: 'Resonant protagonist',
    baseJobId: 'resonant',
    level: 1,
    stats: {
      hp: 320,
      mp: 90,
      move: 4,
      jump: 2,
      speed: 8,
      physical: 42,
      magic: 48,
      temper: 80,
      ether: 110
    },
    affinities: ['holy', 'dark'],
    abilities: ['resonant_strike', 'aura', 'mana_flow'],
    portrait: '/src/game/assets/placeholders/portraits/zane.png',
    sprite: '/src/game/assets/placeholders/units/zane_idle.png'
  },
  mira: {
    id: 'mira',
    name: 'Mira Vey',
    faction: 'party',
    role: 'Field medic and reluctant guide',
    baseJobId: 'luminary',
    level: 1,
    stats: {
      hp: 280,
      mp: 120,
      move: 4,
      jump: 2,
      speed: 7,
      physical: 28,
      magic: 54,
      temper: 65,
      ether: 130
    },
    affinities: ['holy', 'water'],
    abilities: ['curaga', 'bulwark', 'veil'],
    portrait: '/src/game/assets/placeholders/portraits/mira.png',
    sprite: '/src/game/assets/placeholders/units/mira_idle.png'
  },
  kael: {
    id: 'kael',
    name: 'Kael Orik',
    faction: 'party',
    role: 'Stormglass tactical instructor',
    baseJobId: 'warder',
    level: 2,
    stats: {
      hp: 380,
      mp: 55,
      move: 4,
      jump: 2,
      speed: 6,
      physical: 58,
      magic: 22,
      temper: 130,
      ether: 55
    },
    affinities: ['thunder'],
    abilities: ['power_slash', 'sunder_strike', 'cover'],
    portrait: '/src/game/assets/placeholders/portraits/kael.png',
    sprite: '/src/game/assets/placeholders/units/warder_idle.png'
  }
}

export const getPlayerUnit = (unitId) => PLAYER_UNITS[unitId]

export function instantiatePlayerUnit(unitId, spawn = {}) {
  const template = getPlayerUnit(unitId)
  if (!template) return null

  return {
    ...template,
    team: 'player',
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
