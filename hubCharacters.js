// ============================================================
//  THE APPOINTED: AS ABOVE
//  hubCharacters.js — The inhabitants of the Antechamber
// ============================================================
//
//  DESIGN NOTE:
//  Hub characters are NOT mission-critical. They are depth.
//  A player who never seeks them out misses texture.
//  A player who finds all of them understands the architecture
//  of what they're standing inside.
//
//  Greek cosmological figures predate the Abrahamic framework.
//  They are the old bones the current system was built on top of.
//  They are not enemies. They are witnesses with long memory
//  and complicated feelings about the new management.
// ============================================================

export const HUB_CHARACTERS = {

  // ── CHARON ───────────────────────────────────────────────
  charon: {
    id: "charon",
    name: "Charon",
    title: "The Ferryman",
    location: "The Dock — east edge of the Antechamber, where the mist comes in",
    appearance:
      "Older than anything that has a face. Robes that have absorbed decades of river water " +
      "and never fully dried. Eyes that have seen every kind of death and categorized them all. " +
      "Currently drinking something from a clay vessel that he offers to no one.",
    role: "Lore delivery. Dry humor. The party's oldest witness.",
    accessibility: "Available from Run 1 but opens up gradually. Full depth at Run 10+.",

    personality:
      "Has been ferrying the dead under multiple cosmological regimes. " +
      "The Styx was his. The mountain replaced his jurisdiction but not his function — " +
      "he still handles the transit. He has opinions about the new system. " +
      "He also, grudgingly, respects that it works better than the old one. " +
      "Deeply tired. Deeply funny. The fatigue and the humor are the same thing.",

    whatHeKnows:
      "Every soul that has arrived. The condition they arrived in. " +
      "How long each boss has been stuck and what they were carrying when they came. " +
      "How many times the Seven have looped — he has the number " +
      "and won't give it to them yet. He's waiting for the right moment. " +
      "He'll know the moment when it comes.",

    dialogueTier1: [
      "You again. Same party, different loop. You know, most operations have some kind of turnover.",
      "I've been doing this since before this mountain existed. Take my professional advice: stop fighting everything and talk to some of it.",
      "You want to know how many times you've been here? No. You don't. Not yet.",
    ],
    dialogueTier2: [
      "You noticed them hesitating. Good. The new ones are always the most confused. " +
      "They arrived three weeks ago by your reckoning and they still think they're somewhere else.",
      "There was a soul last loop — ordinary man, stone mason — stayed and talked to me for what felt like a month. " +
      "Then he just... went. Just like that. After all that time. Sometimes that's how it goes.",
    ],
    dialogueTier3: [
      "The Fallen. Yes, I remember them from before they were Fallen. " +
      "They were the ones who asked the most questions. Still are, technically.",
      "They're not wrong about everything, you know. I'm not saying join them. " +
      "I'm saying they're not wrong about everything.",
    ],
    dialogueTier4: [
      "You want the number now. I can see it. Fine. " +
      "Are you sure? " +
      "[beat] " +
      "Forty-seven loops. You've been here forty-seven times. " +
      "The record, for what it's worth, is three hundred and twelve. " +
      "That was a different group. They got there.",
    ],
    dialogueTier5: [
      "I've watched a lot of ascents. Most of them don't look like what people expect. " +
      "They look like someone finally putting something down.",
      "You're close. I can tell because you're asking different questions.",
    ],

    // Special mechanic: Charon can be asked about specific souls
    // He gives information based on revelation tier
    soulKnowledge: {
      canReveal: ["arrival_condition", "stuck_duration", "boss_history"],
      requiresTier: 2,
    },

    gifts: [
      { item: "A coin — old, from a civilization no one names anymore",
        effect: "Unlocks Charon's count of how many souls the party has helped ascend this run" },
      { item: "A bottle of river water from the Styx",
        effect: "Charon's eyes change when you give him this. He doesn't speak for a moment. " +
        "Unlocks a conversation about what the river actually was." },
    ],
  },

  // ── NYX ──────────────────────────────────────────────────
  nyx: {
    id: "nyx",
    name: "Nyx",
    title: "Night Herself",
    location: "The threshold between the Antechamber and the Mountain — appears at what passes for dusk",
    appearance:
      "Older than everything. Does not have a body so much as an agreement with the space " +
      "around her to behave as if she does. Dark in the way that pre-dawn dark is different " +
      "from midnight dark — full, but with something in it. Stars, maybe. " +
      "Or things older than stars.",
    role: "The oldest witness. Speaks rarely. When she does, it reframes everything.",
    accessibility: "Appears randomly at low clarity. Appears reliably at Tier 3+.",

    personality:
      "Predates gods, predates sin, predates the mountain. " +
      "She was here when the original design was laid down and she remembers all of it. " +
      "Does not intervene. Does not comfort. Does not threaten. " +
      "She witnesses, and occasionally she says what she saw, " +
      "and what she says is always true and rarely what you wanted to hear.",

    whatSheKnows:
      "Everything that happens in the dark — every secret of every soul that passed through. " +
      "The original design of the mountain and God's intent behind it. " +
      "Who the Seven were before the assignment. " +
      "She will not give this to you directly. " +
      "She will give you one piece, precisely timed, when you need it.",

    dialogueTier1: [
      "...",
      "You are younger than you appear to be.",
      "...",
    ],
    dialogueTier2: [
      "I was here before the mountain. I will be here after whatever comes next. " +
      "What you are experiencing is a middle.",
      "The dark is not the enemy of the light. The dark is where the light rests.",
    ],
    dialogueTier3: [
      "You are asking whether you were given a choice. " +
      "I was present at the assignment. I will tell you: yes. " +
      "You were given a choice. You said yes.",
      "You don't remember. That was also part of the design.",
    ],
    dialogueTier4: [
      "I have watched the Fallen since before they fell. " +
      "They are not wrong that the cost is real. " +
      "They are wrong that the cost is unjust.",
      "God made night first. Before the light, before the firmament. " +
      "Rest before labor. Dark before form. " +
      "The pattern begins with rest.",
    ],
    dialogueTier5: [
      "I have been watching you specifically since your first loop here. " +
      "I have been waiting for this moment. " +
      "You are ready for what comes next. " +
      "...",
      "Go.",
    ],
  },

  // ── HEMERA ───────────────────────────────────────────────
  hemera: {
    id: "hemera",
    name: "Hemera",
    title: "Day — Nyx's daughter, the morning light",
    location: "Appears briefly at the beginning of each run — at the threshold to the Mountain",
    appearance:
      "Young in the way mornings are young — not naive, but clean. " +
      "Light that has not yet accumulated the day's weight. " +
      "Wearing something white that is not quite cloth. " +
      "Gone before you can look directly at her.",
    role: "The breakthrough moment. Appears when a character has had a crack event. Doesn't stay.",
    accessibility: "Triggered by crack events. Cannot be approached directly. Cannot be held.",

    personality:
      "Nyx's daughter, which means she moves in relationship to her mother — " +
      "not as opposition but as rhythm. Day does not defeat Night. Day is Night's gift. " +
      "She does not have long conversations. She has one sentence, " +
      "precisely when the sentence is needed, " +
      "and then she is gone before you can ask what she meant.",

    whatSheKnows:
      "The moment of clarity. Not the sustained work of understanding — " +
      "that is the mountain's work. But the moment when the work yields something. " +
      "She appears at that moment and marks it. " +
      "Players who are paying attention will notice she has been there " +
      "every time something important happened. " +
      "Players who are really paying attention will wonder " +
      "if she causes it or witnesses it.",

    dialogueTier1: [
      "[She is there at the threshold. She does not speak. She looks at you once, and then the run begins.]",
    ],
    dialogueTier2: [
      "Something moved in you just now. I saw it.",
      "[gone]",
    ],
    dialogueTier3: [
      "The crack is not the damage. The crack is how it opens.",
      "[gone]",
    ],
    dialogueTier4: [
      "You are asking the right question.",
      "[gone]",
    ],
    dialogueTier5: [
      "It's morning.",
      "[gone]",
    ],
  },

  // ── PERSEPHONE ───────────────────────────────────────────
  persephone: {
    id: "persephone",
    name: "Persephone",
    title: "Queen of the Between",
    location: "A courtyard in the Antechamber — tending something. A garden that shouldn't grow here, but does.",
    appearance:
      "Neither the maiden nor the queen. Both. Someone who has had long enough " +
      "to understand their own nature and has stopped performing either version of it. " +
      "Tends the garden without ceremony. Will look up and talk if you come to her.",
    role: "The most genuine ally the party has in the Antechamber. Understands their position better than anyone.",
    accessibility: "Available from Run 1. Opens fully over repeated conversations.",

    personality:
      "She was taken. She ate. She stayed — and over a long time, " +
      "decided that staying had been, in some sense, a choice. " +
      "This is not a simple thing to have decided. " +
      "She doesn't pretend it is. But she has made something of the in-between " +
      "rather than being destroyed by it, " +
      "and she recognizes this project in the Seven immediately.",

    whatSheKnows:
      "What it means to belong to two worlds. " +
      "What it means to have an assignment you didn't choose and find meaning in it anyway. " +
      "The difference between resignation and acceptance — which is enormous " +
      "and rarely understood from the outside. " +
      "Hades, better than anyone. What the old system cost and what it gave.",

    dialogueTier1: [
      "You look confused about where you are. Most new ones do. " +
      "You'll stop expecting it to make sense and start expecting it to mean something. " +
      "Those are different things.",
      "The garden shouldn't grow here. It does anyway. I stopped questioning it.",
    ],
    dialogueTier2: [
      "You've been here before, you know. I recognize the shape of how you move. " +
      "Sit down. I'll tell you what I've noticed.",
      "The ones who get stuck aren't weaker than the ones who go through. " +
      "They're usually the ones who got very close to the truth and then got frightened by it.",
    ],
    dialogueTier3: [
      "The Fallen came to me once. Tried to recruit me. I understood what they were offering. " +
      "I told them I'd already tried leaving and it hadn't solved anything. " +
      "The mountain is where the work is.",
      "I think the hardest thing is discovering you were sent here by something that loves you " +
      "and that that doesn't make the difficulty less real. " +
      "Both can be true at the same time.",
    ],
    dialogueTier4: [
      "I know what you're carrying. I carried something similar for a long time. " +
      "The question isn't whether the assignment was fair. " +
      "The question is what you make of where you are.",
    ],
    dialogueTier5: [
      "You're ready. I can tell because you stopped trying to leave.",
      "When you go — and you will go — come back and tell me what it looks like from there. " +
      "I've always wondered.",
    ],

    gifts: [
      { item: "Something from the garden — a flower that doesn't belong here",
        effect: "Brings the flower to a party member. Opens a specific dialogue about belonging." },
      { item: "Seeds",
        description: "She gives these to the party after Run 10. 'For wherever you end up.' " +
        "Does not explain further." },
    ],
  },

  // ── HADES ────────────────────────────────────────────────
  hades: {
    id: "hades",
    name: "Hades",
    title: "The Displaced Administrator",
    location: "An old office in the Antechamber that nobody else uses — stone desk, dead records, something still running in the background",
    appearance:
      "The face of someone who ran something large and well for a very long time " +
      "and has not yet decided what they are without it. " +
      "Dark suit, if that means anything here. " +
      "Formal in the way that people who used to have authority stay formal after losing it.",
    role: "The institutional perspective. Critic and, eventually, unexpected ally.",
    accessibility: "Hard to find initially. Becomes available at Tier 2 through Persephone's introduction.",

    personality:
      "He was the administrator of the dead before this system replaced his. " +
      "He was not evil — he was professional. He ran the old order with precision and consistency. " +
      "He watched it get replaced by something that, in his view, is messier and more chaotic " +
      "and also, if he's honest with himself, more humane. " +
      "He has complicated feelings about this. He has complicated feelings about everything. " +
      "He respects competence. He has grudging respect for the Seven because they keep showing up.",

    whatHeKnows:
      "The old system and how it worked — before Purgatory, before the mountain. " +
      "How the architecture of the afterlife actually functions from an administrative standpoint. " +
      "The Fallen, from the old system's perspective — he knew them before they fell. " +
      "The long view that makes him, against his will, sometimes more useful than anyone.",

    dialogueTier1: [
      "You don't know where you are, and you're moving with confidence anyway. " +
      "That's either courage or foolishness and in my experience the difference only emerges in retrospect.",
      "The old system had problems. The new system has different problems. " +
      "Calling this progress requires a particular definition of progress.",
    ],
    dialogueTier2: [
      "I've watched you loop. More times than you have, obviously. " +
      "My professional assessment: you're doing better than average. " +
      "My personal assessment: you're still missing the point. " +
      "I won't tell you what the point is. That would defeat the purpose.",
    ],
    dialogueTier3: [
      "The Fallen were mine before they were Fallen, if you want to be precise about it. " +
      "Under my system they had a role. A clear one. Defined. " +
      "The clarity helped some of them and constrained others. " +
      "The ones who fell were mostly in the second category.",
      "I'm not defending them. I'm explaining them. There's a difference I've had to learn.",
    ],
    dialogueTier4: [
      "I spent a long time resenting the replacement of my system. " +
      "I've come to a different position. The old system was just. " +
      "This system is trying to be something more than just. " +
      "I'm not sure if that's possible. I'm less certain it's impossible than I used to be.",
    ],
    dialogueTier5: [
      "I'll tell you something. Off the record. " +
      "I've watched dozens of parties complete this. " +
      "Every single one of them came back through this antechamber at the end, " +
      "and not one of them looked the way they expected to look when they made it. " +
      "They looked lighter. That's all. Just — lighter. " +
      "I didn't design that and I don't fully understand it and it still interests me.",
    ],
  },

  // ── HYPNOS ───────────────────────────────────────────────
  hypnos: {
    id: "hypnos",
    name: "Hypnos",
    title: "Sleep — keeper of the space between",
    location: "Found in the Antechamber at what passes for night — asleep himself, until he isn't",
    appearance:
      "Soft. Rounded. Wearing something impractical and comfortable. " +
      "Often half-asleep even while talking. " +
      "Has a quality of existing in multiple states simultaneously that should be unsettling " +
      "but is actually, somehow, restful.",
    role: "Dream keeper. Between-loop memory. The one who knows what happens when the party isn't running.",
    accessibility: "Available after Run 5. Opens up significantly at Tier 2.",

    personality:
      "Governs the unconscious. The space between the runs is his domain — " +
      "and he has been watching the Seven's dreams since the beginning. " +
      "He has observations. He has been waiting for the right one to ask. " +
      "He is not alarming about this. He treats all dreams with the same " +
      "gentle clinical interest, including the distressing ones. " +
      "Especially the distressing ones.",

    whatHeKnows:
      "What happens to the Seven between runs — where they go, what they dream, " +
      "what their unconscious is working on without their awareness. " +
      "Dream symbols, recurring images, what each character's deepest fear " +
      "and deepest desire actually are. He will share these carefully, " +
      "and only when the character is ready to hear them.",

    dialogueTier1: [
      "Oh. You're awake. Good. That's usually the first step.",
      "You've been dreaming of a light you can't name. Most of you have, actually. " +
      "I find that interesting.",
    ],
    dialogueTier2: [
      "You want to know what you dream about between runs? " +
      "That's the first time any of you have asked directly. " +
      "Give me a moment to decide how much to tell you.",
    ],
    dreamRevealsByCharacter: {
      aeryn:  "You dream of being wrong about something important. Every time. " +
              "And in the dream, being wrong doesn't end you. " +
              "You keep being surprised by this.",
      cael:   "You dream of being asked what you want. And answering. " +
              "You never remember what you said when you wake up.",
      brennan:"You dream of a moment before the fire. " +
              "There is always a moment before the fire. " +
              "You've been trying to stay in that moment longer each time.",
      solan:  "You dream of being called back to something. " +
              "You keep going in the wrong direction on purpose. " +
              "You know you're doing it. This is important.",
      mira:   "You dream of giving something away. " +
              "Not from abundance. From the last of what you have. " +
              "And then you dream of what comes after that, which is not what you expected.",
      tobias: "You dream of a meal you've never had. " +
              "You are entirely in it. When you wake up you can't remember what it tasted like " +
              "but you can remember what it felt like to be there.",
      seren:  "You dream of being seen. Just seen. " +
              "Not desired, not admired. Just — met. " +
              "You always cry in this dream. You never know why when you wake up.",
    },
    dialogueTier3: [
      "The Fallen don't dream, you know. They made a choice that took dreaming away from them. " +
      "I'm not sure they realize what that cost.",
    ],
    dialogueTier5: [
      "The dream you're having now is different from the one you were having at the start. " +
      "I keep records. Would you like to know how they've changed? " +
      "It's rather beautiful, actually.",
    ],
  },

  // ── MNEMOSYNE ────────────────────────────────────────────
  mnemosyne: {
    id: "mnemosyne",
    name: "Mnemosyne",
    title: "Memory — the pool of remembrance",
    location: "A still pool in the deepest part of the Antechamber — past the rooms everyone uses",
    appearance:
      "You aren't entirely sure she has a form. There is a presence near the water. " +
      "The water is impossibly clear and impossibly still and looking into it is " +
      "not entirely comfortable. She is the pool and beside the pool and the quality of attention " +
      "you feel when standing near it.",
    role: "Late-game memory return. The mechanism of true names. Not a quest — an arrival.",
    accessibility: "Location available from Tier 2. Nothing happens until Tier 3. Full function at Tier 4+.",

    personality:
      "Does not push. Does not beckon. Does not teach. " +
      "She holds what was always yours and gives it back when you are ready for it. " +
      "The readiness is not something she judges — she simply knows it. " +
      "Coming to the pool before you're ready gives you nothing. " +
      "Not because she withholds — because there is nothing yet to give back. " +
      "The memory isn't locked behind her. It's locked behind the work.",

    whatSheGives:
      "Fragments of true names. Memories from before the assignment. " +
      "The specific moment each character said yes. " +
      "The original virtue as it was before the blur. " +
      "She does not explain these. She returns them. " +
      "The understanding is the character's own work.",

    dialogueTier2: [
      "[The pool is still. Nothing happens. But you feel, standing here, " +
      "that something knows you are standing here.]",
    ],
    dialogueTier3: [
      "[Something surfaces in the pool — not an image. A feeling. " +
      "The feeling of being someone specific, in a moment before this one, " +
      "making a choice. The feeling fades before you can hold it.]",
    ],
    dialogueTier4_fragments: {
      aeryn:  "You are standing in light so complete it has no source. You are asked if you will carry it. You say yes.",
      cael:   "You are given a set of scales. You hold them perfectly steady. You have never held anything this carefully. You say yes.",
      brennan:"You are shown something unjust. The fire rises in you clean and clear. It does not destroy the one who shows you. You say yes.",
      solan:  "You are given every mystery. All at once. You are asked if you can hold it without it becoming a weight. You say yes.",
      mira:   "You are given a world and told: there is enough. Care for what is here. You look at it and believe it. You say yes.",
      tobias: "You are given the capacity for joy. Complete, unguarded. You are told: this is what existence is supposed to feel like. You say yes.",
      seren:  "You are given the ability to love without consuming. To know fully and hold gently. You are shown what this looks like and it is the most beautiful thing you have seen. You say yes.",
    },
    dialogueTier5: [
      "[The pool shows you your own face. Not the one you're wearing. The other one. " +
      "You recognize it.] ",
    ],
  },

  // ── THE ARCHIVIST ────────────────────────────────────────
  archivist: {
    id: "archivist",
    name: "Casimir",
    title: "The Archivist",
    location: "A library corner of the Antechamber — books and maps and an oil lamp that never goes out",
    appearance:
      "Old. Not ancient like the mythological figures — old in a human way. " +
      "Ink stains. Reading glasses. More records than anyone has asked him to keep. " +
      "Warm. Genuinely, simply warm in a way that makes the Antechamber feel livable.",
    role: "Lore delivery without feeling like exposition. Human heart of the hub.",
    accessibility: "Available from Run 1. Always has something new to say.",

    personality:
      "Has been recording 'the pattern' for decades without knowing what he's actually documenting. " +
      "He maps historical cycles — the rise and fall of civilizations, the repetition of certain " +
      "kinds of conflicts, the recurring human responses to recurring human conditions. " +
      "He doesn't know he's been mapping every loop. " +
      "He's gotten dangerously close to the truth, from a completely human direction, " +
      "through pure scholarship. " +
      "He is the character who will know before anyone tells him. " +
      "Players will watch him get there.",

    whatHeKnows:
      "Everything about historical cycles from a scholarly perspective. " +
      "Fragments of every era. The specific historical souls the party is encountering " +
      "— he has records of them, documents about their lives, " +
      "though he doesn't know they're literally upstairs. " +
      "He will, eventually, know everything. " +
      "The party will have to decide what to do with that.",

    dialogueTier1: [
      "You look like you've been somewhere interesting. Sit down. Tell me what you saw.",
      "I've been charting the pattern for thirty years. Every hundred years, the same conflicts. " +
      "Different names. Same shape. I used to think it was coincidence.",
      "Here — I found a reference to this region in a text from eight hundred years ago. " +
      "The geography is identical. The parties involved are different. The events are not.",
    ],
    dialogueTier2: [
      "I've been having a very strange feeling lately. " +
      "That I've been doing this work before. Not just studying history — " +
      "that I specifically have studied these specific patterns before. " +
      "I don't know what to do with that.",
      "I found a reference to something called 'The Appointed' in a medieval text. " +
      "Seven figures. Sent to walk with humanity. I've been trying to find more references. " +
      "There aren't many. It's like someone removed them.",
    ],
    dialogueTier3: [
      "I have to ask you something and I need you to answer honestly. " +
      "Have you been to this mountain before? " +
      "Not in memory. In fact. " +
      "Because if you have, there are things in my records that I need to show you.",
    ],
    dialogueTier4: [
      "I know what you are. " +
      "I've known for three weeks and I've been deciding whether to say anything. " +
      "It changes the work but it doesn't change the work, if you understand me. " +
      "The patterns are still the patterns. " +
      "It just explains why someone needed to understand them from the inside.",
    ],
    dialogueTier5: [
      "Everything I've spent my life recording — the cycles, the patterns, the repetition — " +
      "it's all one thing, isn't it. It's one very long sentence that humanity " +
      "keeps starting over because they keep losing the beginning.",
      "Go finish it. I'll keep the records.",
    ],

    gifts: [
      { item: "A map of the mountain, partial and wrong in interesting ways",
        description: "He gives this in good faith. Some of it is more accurate than he knows." },
      { item: "A record of a historical figure the party has met",
        description: "He has no idea the party knows this person personally. The record is accurate " +
        "and touches aspects the party hasn't asked about yet." },
      { item: "His thirty years of pattern work, compiled",
        description: "Late game. He gives this freely. " +
        "'Use it. It was always for someone other than me.'" },
    ],
  },
};

// ── Helpers ──────────────────────────────────────────────────

export const HUB_CHARACTER_IDS = Object.keys(HUB_CHARACTERS);

export function getHubCharacter(id) {
  return HUB_CHARACTERS[id] ?? null;
}

export function getHubDialogue(characterId, tier) {
  const char = HUB_CHARACTERS[characterId];
  if (!char) return [];
  const key = `dialogueTier${tier}`;
  return char[key] ?? [];
}

// Characters available from the start vs requiring discovery
export const HUB_CHARACTER_AVAILABILITY = {
  charon:      { availableFromRun: 1, requiresIntroduction: false },
  persephone:  { availableFromRun: 1, requiresIntroduction: false },
  archivist:   { availableFromRun: 1, requiresIntroduction: false },
  hypnos:      { availableFromRun: 5, requiresIntroduction: false },
  nyx:         { availableFromRun: 1, requiresIntroduction: false, triggeredByLowClarity: true },
  hemera:      { availableFromRun: 1, requiresIntroduction: false, triggeredByCrackEvents: true },
  hades:       { availableFromRun: 10, requiresIntroduction: true, introducedBy: "persephone" },
  mnemosyne:   { availableFromRun: 1, requiresIntroduction: false, functionsTier: 3 },
};
