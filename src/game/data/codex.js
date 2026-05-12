export const CODEX_ENTRIES = [
  {
    id: 'resonance',
    category: 'Core Systems',
    title: 'Resonance',
    unlockFlags: ['heard_first_guardian'],
    summary:
      'A rare Ether sensitivity that lets a person hear the pain inside a corrupted Guardian instead of only sensing its attack pattern.',
    gameplayNote:
      'Resonance unlocks Guardian-saving story beats, summon progression, and future tactical choices during boss encounters.'
  },
  {
    id: 'void_anchors',
    category: 'Lore',
    title: 'Void Anchors',
    unlockFlags: ['heard_first_guardian'],
    summary:
      'Pre-world Null shards driven into Guardian cores. They twist elemental Ether into pain, aggression, and obedience.',
    gameplayNote:
      'Void Anchors create Resonance Windows. Breaking them saves Guardians and improves rewards.'
  },
  {
    id: 'the_concord',
    category: 'Lore',
    title: 'The Concord',
    unlockFlags: ['heard_first_guardian'],
    summary:
      'The official treaty said the First Breach ended when noble houses, shrine orders, and military academies united. Older echoes suggest the Concord also erased the common soldiers and Resonants who refused to let the victors rewrite the cost.',
    gameplayNote:
      'The Concord is the campaign’s history-cycle spine: each region should reveal another institution built on survival, erasure, and controlled memory.'
  },
  {
    id: 'ashen_companies',
    category: 'Factions',
    title: 'The Ashen Companies',
    unlockFlags: ['completed_intro_battle'],
    summary:
      'Erased wartime companies of common soldiers, medics, scouts, and warders who held the First Breach line before official records credited the Concord houses.',
    gameplayNote:
      'The Ashen Companies support Elian’s route, sabotage objectives, anti-armor abilities, and liberation missions that challenge clean heroic reputation systems.'
  },
  {
    id: 'concord_bloodlines',
    category: 'Factions',
    title: 'Concord Bloodlines',
    unlockFlags: ['stormglass_unlocked'],
    summary:
      'Families rewarded after the First Breach with land, command rights, and archive access. Some inherited duty. Others inherited stolen victory.',
    gameplayNote:
      'Concord heirs like Serra can unlock command advantages, restricted archives, noble deployment options, and story choices that make privilege mechanically useful but morally expensive.'
  },
  {
    id: 'surface_reactions',
    category: 'Combat',
    title: 'Elemental Surface Reactions',
    unlockFlags: ['mirefen_unlocked'],
    summary:
      'Battlefields can hold temporary elemental states like Wet, Burning, Frozen, Cursed, and Blessed.',
    gameplayNote:
      'Wet plus Ice can Freeze. Wet plus Thunder can Electrify. Frozen plus Thunder can Shatter for burst damage.'
  },
  {
    id: 'stormglass_timing',
    category: 'Combat',
    title: 'Timing Discipline',
    unlockFlags: ['stormglass_unlocked'],
    summary:
      'Stormglass soldiers train to act between warning and impact, turning reaction time into a martial art.',
    gameplayNote:
      'Future battles can use tighter SURGE windows, DEFLECT chains, and turn-order manipulation.'
  },
  {
    id: 'null_conclave',
    category: 'Factions',
    title: 'The Null Conclave',
    unlockFlags: ['completed_intro_battle'],
    summary:
      'A secretive order excavating pre-world ruins and weaponizing corrupted Ether.',
    gameplayNote:
      'The Conclave can become the main antagonist faction across story arcs, optional bosses, and moral-choice quests.'
  },
  {
    id: 'surge_deflect',
    category: 'Combat',
    title: 'SURGE and DEFLECT',
    unlockFlags: ['heard_first_guardian'],
    summary:
      'SURGE rewards offensive timing. DEFLECT rewards defensive timing. Together they make every action feel active instead of passive.',
    gameplayNote:
      'Keep these mechanics readable with obvious prompts, strong feedback, and configurable timing assists.'
  }
]

export const getUnlockedCodexEntries = (storyFlags = []) =>
  CODEX_ENTRIES.filter((entry) => entry.unlockFlags.every((flag) => storyFlags.includes(flag)))
