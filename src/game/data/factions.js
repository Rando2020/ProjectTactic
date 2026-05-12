export const FACTIONS = {
  ashvale_watch: {
    id: 'ashvale_watch',
    name: 'Ashvale Watch',
    alignment: 'civilian_guard',
    description: 'Local defenders trying to keep the road open while Guardian disturbances spread.',
    startingTrust: 20,
    unlocks: ['discount_basic_items', 'watch_training_contracts']
  },
  bellkeepers: {
    id: 'bellkeepers',
    name: 'Bellkeepers of the Broken Shrine',
    alignment: 'religious_order',
    description: 'Shrine keepers who record Guardian echoes and protect old resonance rites.',
    startingTrust: 10,
    unlocks: ['resonance_lore', 'guardian_contracts']
  },
  mirefen_reedfolk: {
    id: 'mirefen_reedfolk',
    name: 'Mirefen Reedfolk',
    alignment: 'regional_survivors',
    description: 'Marsh families who read water, weather, and reflection as warning signs.',
    startingTrust: 0,
    unlocks: ['marsh_routes', 'water_reaction_training']
  },
  stormglass_bastion: {
    id: 'stormglass_bastion',
    name: 'Stormglass Bastion',
    alignment: 'military_academy',
    description: 'A disciplined fortress culture built around timing, lightning, and tactical restraint.',
    startingTrust: 0,
    unlocks: ['timing_trials', 'deflect_mastery']
  },
  null_conclave: {
    id: 'null_conclave',
    name: 'Null Conclave',
    alignment: 'antagonist',
    description: 'An occult faction experimenting with Void Anchors and Guardian corruption.',
    startingTrust: -100,
    unlocks: []
  }
}

export const getFaction = (factionId) => FACTIONS[factionId]

export const getStartingFactionTrust = () =>
  Object.values(FACTIONS).reduce((trust, faction) => {
    trust[faction.id] = faction.startingTrust
    return trust
  }, {})
