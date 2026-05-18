export const RUN_MODIFIERS = {
  emberlit_skies: {
    id: 'emberlit_skies',
    name: 'Emberlit Skies',
    type: 'elemental_weather',
    summary: 'Fire pressure is easier to trigger.',
    description: 'The road glows with residual flame. Future battle work should bias terrain reactions toward burning tiles.',
  },
  charged_water: {
    id: 'charged_water',
    name: 'Charged Water',
    type: 'terrain_pressure',
    summary: 'Water routes invite thunder chains.',
    description: 'Marsh routes carry static through shallow water. Future battle work should increase thunder reaction range.',
  },
  guardian_whispers: {
    id: 'guardian_whispers',
    name: 'Guardian Whispers',
    type: 'draft_bias',
    summary: 'Guardian rewards are more likely.',
    description: 'The shrine offers stronger pacts and relics before the next fight.',
  },
  void_pressure: {
    id: 'void_pressure',
    name: 'Void Pressure',
    type: 'elite_risk',
    summary: 'Elite route with harsher pressure.',
    description: 'Future battle work should add a round timer or enemy speed bonus.',
  },
  echoing_past: {
    id: 'echoing_past',
    name: 'Echoing Past',
    type: 'event',
    summary: 'History repeats unless the player pays a cost.',
    description: 'A narrative event that should later trade HP, gold, or a boon for Echo Shards.',
  },
  boss_resonance: {
    id: 'boss_resonance',
    name: 'Boss Resonance',
    type: 'boss',
    summary: 'The capstone fight spikes Guardian energy.',
    description: 'Future battle work should add a boss-specific resonance phase.',
  },
}

export function getRunModifier(modifierId) {
  return RUN_MODIFIERS[modifierId]
}

export function getRunModifiers(modifierIds = []) {
  return modifierIds.map(getRunModifier).filter(Boolean)
}
