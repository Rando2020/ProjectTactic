export const TERRAIN = {
  grass: { id: 'grass', name: 'Grass', moveCost: 1, heightCost: 1, defense: 0, tags: [] },
  road: { id: 'road', name: 'Road', moveCost: 1, heightCost: 1, defense: 0, tags: ['route'] },
  stone: { id: 'stone', name: 'Stone', moveCost: 1, heightCost: 1, defense: 5, tags: ['stable'] },
  shrine: { id: 'shrine', name: 'Shrine Stone', moveCost: 1, heightCost: 1, defense: 8, etherDefense: 8, tags: ['arcane'] },
  shallow_water: { id: 'shallow_water', name: 'Shallow Water', moveCost: 2, heightCost: 1, defense: -5, tags: ['wet', 'conductive'], reactions: { ice: 'freeze_tile', thunder: 'electrify_chain' } },
  deep_water: { id: 'deep_water', name: 'Deep Water', moveCost: 99, heightCost: 99, blocked: true, tags: ['water', 'blocked'] },
  ice: { id: 'ice', name: 'Ice', moveCost: 2, heightCost: 1, defense: -4, tags: ['frozen', 'slippery'], reactions: { thunder: 'shatter_tile', fire: 'melt_tile' } },
  burning: { id: 'burning', name: 'Burning Ground', moveCost: 2, heightCost: 1, defense: -8, tags: ['burning'], startTurnDamage: 18, reactions: { water: 'steam_cloud', ice: 'cryo_douse' } },
  wall: { id: 'wall', name: 'Wall', moveCost: 99, heightCost: 99, blocked: true, blocksLineOfSight: true, tags: ['blocked'] },
  high_ground: { id: 'high_ground', name: 'High Ground', moveCost: 1, heightCost: 2, defense: 6, tags: ['height'] }
}

export const getTerrain = (terrainId) => TERRAIN[terrainId] || TERRAIN.grass
