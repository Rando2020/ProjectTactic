export const JOBS = {
  warder: {
    id: 'warder',
    name: 'Warder',
    role: 'Frontline physical defender',
    moveMod: 0,
    jumpMod: 0,
    weaponTypes: ['sword', 'shield'],
    abilities: ['power_slash', 'sunder_strike', 'cover'],
    reaction: 'deflect_guard',
    passive: 'temper_stance',
    growth: { hp: 1.2, physical: 1.1, temper: 1.25 }
  },
  arcanist: {
    id: 'arcanist',
    name: 'Arcanist',
    role: 'Elemental spellcaster and combo engine',
    moveMod: -1,
    jumpMod: 0,
    weaponTypes: ['staff', 'wand'],
    abilities: ['firaga', 'blizzaga', 'thundaga', 'flare'],
    reaction: 'ether_guard',
    passive: 'combo_memory',
    growth: { mp: 1.25, magic: 1.25, ether: 1.1 }
  },
  resonant: {
    id: 'resonant',
    name: 'Resonant',
    role: 'Guardian-bonded hybrid support',
    moveMod: 0,
    jumpMod: 0,
    weaponTypes: ['blade', 'focus'],
    abilities: ['resonant_strike', 'aura', 'mana_flow'],
    reaction: 'resonance_pulse',
    passive: 'guardian_attunement',
    growth: { hp: 1.05, mp: 1.1, magic: 1.1, ether: 1.15 }
  },
  luminary: {
    id: 'luminary',
    name: 'Luminary',
    role: 'Healer, purifier, Ether restorer',
    moveMod: 0,
    jumpMod: 0,
    weaponTypes: ['staff', 'focus'],
    abilities: ['curaga', 'bulwark', 'veil', 'raise'],
    reaction: 'blessed_recovery',
    passive: 'kindled_light',
    growth: { mp: 1.2, magic: 1.15, ether: 1.25 }
  },
  skywarden: {
    id: 'skywarden',
    name: 'Skywarden',
    role: 'Jump attacker and backline diver',
    moveMod: 1,
    jumpMod: 2,
    weaponTypes: ['spear'],
    abilities: ['dragon_jump', 'lancet', 'dragon_fang'],
    reaction: 'aerial_shift',
    passive: 'high_ground_hunter',
    growth: { hp: 1.1, physical: 1.15, speed: 1.05 }
  }
}

export const getJob = (jobId) => JOBS[jobId]
