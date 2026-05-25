export const ABILITIES = {
  basic_attack: {
    id: 'basic_attack',
    name: 'Attack',
    type: 'physical',
    element: 'none',
    mpCost: 0,
    power: 52,
    range: { min: 1, max: 1, shape: 'single', heightTolerance: 1 },
    target: 'enemy',
    timingProfile: 'none',
    effects: []
  },
  resonant_strike: {
    id: 'resonant_strike',
    name: 'Resonant Strike',
    type: 'hybrid',
    element: 'holy',
    mpCost: 8,
    power: 72,
    range: { min: 1, max: 1, shape: 'single', heightTolerance: 1 },
    target: 'enemy',
    timingProfile: 'holy',
    effects: [{ type: 'ether_damage', amount: 16 }]
  },
  sunder_strike: {
    id: 'sunder_strike',
    name: 'Sunder Strike',
    type: 'physical',
    element: 'none',
    mpCost: 8,
    power: 58,
    range: { min: 1, max: 1, shape: 'single', heightTolerance: 1 },
    target: 'enemy',
    timingProfile: 'none',
    effects: [{ type: 'temper_damage', amount: 52 }]
  },
  power_slash: {
    id: 'power_slash',
    name: 'Power Slash',
    type: 'physical',
    element: 'none',
    mpCost: 0,
    power: 88,
    range: { min: 1, max: 1, shape: 'single', heightTolerance: 1 },
    target: 'enemy',
    timingProfile: 'none',
    effects: [{ type: 'status', status: 'bleed', chance: 0.28, turns: 2 }]
  },
  cover: {
    id: 'cover',
    name: 'Cover',
    type: 'support',
    element: 'guard',
    mpCost: 10,
    power: 0,
    range: { min: 1, max: 3, shape: 'single', heightTolerance: 2 },
    target: 'ally',
    timingProfile: 'none',
    effects: [{ type: 'status', status: 'covered', turns: 2 }]
  },
  curaga: {
    id: 'curaga',
    name: 'Curaga',
    type: 'heal',
    element: 'holy',
    mpCost: 24,
    power: 110,
    range: { min: 0, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'ally',
    timingProfile: 'holy',
    effects: [{ type: 'heal_hp', amount: 110 }]
  },
  bulwark: {
    id: 'bulwark',
    name: 'Bulwark',
    type: 'support',
    element: 'guard',
    mpCost: 15,
    power: 0,
    range: { min: 0, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'ally',
    timingProfile: 'none',
    effects: [{ type: 'restore_temper', amount: 60 }]
  },
  veil: {
    id: 'veil',
    name: 'Veil',
    type: 'support',
    element: 'holy',
    mpCost: 15,
    power: 0,
    range: { min: 0, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'ally',
    timingProfile: 'none',
    effects: [{ type: 'restore_ether', amount: 60 }]
  },
  firebolt: {
    id: 'firebolt',
    name: 'Firebolt',
    type: 'magic',
    element: 'fire',
    mpCost: 18,
    power: 92,
    range: { min: 1, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'enemy',
    timingProfile: 'fire',
    effects: [{ type: 'status', status: 'burning', chance: 0.35, turns: 2 }]
  },
  frostbind: {
    id: 'frostbind',
    name: 'Frostbind',
    type: 'magic',
    element: 'ice',
    mpCost: 18,
    power: 82,
    range: { min: 1, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'enemy_or_tile',
    timingProfile: 'ice',
    effects: [{ type: 'terrain_reaction', element: 'ice' }]
  },
  spark_chain: {
    id: 'spark_chain',
    name: 'Spark Chain',
    type: 'magic',
    element: 'thunder',
    mpCost: 20,
    power: 76,
    range: { min: 1, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'enemy_or_tile',
    timingProfile: 'thunder',
    effects: [{ type: 'terrain_reaction', element: 'thunder' }]
  },
  resonate: {
    id: 'resonate',
    name: 'Resonate',
    type: 'objective',
    element: 'resonance',
    mpCost: 30,
    power: 0,
    range: { min: 1, max: 2, shape: 'single', heightTolerance: 2 },
    target: 'objective',
    timingProfile: 'holy',
    effects: [{ type: 'shatter_void_anchor' }]
  },
  // Healer abilities
  protect: {
    id: 'protect',
    name: 'Protect',
    type: 'support',
    element: 'guard',
    mpCost: 20,
    power: 0,
    range: { min: 0, max: 4, shape: 'single', heightTolerance: 3 },
    target: 'ally',
    timingProfile: 'none',
    effects: [{ type: 'status', status: 'protected', turns: 2 }]
  },
  mend: {
    id: 'mend',
    name: 'Mend',
    type: 'heal',
    element: 'holy',
    mpCost: 14,
    power: 60,
    range: { min: 0, max: 3, shape: 'single', heightTolerance: 2 },
    target: 'ally',
    timingProfile: 'holy',
    effects: [{ type: 'heal_hp', amount: 60 }]
  },
  // Physical DPS abilities
  double_strike: {
    id: 'double_strike',
    name: 'Double Strike',
    type: 'physical',
    element: 'none',
    mpCost: 0,
    power: 110,
    range: { min: 1, max: 1, shape: 'single', heightTolerance: 1 },
    target: 'enemy',
    timingProfile: 'none',
    effects: [{ type: 'status', status: 'bleed', chance: 0.4, turns: 2 }]
  },
  // Elemental spells for casters
  firaga: {
    id: 'firaga',
    name: 'Firaga',
    type: 'magic',
    element: 'fire',
    mpCost: 30,
    power: 120,
    range: { min: 1, max: 5, shape: 'single', heightTolerance: 3 },
    target: 'enemy',
    timingProfile: 'fire',
    effects: [{ type: 'status', status: 'burning', chance: 0.45, turns: 3 }]
  },
  inferno: {
    id: 'inferno',
    name: 'Inferno',
    type: 'magic',
    element: 'fire',
    mpCost: 45,
    power: 160,
    range: { min: 2, max: 4, shape: 'aoe', aoeRadius: 1, heightTolerance: 2 },
    target: 'enemy',
    timingProfile: 'fire',
    effects: [{ type: 'status', status: 'burning', chance: 0.55, turns: 3 }]
  },
  flare: {
    id: 'flare',
    name: 'Flare',
    type: 'magic',
    element: 'fire',
    mpCost: 60,
    power: 200,
    range: { min: 1, max: 6, shape: 'single', heightTolerance: 3 },
    target: 'enemy',
    timingProfile: 'fire',
    effects: [{ type: 'status', status: 'burning', chance: 0.6, turns: 4 }]
  },
  thunderbolt: {
    id: 'thunderbolt',
    name: 'Thunderbolt',
    type: 'magic',
    element: 'thunder',
    mpCost: 28,
    power: 110,
    range: { min: 1, max: 5, shape: 'single', heightTolerance: 3 },
    target: 'enemy',
    timingProfile: 'thunder',
    effects: [{ type: 'terrain_reaction', element: 'thunder' }]
  },
  blizzaga: {
    id: 'blizzaga',
    name: 'Blizzaga',
    type: 'magic',
    element: 'ice',
    mpCost: 32,
    power: 125,
    range: { min: 1, max: 5, shape: 'single', heightTolerance: 3 },
    target: 'enemy',
    timingProfile: 'ice',
    effects: [{ type: 'terrain_reaction', element: 'ice' }]
  }
}

export const getAbility = (abilityId) => ABILITIES[abilityId] || ABILITIES.basic_attack

export const getUnitAbilities = (unit) => ['basic_attack', ...(unit?.abilities || [])].map(getAbility)
