export const GUARDIANS = {
  ignareth: {
    id: 'ignareth',
    name: 'Ignareth',
    element: 'Fire',
    tier: 'Primal Guardian',
    status: 'corrupted',
    description: 'The Eternal Flame, now screaming through a Void Anchor beneath ash and glass.',
    combatRole: 'Area burn pressure and field ignition',
    unlock: 'Free Ignareth through a Resonance Window.'
  },
  nerevan: {
    id: 'nerevan',
    name: 'Nerevan',
    element: 'Water',
    tier: 'Primal Guardian',
    status: 'rumored',
    description: 'The Tide Eternal. Mirefen’s waters have started reflecting events before they happen.',
    combatRole: 'Wet setup, reaction enabling, and field control',
    unlock: 'Investigate Mirefen Reach.'
  },
  torvahk: {
    id: 'torvahk',
    name: 'Torvahk',
    element: 'Thunder',
    tier: 'Primal Guardian',
    status: 'rumored',
    description: 'The Storm Father. Stormglass Bastion hears grief inside the thunder.',
    combatRole: 'Multi-hit pressure, stun windows, and fast SURGE rhythm',
    unlock: 'Complete Stormglass timing trials.'
  },
  luminarch: {
    id: 'luminarch',
    name: 'Luminarch',
    element: 'Holy',
    tier: 'Primal Guardian',
    status: 'locked',
    description: 'The Sacred Light. Old abbey records describe a Guardian that heals and judges in the same breath.',
    combatRole: 'Party healing, cleanse, and Ether restoration',
    unlock: 'Reach Lumenrest Abbey in a future chapter.'
  },
  vaelthorn: {
    id: 'vaelthorn',
    name: 'Vaelthorn',
    element: 'Dark',
    tier: 'Primal Guardian',
    status: 'locked',
    description: 'The Shadow That Was. Some scholars insist Vaelthorn is not corrupted. It is remembering what came before light.',
    combatRole: 'Dark burst, curse, drain, and endgame summon pressure',
    unlock: 'Discover the truth of the Null Conclave.'
  }
}

export const getGuardians = () => Object.values(GUARDIANS)
