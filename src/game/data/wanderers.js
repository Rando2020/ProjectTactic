/**
 * wanderers.js
 * Disgaea-inspired wandering characters who appear at ? Event nodes.
 * Each has a unique personality, condition, and reward.
 *
 * Types:
 *   teacher    — teaches a secret skill (conditional or paid)
 *   challenger — wants to fight; win to learn their skill + extra loot
 *   merchant   — sells special items / boons not in normal rotation
 *   scholar    — reveals info (elite affixes, floor structure, lore)
 *   innocent   — carry them through the floor for a passive bonus (Disgaea Innocent ref)
 *   hostile    — dangerous wanderer; must be defeated to claim their skill
 */

export const WANDERERS = [

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'ember_knight_solara',
    name:      'Ember Knight Solara',
    title:     'Disgraced Ashvale Watch Captain',
    type:      'challenger',
    rarity:    'uncommon',
    floorMin:  1,
    element:   'fire',
    portrait:  '🔥',
    teaches:   'blaze_counter',

    greeting:  '"You fight like a Watch soldier. That\'s not a compliment — but it means you know what you\'re doing. Prove it. Face me."',
    accept:    '"Good. Come on then. Don\'t hold back or this lesson means nothing."',
    decline:   '"Smart. Or cowardly. Hard to tell from here."',
    victory:   '"... Decent. Here. This is the technique that got me stripped of my rank. Apparently it was \'too aggressive.\'" [Teaches Blaze Counter]',
    defeat:    '"You let me win. I can tell. Come back when you\'re serious."',

    condition: { type: 'challenge', label: 'Accept her challenge (duel)', subtype: 'duel' },
    altCondition: { type: 'pay', label: 'Pay 60g for the lesson instead', cost: 60 },
    reward: { type: 'secret_skill', skillId: 'blaze_counter' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'archive_mage_volant',
    name:      'Archive Mage Volant',
    title:     'Bellkeeper Researcher',
    type:      'teacher',
    rarity:    'uncommon',
    floorMin:  1,
    element:   'holy',
    portrait:  '🔔',
    teaches:   'leyline_burst',

    greeting:  '"Twelve years cataloguing resonance events. Every single one. I\'ve seen what happens when someone with real aptitude channels a ley confluence. You have that aptitude. I\'ll show you the technique — for a price."',
    accept:    '"The knowledge costs 80g. Consider it a research donation."',
    decline:   '"As you wish. The ley lines will remain uncharted for another twelve years."',
    paid:      '"Here. Don\'t waste it." [Teaches Leyline Burst]',
    poor:      '"You don\'t have enough. Come back when you\'ve earned more than dust."',

    condition: { type: 'pay', label: 'Pay 80g for the technique', cost: 80 },
    altCondition: { type: 'answer_riddle', label: 'Answer his question (skip the gold)', riddle: {
      question: '"What element does a Bellkeeper record but never wields?"',
      answer:   'resonance',
      hint:     'Think about what the bells measure, not what they ring.',
    }},
    reward: { type: 'secret_skill', skillId: 'leyline_burst' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'void_scholar_thresh',
    name:      'Void Scholar Thresh',
    title:     'Former Null Conclave Researcher',
    type:      'teacher',
    rarity:    'rare',
    floorMin:  2,
    element:   'dark',
    portrait:  '🕳️',
    teaches:   'null_break',

    greeting:  '"You carry the resonance signature. The Conclave wants that — badly. I left the Conclave. We have that in common. I\'ll teach you how to unmake their constructs, but only if you show me you can handle one in the field."',
    condition_met: '"You did it. Destroyed their champion. Here — this is how the Anchors are actually held together. And how to undo it." [Teaches Null-Break]',
    condition_pending: '"Kill one of their elites while I watch. Then we\'ll talk."',

    condition: { type: 'witness_elite_kill', label: 'Kill an Elite enemy while Thresh watches', description: 'He follows you — an elite must die this floor.' },
    reward: { type: 'secret_skill', skillId: 'null_break' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'storm_duelist_kira',
    name:      'Storm Duelist Kira',
    title:     'Stormglass Bastion Dropout',
    type:      'challenger',
    rarity:    'uncommon',
    floorMin:  2,
    element:   'thunder',
    portrait:  '⚡',
    teaches:   'arc_counter',

    greeting:  '"The Bastion said my timing was wrong. I disagreed. I\'ve been proving it ever since." [She draws her blade.] "Show me your timing."',
    accept:    '"Good. I fight fast. Keep up."',
    decline:   '"Shame. I had a technique worth sharing."',
    victory:   '"...You have good timing. Better than mine? Maybe. Here — this is the counter I developed in secret. The Bastion never even saw it." [Teaches Arc Counter]',
    defeat:    '"My timing wins again. Come back when you\'re faster."',

    condition: { type: 'challenge', label: 'Accept her duel', subtype: 'duel' },
    altCondition: { type: 'pay', label: 'Pay 50g — she respects gold', cost: 50 },
    reward: { type: 'secret_skill', skillId: 'arc_counter' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'the_wandering_null',
    name:      'The Wandering Null',
    title:     'Unknown',
    type:      'teacher',
    rarity:    'legendary',
    floorMin:  3,
    element:   'resonance',
    portrait:  '💠',
    teaches:   'resonance_fracture',

    greeting:  '"..."',
    condition_met: '"..." [The void around them briefly shatters. You feel something enter your understanding.] [Teaches Resonance Fracture]',
    condition_pending: '"..."',
    condition_hint: 'This one doesn\'t speak. But something about them feels like a test.',

    condition: { type: 'flawless_floor', label: 'Complete this floor without taking damage', description: 'The Null watches silently. Take no damage and they\'ll share what they know.' },
    reward: { type: 'secret_skill', skillId: 'resonance_fracture' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'chaplain_aldis',
    name:      'Chaplain Aldis',
    title:     'Traveling Luminarch Devotee',
    type:      'teacher',
    rarity:    'uncommon',
    floorMin:  1,
    element:   'holy',
    portrait:  '✨',
    teaches:   'last_rites',

    greeting:  '"Luminarch\'s grace extends even here. I\'ve been following this road since the Third Anchor went dark. I teach what I can to those who seem worth teaching."',
    accept:    '"The technique is old. Older than the Bellkeepers. Here." [Teaches Last Rites]',
    decline:   '"Then go. Luminarch keeps no one against their will."',

    condition: { type: 'party_full_hp', label: 'Arrive with party at full HP', description: 'The Chaplain only teaches those who have been taking care of themselves.' },
    altCondition: { type: 'pay', label: 'Donate 40g to his mission', cost: 40 },
    reward: { type: 'secret_skill', skillId: 'last_rites' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'iron_duelist_garek',
    name:      'Iron Duelist Garek',
    title:     'Mercenary Knight',
    type:      'merchant',
    rarity:    'common',
    floorMin:  1,
    element:   null,
    portrait:  '⚔️',
    teaches:   'sunder_armor',

    greeting:  '"I work for gold. Not gold AND favors. Just gold. You want the technique, it costs sixty. You want my opinion on your posture, that\'s free — it\'s terrible."',
    paid:      '"Here. Don\'t thank me. I don\'t do gratitude." [Teaches Sunder Armor]',
    poor:      '"Come back with sixty. Or don\'t come back."',

    condition: { type: 'pay', label: 'Pay 60g', cost: 60 },
    reward: { type: 'secret_skill', skillId: 'sunder_armor' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'mirefen_seer_yuna',
    name:      'Mirefen Seer Yuna',
    title:     'Reedfolk Elder',
    type:      'scholar',
    rarity:    'rare',
    floorMin:  2,
    element:   'water',
    portrait:  '🌿',
    teaches:   null,

    greeting:  '"The water showed me your path. All of it — the elites, the boons, the thing waiting at the end. I\'ll share what I saw. No charge. The Mirefen asks only that you carry the knowledge forward."',
    reveal:    '"Here is what waits ahead." [Reveals all elite affixes on this floor and next] [Grants one random Rare boon]',

    condition: { type: 'free', label: 'Listen to her reading', description: 'No conditions. She gives freely.' },
    reward: { type: 'reveal_and_boon', revealFloors: 2, boonRarity: 'rare' },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'shadow_of_vaelthorn',
    name:      'Shadow of Vaelthorn',
    title:     'Corrupted Echo of the Dark Guardian',
    type:      'hostile',
    rarity:    'legendary',
    floorMin:  3,
    element:   'dark',
    portrait:  '💀',
    teaches:   'dark_echo',

    greeting:  '"You carry the resonance. I\'ll take it from you."',
    victory:   '"... The echo remains." [Drops Dark Echo skill fragment — can be learned at camp]',
    defeat:    '"The Shadow withdraws. For now."',

    condition: { type: 'defeat', label: 'Defeat the Shadow in combat', description: 'It is hostile — it cannot be reasoned with. Win and claim Dark Echo.' },
    reward: { type: 'secret_skill', skillId: 'dark_echo' },
    stats: { hp: 320, speed: 9, power: 75, element: 'dark', abilities: ['dark_breath', 'void_pulse'] },
  },

  // ────────────────────────────────────────────────────────────────────────────
  {
    id:        'resonance_vendor',
    name:      'The Resonance Vendor',
    title:     'Origin Unknown',
    type:      'merchant',
    rarity:    'rare',
    floorMin:  1,
    element:   null,
    portrait:  '💎',
    teaches:   null,

    greeting:  '"I find things. You want things. This is a simple exchange." [Displays three Resonant-tier items from the deep pool]',
    sold:      '"Pleasure doing business."',
    no_gold:   '"Come back with more gold. Or more shards. I accept both."',

    condition: { type: 'purchase', label: 'Buy one of three Resonant items', description: 'Three Resonant-tier items available. Priced high.' },
    reward: { type: 'resonant_shop', itemCount: 3, goldCost: 180 },
  },

  // ────────────────────────────────────────────────────────────────────────────
  // Disgaea-style Innocent — carry them through the floor for a passive bonus
  {
    id:        'lost_innocent',
    name:      'Lost Innocent',
    title:     'Wandering Soul (Floor Bonus)',
    type:      'innocent',
    rarity:    'common',
    floorMin:  1,
    element:   null,
    portrait:  '👻',
    teaches:   null,

    greeting:  '"Oh! A person! I\'ve been lost in here for... I don\'t know how long. If you get me to the end of the floor safely, I\'ll share what I know."',
    survived:  '"Thank you! Here — I\'ve been absorbing the energy of this place. Take it." [Grants a random Common boon OR +25 JP all]',
    died:      '"... [The Innocent dissolves. Nothing gained.]"',

    condition: { type: 'escort', label: 'Escort them to the end of the floor', description: 'They follow your party. If they take damage, the bonus is lost.' },
    reward: { type: 'random_common_or_jp', jpAmount: 25 },
  },
]

export const getWanderer = (id) => WANDERERS.find(w => w.id === id)
export const getWanderersForFloor = (floor, rng) => {
  const pool = WANDERERS.filter(w => w.floorMin <= floor)
  if (pool.length === 0) return null
  return pool[Math.floor(rng() * pool.length)]
}
