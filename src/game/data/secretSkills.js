/**
 * secretSkills.js
 * Secret techniques — learned only from wandering characters.
 * More powerful than regular JP abilities. Each unit can hold 1 secret slot.
 * Not purchasable, not in normal ability pool.
 */

export const SECRET_SKILLS = {

  // ── Zane (Resonant) ───────────────────────────────────────────────────────
  resonance_fracture: {
    id: 'resonance_fracture', name: 'Resonance Fracture',
    element: 'resonance', target: 'all_enemies', range: 5,
    power: 90, mpCost: 60, teacherRequired: 'the_wandering_null',
    description: 'Zane fractures the resonant field — dealing 90 damage to all enemies and stripping one status from each.',
    flavour: 'The resonance is not yours to command. It is yours to release.',
    icon: '💠',
  },
  null_break: {
    id: 'null_break', name: 'Null-Break',
    element: 'resonance', target: 'enemy', range: 2,
    power: 45, mpCost: 35, teacherRequired: 'void_scholar_thresh',
    description: 'Zane disrupts the target\'s elite prefix permanently — removing one random affix for the rest of the run.',
    flavour: 'The void holds things together. Break the weave and they fall apart.',
    icon: '💠',
  },

  // ── Mira (Luminary) ───────────────────────────────────────────────────────
  leyline_burst: {
    id: 'leyline_burst', name: 'Leyline Burst',
    element: 'holy', target: 'area', range: 3,
    power: 55, mpCost: 40, teacherRequired: 'archive_mage_volant',
    description: 'Mira taps the ley network — dealing 55 holy+fire damage in a 3×3 area. Ignites terrain.',
    flavour: 'Twelve years of research, distilled into one unbearable moment of clarity.',
    icon: '✨',
  },
  last_rites: {
    id: 'last_rites', name: 'Last Rites',
    element: 'holy', target: 'ally', range: 4,
    power: 0, mpCost: 30, teacherRequired: 'chaplain_aldis',
    description: 'When a party member would die this battle, they get one final free action before falling.',
    flavour: 'Luminarch\'s grace extends even here.',
    icon: '✨',
    isPassive: true,
  },

  // ── Kael (Warder) ─────────────────────────────────────────────────────────
  blaze_counter: {
    id: 'blaze_counter', name: 'Blaze Counter',
    element: 'fire', target: 'auto', range: 0,
    power: 50, mpCost: 0, teacherRequired: 'ember_knight_solara',
    description: 'Once per battle: when Kael is struck, he automatically counters with a fire-wreathed blow (50 dmg).',
    flavour: '"You fight like a Watch soldier." — Solara',
    icon: '🔥',
    isPassive: true, trigger: 'on_hit',
  },
  sunder_armor: {
    id: 'sunder_armor', name: 'Sunder Armor',
    element: 'none', target: 'enemy', range: 1,
    power: 30, mpCost: 20, teacherRequired: 'iron_duelist_garek',
    description: 'Deals 30 damage and permanently removes 1 tier of the target\'s physical defense (armor) for the run.',
    flavour: 'Gold? Always. Principles? Negotiable.',
    icon: '⚔️',
  },

  // ── Any unit (from neutral wanderers) ─────────────────────────────────────
  arc_counter: {
    id: 'arc_counter', name: 'Arc Counter',
    element: 'thunder', target: 'auto', range: 0,
    power: 40, mpCost: 0, teacherRequired: 'storm_duelist_kira',
    description: 'Once per battle: auto-counter with a 40-damage thunder arc when struck. Stun chance 30%.',
    flavour: '"My timing was wrong." She was right. It was perfect.',
    icon: '⚡',
    isPassive: true, trigger: 'on_hit',
  },
  dark_echo: {
    id: 'dark_echo', name: 'Dark Echo',
    element: 'dark', target: 'enemy', range: 3,
    power: 60, mpCost: 25, teacherRequired: 'shadow_of_vaelthorn',
    description: 'Copies the last ability any enemy used — mirrors it back as dark-typed at 60 power.',
    flavour: 'The shadow doesn\'t create. It remembers.',
    icon: '💀',
  },
}

export const getSecretSkill = (id) => SECRET_SKILLS[id]
export const getSecretSkillsForUnit = (unitId) => {
  const skills = Object.values(SECRET_SKILLS)
  // Filter by character-specific restrictions (any unit can learn arc_counter/dark_echo)
  const unitSpecific = { zane:['resonance_fracture','null_break'], mira:['leyline_burst','last_rites'], kael:['blaze_counter','sunder_armor'] }
  const neutral = ['arc_counter', 'dark_echo']
  return [...(unitSpecific[unitId] ?? []), ...neutral].map(id => SECRET_SKILLS[id]).filter(Boolean)
}
