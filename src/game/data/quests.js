export const QUESTS = {
  cracked_bell: {
    id: 'cracked_bell',
    title: 'The Cracked Bell',
    type: 'main',
    townId: 'ashvale',
    status: 'active',
    description:
      'Investigate the shrine bell after Zane hears a corrupted Guardian speaking through the fracture.',
    objectives: [
      { id: 'speak_mira', text: 'Speak with Mira in Ashvale Crossing.' },
      { id: 'check_shrine', text: 'Inspect the cracked shrine bell.' },
      { id: 'first_mission', text: 'Clear the Null Drake at the eastern road.' }
    ],
    rewards: {
      jp: 30,
      items: ['Vitae Draught'],
      flags: ['completed_intro_battle'],
      unlockTownIds: ['mirefen']
    }
  },

  road_to_mirefen: {
    id: 'road_to_mirefen',
    title: 'Road to Mirefen',
    type: 'main',
    townId: 'mirefen',
    status: 'locked',
    description:
      'Follow the flooded road toward Mirefen Reach and learn why the marsh is reflecting events before they happen.',
    objectives: [
      { id: 'enter_mirefen', text: 'Travel to Mirefen Reach.' },
      { id: 'learn_reactions', text: 'Speak with the Drowned Scholar about Wet, Freeze, and Electrify reactions.' },
      { id: 'clear_marsh', text: 'Clear the marsh reaction trial.' }
    ],
    rewards: {
      jp: 55,
      items: ['Resonance Phial'],
      flags: ['completed_mirefen_trial'],
      unlockTownIds: ['stormglass']
    }
  },

  stormglass_trials: {
    id: 'stormglass_trials',
    title: 'Between Thunderbeats',
    type: 'main',
    townId: 'stormglass',
    status: 'locked',
    description:
      'Train at Stormglass Bastion and prove Zane can move within the brief moment between warning and impact.',
    objectives: [
      { id: 'meet_marshal', text: 'Meet Marshal Kael Orik.' },
      { id: 'deflect_trial', text: 'Complete the Deflect timing trial.' },
      { id: 'hear_torvahk', text: 'Listen for Torvahk beneath the stormglass walls.' }
    ],
    rewards: {
      jp: 80,
      items: ['Ironcore Shard'],
      flags: ['completed_stormglass_trial'],
      unlockTownIds: []
    }
  }
}

export const getQuest = (questId) => QUESTS[questId]

export const getQuestsForTown = (townId) =>
  Object.values(QUESTS).filter((quest) => quest.townId === townId)
