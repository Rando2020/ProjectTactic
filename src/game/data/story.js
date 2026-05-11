export const STORY_CHAPTERS = [
  {
    id: 'prologue',
    title: 'The Broken Anchor',
    locationId: 'ashvale',
    requiredFlags: [],
    nextMode: 'town',
    nextTownId: 'ashvale',
    beats: [
      {
        speaker: 'Narrator',
        text: 'The first scream did not come from the sky. It came from underneath it.'
      },
      {
        speaker: 'Narrator',
        text: 'Ashvale Crossing shook as the old shrine bell split in two, spilling violet light across the market stones. For one breath, every flame in town burned black.'
      },
      {
        speaker: 'Unknown Guardian',
        text: 'Help me. Not with steel. Not with fire. Hear me.'
      },
      {
        speaker: 'Zane',
        text: 'That was not rage. That was pain.'
      },
      {
        speaker: 'Mira',
        text: 'Then pain just tore open half the eastern road. If you can hear it, you are coming with me.'
      }
    ],
    rewards: {
      activateQuestIds: ['cracked_bell'],
      unlockTownIds: ['ashvale'],
      flags: ['heard_first_guardian']
    }
  },

  {
    id: 'after_ashvale',
    title: 'Ash Under Glass',
    locationId: 'ashvale',
    requiredFlags: ['completed_intro_battle'],
    nextMode: 'world',
    nextTownId: 'ashvale',
    beats: [
      {
        speaker: 'Mira',
        text: 'You reached through the Anchor and something answered back. Do you understand how rare that is?'
      },
      {
        speaker: 'Zane',
        text: 'No. But I understand it was afraid.'
      },
      {
        speaker: 'Old Bellkeeper Soren',
        text: 'Then Ashvale is only the first bell. Mirefen has been ringing underwater for three nights.'
      },
      {
        speaker: 'System',
        text: 'Mirefen Reach unlocked. New quest available: Road to Mirefen.'
      }
    ],
    rewards: {
      activateQuestIds: ['road_to_mirefen'],
      unlockTownIds: ['mirefen'],
      flags: ['mirefen_unlocked']
    }
  },

  {
    id: 'after_mirefen',
    title: 'The Reflection Moves First',
    locationId: 'mirefen',
    requiredFlags: ['completed_mirefen_trial'],
    nextMode: 'world',
    nextTownId: 'mirefen',
    beats: [
      {
        speaker: 'The Drowned Scholar',
        text: 'Water remembers what you did. Ice remembers what it cost. Thunder remembers the instant you chose anyway.'
      },
      {
        speaker: 'Reed Child',
        text: 'The stormglass people are afraid of the next voice. It is louder than the river.'
      },
      {
        speaker: 'System',
        text: 'Stormglass Bastion unlocked. New quest available: Between Thunderbeats.'
      }
    ],
    rewards: {
      activateQuestIds: ['stormglass_trials'],
      unlockTownIds: ['stormglass'],
      flags: ['stormglass_unlocked']
    }
  }
]

export const getStoryChapter = (chapterId) =>
  STORY_CHAPTERS.find((chapter) => chapter.id === chapterId)

export const getNextAvailableChapter = (storyFlags = [], completedStoryIds = []) =>
  STORY_CHAPTERS.find((chapter) => {
    if (completedStoryIds.includes(chapter.id)) return false
    return chapter.requiredFlags.every((flag) => storyFlags.includes(flag))
  })
