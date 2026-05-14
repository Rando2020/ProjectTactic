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
    cycleArchetypeId: 'listener',
    bio: 'A rare Resonant who hears the pain inside corrupted Guardians instead of only sensing their rage.',
    storyHook:
      'Zane is the proof that the old war was not won cleanly. His gift makes every battlefield a testimony and every spared Guardian a witness.'
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
    cycleArchetypeId: 'witness',
    bio: 'A practical medic who trusts bandages, field notes, and proof more than prophecy.',
    storyHook:
      'Mira turns skepticism into resistance. She records what power wants treated as rumor, hysteria, or battlefield fog.'
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
    cycleArchetypeId: 'preserver',
    bio: 'Ashvale’s watch captain. He does not understand Resonance, but he understands standing between danger and civilians.',
    storyHook:
      'Rusk embodies the necessary danger of order: walls save people, but walls can also hide the crime that guarantees the next war.'
  },
  elian: {
    id: 'elian',
    name: 'Elian Crowe',
    role: 'Ashen Saboteur',
    level: 2,
    jobId: 'warder',
    hp: 350,
    mp: 60,
    temper: 120,
    ether: 80,
    portrait: 'placeholder-elian',
    traits: ['Cycle destroyer', 'Armor breaker', 'Anti-institution striker'],
    cycleArchetypeId: 'destroyer',
    bio: 'A furious descendant of erased common soldiers who believes every institution born from the Concord deserves to fall.',
    storyHook:
      'Elian is what happens when buried history grows teeth. He is often right about the lie and dangerously wrong about who deserves to survive its collapse.'
  },
  serra: {
    id: 'serra',
    name: 'Serra Valecourt',
    role: 'Concord Heir',
    level: 2,
    jobId: 'skywarden',
    hp: 330,
    mp: 70,
    temper: 105,
    ether: 95,
    portrait: 'placeholder-serra',
    traits: ['Noble command', 'Formation support', 'Inherited guilt'],
    cycleArchetypeId: 'inheritor',
    bio: 'A disciplined noble heir whose family was rewarded after the First Breach records were rewritten.',
    storyHook:
      'Serra makes privilege playable and uncomfortable. Her access opens doors, but every opened door reminds the party who was locked outside history.'
  }
}

export const STARTING_PARTY_IDS = ['zane', 'mira', 'rusk']

export const STORY_RECRUITABLE_PARTY_IDS = ['elian', 'serra']

export const getPartyMembers = (partyIds = STARTING_PARTY_IDS) =>
  partyIds.map((id) => PARTY_MEMBERS[id]).filter(Boolean)

export const getAllPartyMembers = () => Object.values(PARTY_MEMBERS)
