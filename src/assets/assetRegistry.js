// Central browser asset registry for ProjectTactic.
//
// This file intentionally maps stable gameplay IDs to planned asset paths.
// Some referenced files are placeholders that may not exist yet. Keep these IDs
// stable so generated assets can be dropped into the expected folders without
// forcing gameplay systems to change imports repeatedly.

export const assetRegistry = {
  tiles: {
    grass: {
      id: 'grass',
      label: 'Grass',
      path: '/src/assets/tiles/grass-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    dirt: {
      id: 'dirt',
      label: 'Dirt',
      path: '/src/assets/tiles/dirt-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    road: {
      id: 'road',
      label: 'Road',
      path: '/src/assets/tiles/stone-road-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    stone: {
      id: 'stone',
      label: 'Stone',
      path: '/src/assets/tiles/stone-floor-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    wall: {
      id: 'wall',
      label: 'Wall',
      path: '/src/assets/tiles/wall-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    water: {
      id: 'water',
      label: 'Water',
      path: '/src/assets/tiles/water-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    shrine: {
      id: 'shrine',
      label: 'Shrine',
      path: '/src/assets/tiles/shrine-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    },
    highGround: {
      id: 'high-ground',
      label: 'High Ground',
      path: '/src/assets/tiles/high-ground-tile-placeholder.png',
      promptSource: 'docs/prompts/tilesets-terrain.md'
    }
  },

  overlays: {
    wet: '/src/assets/tiles/wet-overlay-placeholder.png',
    burning: '/src/assets/tiles/burning-overlay-placeholder.png',
    frozen: '/src/assets/tiles/frozen-overlay-placeholder.png',
    electrified: '/src/assets/tiles/electrified-overlay-placeholder.png'
  },

  highlights: {
    selected: '/src/assets/ui/tile-selected-diamond.png',
    move: '/src/assets/ui/tile-move-diamond.png',
    attack: '/src/assets/ui/tile-attack-diamond.png',
    ability: '/src/assets/ui/tile-ability-diamond.png',
    blocked: '/src/assets/ui/tile-blocked-diamond.png'
  },

  units: {
    zane: {
      id: 'zane',
      displayName: 'Zane',
      role: 'Swordsman',
      idle: '/src/assets/characters/zane-idle-placeholder.png',
      action: '/src/assets/characters/zane-action-placeholder.png',
      portrait: '/src/assets/characters/zane-portrait-placeholder.png',
      promptSource: 'docs/prompts/characters-player-units.md'
    },
    mira: {
      id: 'mira',
      displayName: 'Mira',
      role: 'Archer',
      idle: '/src/assets/characters/mira-idle-placeholder.png',
      action: '/src/assets/characters/mira-action-placeholder.png',
      portrait: '/src/assets/characters/mira-portrait-placeholder.png',
      promptSource: 'docs/prompts/characters-player-units.md'
    },
    kael: {
      id: 'kael',
      displayName: 'Kael',
      role: 'Mage',
      idle: '/src/assets/characters/kael-idle-placeholder.png',
      action: '/src/assets/characters/kael-action-placeholder.png',
      portrait: '/src/assets/characters/kael-portrait-placeholder.png',
      promptSource: 'docs/prompts/characters-player-units.md'
    }
  },

  enemies: {
    nullDrake: {
      id: 'null-drake',
      displayName: 'Null Drake',
      idle: '/src/assets/characters/null-drake-idle-placeholder.png',
      attack: '/src/assets/characters/null-drake-attack-placeholder.png',
      promptSource: 'docs/prompts/characters-enemies.md'
    },
    stormImp: {
      id: 'storm-imp',
      displayName: 'Storm Imp',
      idle: '/src/assets/characters/storm-imp-idle-placeholder.png',
      attack: '/src/assets/characters/storm-imp-attack-placeholder.png',
      promptSource: 'docs/prompts/characters-enemies.md'
    },
    fenWraith: {
      id: 'fen-wraith',
      displayName: 'Fen Wraith',
      idle: '/src/assets/characters/fen-wraith-idle-placeholder.png',
      attack: '/src/assets/characters/fen-wraith-attack-placeholder.png',
      promptSource: 'docs/prompts/characters-enemies.md'
    }
  },

  ui: {
    panels: {
      darkStone: '/src/assets/ui/dark-stone-panel.png',
      commandBar: '/src/assets/ui/command-bar-panel.png',
      turnOrderSidebar: '/src/assets/ui/turn-order-sidebar-panel.png'
    },
    commandIcons: {
      move: '/src/assets/icons/command-move-icon.png',
      attack: '/src/assets/icons/command-attack-icon.png',
      ability: '/src/assets/icons/command-ability-icon.png',
      item: '/src/assets/icons/command-item-icon.png',
      wait: '/src/assets/icons/command-wait-icon.png'
    },
    bars: {
      hp: '/src/assets/ui/hp-bar-frame.png',
      temper: '/src/assets/ui/temper-bar-frame.png',
      ether: '/src/assets/ui/ether-bar-frame.png'
    }
  },

  jobs: {
    knight: '/src/assets/icons/job-knight-icon.png',
    mage: '/src/assets/icons/job-mage-icon.png',
    cleric: '/src/assets/icons/job-cleric-icon.png',
    rogue: '/src/assets/icons/job-rogue-icon.png',
    archer: '/src/assets/icons/job-archer-icon.png',
    guardian: '/src/assets/icons/job-guardian-icon.png'
  },

  vfx: {
    fireImpact: '/src/assets/vfx/fire-impact-vfx-sheet.png',
    iceImpact: '/src/assets/vfx/ice-impact-vfx-sheet.png',
    lightningImpact: '/src/assets/vfx/lightning-impact-vfx-sheet.png',
    earthImpact: '/src/assets/vfx/earth-impact-vfx-sheet.png',
    windImpact: '/src/assets/vfx/wind-impact-vfx-sheet.png',
    damageNumbers: '/src/assets/vfx/damage-number-floats.png'
  },

  guardians: {
    titan: '/src/assets/characters/titan-guardian-summon.png',
    siren: '/src/assets/characters/siren-guardian-summon.png'
  }
}

export function getAsset(category, key) {
  return assetRegistry?.[category]?.[key] ?? null
}

export function getUnitAsset(unitId) {
  return assetRegistry.units[unitId] ?? assetRegistry.enemies[unitId] ?? null
}

export default assetRegistry
