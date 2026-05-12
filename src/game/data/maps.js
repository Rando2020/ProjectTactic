export const BATTLE_MAPS = {
  ashvale_road_01: {
    id: 'ashvale_road_01',
    name: 'Eastern Road: Null Drake Ambush',
    region: 'Vaelthar Lowlands',
    objective: { type: 'defeat_all', label: 'Defeat all enemies' },
    size: { width: 10, height: 8 },
    defaultTerrain: 'grass',
    maxPartySize: 2,
    requiredUnitIds: ['zane'],
    recommendedUnitIds: ['zane', 'mira'],
    deployment: {
      label: 'Ashvale Road Approach',
      briefing: 'Place your units along the southern road before pushing toward the shrine ridge.',
      defaultFacing: 'N',
      zones: [
        { id: 'south_road', name: 'Southern Road', tiles: [{ x: 1, y: 6 }, { x: 2, y: 6 }, { x: 1, y: 5 }, { x: 2, y: 5 }] }
      ]
    },
    tiles: [
      ...Array.from({ length: 10 }, (_, x) => ({ x, y: 3, terrain: 'road', height: 0 })),
      ...Array.from({ length: 10 }, (_, x) => ({ x, y: 4, terrain: 'road', height: 0 })),
      { x: 0, y: 0, terrain: 'wall', height: 2 },
      { x: 1, y: 0, terrain: 'wall', height: 2 },
      { x: 6, y: 1, terrain: 'high_ground', height: 1 },
      { x: 7, y: 1, terrain: 'high_ground', height: 1 },
      { x: 6, y: 2, terrain: 'high_ground', height: 1 },
      { x: 2, y: 5, terrain: 'stone', height: 0 },
      { x: 3, y: 5, terrain: 'stone', height: 0 },
      { x: 8, y: 6, terrain: 'shrine', height: 1 }
    ],
    playerSpawns: [
      { unitId: 'zane', x: 1, y: 6, facing: 'N' },
      { unitId: 'mira', x: 2, y: 6, facing: 'N' }
    ],
    enemySpawns: [
      { unitId: 'null_drake', x: 7, y: 2, facing: 'S' },
      { unitId: 'storm_imp', x: 8, y: 4, facing: 'W' }
    ],
    rewards: { gold: 120, jp: 30, items: ['vitae_draught'], flags: ['completed_intro_battle'] }
  },

  mirefen_marsh_01: {
    id: 'mirefen_marsh_01',
    name: 'Mirefen Reach: Conductive Marsh',
    region: 'Flooded Lowlands',
    objective: { type: 'defeat_all', label: 'Defeat all enemies using terrain reactions' },
    size: { width: 10, height: 8 },
    defaultTerrain: 'grass',
    maxPartySize: 3,
    requiredUnitIds: ['zane'],
    recommendedUnitIds: ['zane', 'mira', 'kael'],
    deployment: {
      label: 'Mirefen Marsh Entry',
      briefing: 'Choose whether to cluster near the dry path or split across the reeds before the water turns against you.',
      defaultFacing: 'N',
      zones: [
        { id: 'dry_bank', name: 'Dry Bank', tiles: [{ x: 1, y: 6 }, { x: 2, y: 6 }, { x: 1, y: 5 }] },
        { id: 'reed_edge', name: 'Reed Edge', tiles: [{ x: 3, y: 6 }, { x: 2, y: 5 }, { x: 3, y: 5 }] }
      ]
    },
    tiles: [
      ...Array.from({ length: 6 }, (_, i) => ({ x: 2 + i, y: 3, terrain: 'shallow_water', height: 0 })),
      ...Array.from({ length: 6 }, (_, i) => ({ x: 2 + i, y: 4, terrain: 'shallow_water', height: 0 })),
      { x: 5, y: 2, terrain: 'stone', height: 1 },
      { x: 6, y: 2, terrain: 'stone', height: 1 },
      { x: 1, y: 1, terrain: 'deep_water', height: 0 },
      { x: 8, y: 6, terrain: 'deep_water', height: 0 }
    ],
    playerSpawns: [
      { unitId: 'zane', x: 1, y: 6, facing: 'N' },
      { unitId: 'mira', x: 2, y: 6, facing: 'N' },
      { unitId: 'kael', x: 1, y: 5, facing: 'N' }
    ],
    enemySpawns: [
      { unitId: 'fen_wraith', x: 7, y: 2, facing: 'S' },
      { unitId: 'null_drake', x: 8, y: 3, facing: 'W' }
    ],
    rewards: { gold: 180, jp: 55, items: ['resonance_phial'], flags: ['completed_mirefen_trial'] }
  }
}

export const getBattleMap = (mapId) => BATTLE_MAPS[mapId]
