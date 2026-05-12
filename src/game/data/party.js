export const PARTY_MEMBERS = {
  zane: {
    id: 'zane',
    name: 'Zane Vale',
    role: 'Resonant',
    level: 1,
    jobId: 'resonant',
    hp: 320,
    mp: 90,
    temper: 80,
    ether: 120,
    portrait: 'placeholder-zane',
    traits: ['Guardian listener', 'Balanced caster', 'Story anchor'],
    bio: 'A rare Resonant who hears the pain inside corrupted Guardians instead of only sensing their rage.'
  },
  mira: {
    id: 'mira',
    name: 'Mira Vey',
    role: 'Field Medic',
    level: 1,
    jobId: 'luminary',
    hp: 280,
    mp: 115,
    temper: 60,
    ether: 135,
    portrait: 'placeholder-mira',
    traits: ['Healer', 'Cleanse support', 'Skeptical guide'],
    bio: 'A practical medic who trusts bandages, field notes, and proof more than prophecy.'
  },
  rusk: {
    id: 'rusk',
    name: 'Captain Rusk',
    role: 'Warder',
    level: 1,
    jobId: 'warder',
    hp: 390,
    mp: 45,
    temper: 145,
    ether: 55,
    portrait: 'placeholder-rusk',
    traits: ['Frontline guard', 'Temper breaker', 'Town defender'],
    bio: 'Ashvale’s watch captain. He does not understand Resonance, but he understands standing between danger and civilians.'
  }
}

export const STARTING_PARTY_IDS = ['zane', 'mira', 'rusk']

export const getPartyMembers = (partyIds = STARTING_PARTY_IDS) =>
  partyIds.map((id) => PARTY_MEMBERS[id]).filter(Boolean)
