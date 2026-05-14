export const TOWNS = {
  ashvale: {
    id: 'ashvale',
    name: 'Ashvale Crossing',
    subtitle: 'The town beneath the split shrine bell',
    region: 'Vaelthar Lowlands',
    element: 'fire',
    mapPosition: { x: 18, y: 58 },
    unlockedByDefault: true,
    description:
      'A trade town built around an old Guardian shrine. Since the bell cracked, violet Ether seeps through the market stones at dusk.',
    ambientLine: 'The shrine bell hums even when there is no wind.',
    services: ['Inn', 'Market', 'Training Yard', 'Mission Board'],
    npcs: [
      {
        id: 'mira',
        name: 'Mira Vey',
        role: 'Field medic and reluctant guide',
        line: 'You did not destroy the thing outside town. You reached it. That makes you useful, and dangerous.'
      },
      {
        id: 'oldBellkeeper',
        name: 'Old Bellkeeper Soren',
        role: 'Shrine keeper',
        line: 'That bell has rung for births, fires, weddings, and wars. Last night it rang for something underneath the world.'
      },
      {
        id: 'captainRusk',
        name: 'Captain Rusk',
        role: 'Town watch captain',
        line: 'If you can hear the Guardian, then you can walk toward the noise while the rest of us keep people alive.'
      },
      {
        id: 'elianCrowe',
        name: 'Elian Crowe',
        role: 'Ashen Company agitator',
        line: 'A cracked bell is honest. It finally sounds like the thing it was built to hide.'
      }
    ],
    missions: ['ashvale_null_drake'],
    connectedTownIds: ['mirefen']
  },

  mirefen: {
    id: 'mirefen',
    name: 'Mirefen Reach',
    subtitle: 'A drowned settlement of blue lanterns',
    region: 'Flooded Lowlands',
    element: 'water',
    mapPosition: { x: 42, y: 68 },
    unlockedByDefault: false,
    description:
      'A wetlands town where water Ether gathers in the reeds. The people fear that Nerevan’s tide has begun answering something beneath the marsh.',
    ambientLine: 'Every reflection in the marsh looks half a second late.',
    services: ['Inn', 'Reed Market', 'Mission Board'],
    npcs: [
      {
        id: 'fenwardenIla',
        name: 'Fenwarden Ila',
        role: 'Marsh pathfinder',
        line: 'Step where the reeds bend away from you. If they bend toward you, something already knows your weight.'
      },
      {
        id: 'drownedScholar',
        name: 'The Drowned Scholar',
        role: 'Guardian historian',
        line: 'Water remembers shape. Ice remembers injury. Thunder remembers the instant both become one.'
      },
      {
        id: 'reedChild',
        name: 'Reed Child',
        role: 'Unsettling local witness',
        line: 'The river talked in my sleep. It said your name wrong, then corrected itself.'
      }
    ],
    missions: ['mirefen_reaction_trial'],
    connectedTownIds: ['ashvale', 'stormglass']
  },

  stormglass: {
    id: 'stormglass',
    name: 'Stormglass Bastion',
    subtitle: 'A fortress where lightning sleeps in the walls',
    region: 'High Glass March',
    element: 'thunder',
    mapPosition: { x: 68, y: 36 },
    unlockedByDefault: false,
    description:
      'A military bastion carved from black glass and copper. Its towers catch storms and teach soldiers to move between thunderbeats.',
    ambientLine: 'The air tastes like copper and unfinished warnings.',
    services: ['Barracks', 'Glasswright', 'Mission Board', 'Timing Trials'],
    npcs: [
      {
        id: 'bastionMarshal',
        name: 'Marshal Kael Orik',
        role: 'Trial commander',
        line: 'Your timing is not instinct. It is discipline wearing instinct’s clothes.'
      },
      {
        id: 'glasswrightTheo',
        name: 'Glasswright Theo',
        role: 'Resonance engineer',
        line: 'I can make the Surge window visible. I cannot make your hand brave enough to press it.'
      },
      {
        id: 'stormAcolyte',
        name: 'Storm Acolyte Venn',
        role: 'Torvahk devotee',
        line: 'When Torvahk speaks, most hear thunder. The chosen hear grief.'
      },
      {
        id: 'serraValecourt',
        name: 'Serra Valecourt',
        role: 'Concord heir under military escort',
        line: 'My family taught me how to inherit a country. No one taught me how to give one back.'
      }
    ],
    missions: ['stormglass_deflect_trial'],
    connectedTownIds: ['mirefen']
  }
}

export const getTown = (townId) => TOWNS[townId]

export const getUnlockedTowns = (unlockedTownIds = []) =>
  unlockedTownIds.map((townId) => TOWNS[townId]).filter(Boolean)
