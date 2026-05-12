export const TERRAIN = {
  grass: {
    id: 'grass',
    name: 'Grass',
    moveCost: 1,
    heightCost: 1,
    defense: 0,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['natural'],
    reactions: {}
  },
  road: {
    id: 'road',
    name: 'Road',
    moveCost: 1,
    heightCost: 1,
    defense: 0,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['route'],
    reactions: {}
  },
  stone: {
    id: 'stone',
    name: 'Stone',
    moveCost: 1,
    heightCost: 1,
    defense: 5,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['stable', 'constructed'],
    reactions: {}
  },
  shrine: {
    id: 'shrine',
    name: 'Shrine Stone',
    moveCost: 1,
    heightCost: 1,
    defense: 8,
    etherDefense: 8,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['arcane', 'resonant'],
    reactions: { dark: 'void_scar', holy: 'sanctify_tile' }
  },
  shallow_water: {
    id: 'shallow_water',
    name: 'Shallow Water',
    moveCost: 2,
    heightCost: 1,
    defense: -5,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['wet', 'conductive'],
    reactions: { ice: 'freeze_tile', thunder: 'electrify_chain', earth: 'muddy_tile' }
  },
  deep_water: {
    id: 'deep_water',
    name: 'Deep Water',
    moveCost: 99,
    heightCost: 99,
    defense: 0,
    blocked: true,
    blocksMovement: true,
    blocksLineOfSight: false,
    tags: ['water', 'blocked'],
    reactions: { ice: 'freeze_bridge', thunder: 'electrify_chain' }
  },
  ice: {
    id: 'ice',
    name: 'Ice',
    moveCost: 2,
    heightCost: 1,
    defense: -4,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['frozen', 'slippery'],
    reactions: { thunder: 'shatter_tile', fire: 'melt_tile' }
  },
  burning: {
    id: 'burning',
    name: 'Burning Ground',
    moveCost: 2,
    heightCost: 1,
    defense: -8,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['burning', 'hazard'],
    hazard: { element: 'fire', damage: 18 },
    startTurnDamage: 18,
    reactions: { water: 'steam_cloud', ice: 'cryo_douse' }
  },
  electrified_water: {
    id: 'electrified_water',
    name: 'Electrified Water',
    moveCost: 2,
    heightCost: 1,
    defense: -8,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['wet', 'conductive', 'hazard'],
    hazard: { element: 'thunder', damage: 24, status: 'stun' },
    reactions: { earth: 'ground_charge', ice: 'freeze_tile' }
  },
  wall: {
    id: 'wall',
    name: 'Wall',
    moveCost: 99,
    heightCost: 99,
    defense: 0,
    blocked: true,
    blocksMovement: true,
    blocksLineOfSight: true,
    tags: ['blocked'],
    reactions: {}
  },
  high_ground: {
    id: 'high_ground',
    name: 'High Ground',
    moveCost: 1,
    heightCost: 2,
    defense: 6,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['height'],
    reactions: {}
  },
  void_anchor: {
    id: 'void_anchor',
    name: 'Void Anchor',
    moveCost: 2,
    heightCost: 1,
    defense: -10,
    etherDefense: -10,
    blocksMovement: false,
    blocksLineOfSight: false,
    tags: ['void', 'objective', 'hazard'],
    hazard: { element: 'dark', damage: 12, etherDamage: 10 },
    reactions: { holy: 'expose_anchor', resonance: 'shatter_anchor' }
  }
}

export const getTerrain = (terrainId) => TERRAIN[terrainId] || TERRAIN.grass

export const getMoveCost = (terrainId) => getTerrain(terrainId).moveCost

export const isBlockingTerrain = (terrainId) => Boolean(getTerrain(terrainId).blocked || getTerrain(terrainId).blocksMovement)

export const blocksLineOfSight = (terrainId) => Boolean(getTerrain(terrainId).blocksLineOfSight)

export const getTerrainReaction = (terrainId, element) => getTerrain(terrainId).reactions?.[element] || null
