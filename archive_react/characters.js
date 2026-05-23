// ============================================================
//  THE APPOINTED: AS ABOVE
//  characters.js — The Seven. Human names, true names, full arcs.
// ============================================================
//
//  DESIGN NOTE:
//  Every character carries a sin they don't recognize as a sin —
//  because it wears the costume of a virtue. The game's work is
//  stripping the costume through reflection, not confrontation.
//
//  The sin is never attacked directly. It is mirrored until
//  the character can finally see it.
// ============================================================

export const CHARACTERS = {

  // ── 1. PRIDE → Righteousness ─────────────────────────────

  aeryn: {
    id: "aeryn",
    humanName: "Aeryn",
    trueName: "Luciel",          // Light-bearer — the one who almost fell
    trueNameMeaning: "Bearer of the First Light",
    sin: "pride",
    sinLabel: "Pride",
    costume: "Righteousness",
    virtue: "Dignity",
    costumeDescription:
      "Aeryn doesn't experience pride as vanity. They experience it as clarity. " +
      "The world has a right and a wrong and Aeryn can see which is which. " +
      "This certainty has saved the party many times. It has also cost them things " +
      "they haven't finished counting.",

    // What the character presents to the world
    surfacePersonality:
      "The leader. Magnetic, decisive, genuinely moral. The one people naturally " +
      "defer to because Aeryn is usually right. Calm in crisis. Absolute in judgment. " +
      "Has a quality of stillness that reads as strength — and sometimes is.",

    // What lives underneath
    wound:
      "Aeryn is terrified of being wrong — not for practical reasons but " +
      "because their entire architecture of self is built on being right. " +
      "Every decision made with certainty is a load-bearing wall in a structure " +
      "they cannot allow to be inspected. If they are wrong about this, " +
      "they might be wrong about everything. And if they're wrong about everything, " +
      "what are they?",

    // The moment the costume begins to crack
    crackEvent:
      "Aeryn meets a soul on the mountain who did exactly what they did — same " +
      "certainty, same mandate, same peace in the doing of it — for a cause that " +
      "history has judged catastrophically wrong. From the outside the two are " +
      "indistinguishable. Aeryn has to sit with one question: " +
      "how do I know the difference between my certainty and theirs?",

    // What waits on the other side
    resolution:
      "Dignity without the armor of certainty. The capacity to act without " +
      "God guaranteeing the outcome in advance. Conviction that can hold " +
      "uncertainty rather than being destroyed by it. " +
      "Aeryn becomes the leader who says 'I might be wrong' and leads anyway — " +
      "and discovers this is harder and more powerful than certainty ever was.",

    // Historical soul assigned to this arc
    historicalSoul: "nebuchadnezzar",

    // Job progression — jobs that match this arc
    jobArc: ["knight", "templar", "devoted"],
    startingJob: "soldier",

    // Stats lean — how this character plays
    statLean: { str: 8, def: 7, mag: 4, spd: 5, fth: 9 },
    // Faith (fth) is a stat unique to this game — spiritual clarity that
    // affects how much of the truth a character can access at once.

    // Relationship tensions with other party members
    relationships: {
      cael:   { tension: "Aeryn needs to be recognized. Cael keeps score. They orbit " +
                "each other in a conversation about worth that neither can finish.",
                intimacyRequired: 20 },
      brennan:{ tension: "Aeryn and Brennan are two kinds of certainty. They almost " +
                "never disagree about the target. They always disagree about the method.",
                intimacyRequired: 15 },
      solan:  { tension: "Aeryn acts. Solan watches. Aeryn cannot understand Solan's " +
                "paralysis. Solan cannot explain that not-acting is sometimes the " +
                "thing that keeps the fire from spreading.",
                intimacyRequired: 25 },
      mira:   { tension: "Mutual respect. Both practical. Neither fully trusts the other's " +
                "definition of 'enough.'",
                intimacyRequired: 10 },
      tobias: { tension: "Tobias is the only one who can soften Aeryn. The warmth " +
                "bypasses the certainty. Aeryn doesn't know what to do with that.",
                intimacyRequired: 12 },
      seren:  { tension: "Seren sees Aeryn completely. Aeryn knows it. Is the only " +
                "relationship in Aeryn's life where being known is not a threat. " +
                "This terrifies Aeryn.",
                intimacyRequired: 30 },
    },

    // Hub dialogue seeds — what Aeryn says at different revelation tiers
    hubDialogue: {
      tier1: [
        "The objective is clear. I don't understand why the others hesitate.",
        "Every decision has a right answer. Finding it takes discipline.",
        "We've been given a purpose. I won't apologize for pursuing it completely.",
      ],
      tier2: [
        "There was a moment in the last battle... one of them stopped. Just stopped. " +
        "And looked at me. I don't know what I saw in its face.",
        "I keep making the right calls. I know I keep making the right calls. " +
        "So why does it feel like something is accumulating?",
      ],
      tier3: [
        "The one who called itself Veriel — it knew my name. Not this name. " +
        "Something older. I told it that was impossible.",
        "It said: 'You've been here before. Every loop, the same certainty, " +
        "the same cost. Do you ever ask yourself who taught you to be this sure?'",
        "I didn't have an answer. I've been writing one ever since.",
      ],
      tier4: [
        "I met a man today who had been certain about everything. " +
        "Completely, peacefully certain. He was wrong about all of it. " +
        "He didn't know. How would he have known? How do I know?",
      ],
      tier5: [
        "It was never about whether I was right enough. I understand that now.",
        "Luciel. Someone said that name to me and I — I felt it land somewhere " +
        "very deep and old, and I didn't correct them.",
      ],
    },

    // Gifts that deepen the relationship — found in the world, brought back
    hubGifts: [
      { name: "A broken compass",
        description: "Points in four directions simultaneously. Useless. Aeryn holds " +
        "it longer than makes sense." },
      { name: "A judgment scroll, half-burned",
        description: "A record of a trial. The verdict is missing. " +
        "Something about the incompleteness bothers Aeryn and they can't say why." },
      { name: "A crown of thorns, dried",
        description: "No explanation needed. Aeryn doesn't speak for a long time " +
        "after you give them this." },
    ],

    flavorText: {
      tier1: "Carries conviction like a weapon and has never considered " +
             "that weapons cut both directions.",
      tier2: "Something in the certainty has a small cold room inside it " +
             "that Aeryn does not open.",
      tier3: "The light that bears them is the same light that makes shadows.",
      tier4: "Learning to hold what they know and what they don't " +
             "in the same hand without either falling.",
      tier5: "The first light, returned to itself.",
    },
  },

  // ── 2. ENVY → Righteous Advocacy ─────────────────────────

  cael: {
    id: "cael",
    humanName: "Cael",
    trueName: "Zaqiel",
    trueNameMeaning: "Purity of God — the keeper of divine justice",
    sin: "envy",
    sinLabel: "Envy",
    costume: "Righteous Advocacy",
    virtue: "Justice",
    costumeDescription:
      "Cael doesn't envy. Cael fights for fairness. For others. Always for others. " +
      "The work is real, the causes are right, the injustice being fought is genuine. " +
      "What has never been examined is what fuels it — the personal argument " +
      "with the universe's distribution that runs underneath every righteous cause " +
      "like a river under ice.",

    surfacePersonality:
      "Quiet. Watchful. The one who notices everything and says little. " +
      "Remembers every slight done to anyone they've traveled with. " +
      "Would give their last resource to someone who had less. " +
      "Reads as selfless — and is selfless — and also cannot name a single " +
      "thing they want for themselves.",

    wound:
      "To want something for yourself feels like selfishness. To acknowledge " +
      "the gap between what you have and what you want feels like envy — " +
      "which Cael knows is ugly. So desire gets laundered through causes. " +
      "The hunger is real. The direction it travels is a disguise. " +
      "Cael has been advocating for everyone's right to want things " +
      "while quietly suffocating their own.",

    crackEvent:
      "Someone asks Cael what they want. Not for the world. Not for others. " +
      "For themselves. Right now. One thing. " +
      "The silence that follows is the longest moment in the game. " +
      "Cael opens their mouth twice. Nothing comes.",

    resolution:
      "The justice that was always there, freed from the personal. " +
      "Cael who can name what they want without shame — and discovers that " +
      "wanting things for yourself doesn't make the work for others less real. " +
      "It makes it sustainable. Justice that includes the self.",

    historicalSoul: "cain",
    jobArc: ["rogue", "shadow", "chronicler"],
    startingJob: "archer",

    statLean: { str: 5, def: 5, mag: 7, spd: 8, fth: 6 },

    relationships: {
      aeryn:  { tension: "Cael has been keeping score on Aeryn since the beginning. " +
                "Aeryn doesn't know this. The score is complicated — " +
                "part resentment, part something that looks a lot like admiration " +
                "that Cael won't call admiration.",
                intimacyRequired: 20 },
      brennan:{ tension: "Cael appreciates Brennan's fire and is quietly exhausted by it. " +
                "Brennan fights. Cael measures. Both think the other is missing something.",
                intimacyRequired: 18 },
      solan:  { tension: "Unexpected. Cael and Solan are the two who observe. " +
                "They have more in common than either admits. " +
                "The first honest conversation they have surprises them both.",
                intimacyRequired: 22 },
      mira:   { tension: "Cael has noticed exactly what Mira has and what Mira does with it. " +
                "This is a source of private judgment that Cael has not examined.",
                intimacyRequired: 14 },
      tobias: { tension: "Tobias is the only person who makes Cael genuinely laugh. " +
                "Cael would not tell them this.",
                intimacyRequired: 10 },
      seren:  { tension: "Seren read Cael on day one. Cael knows it. " +
                "Has been waiting for Seren to use it against them. " +
                "Seren hasn't. This has created a strange, fragile trust.",
                intimacyRequired: 28 },
    },

    hubDialogue: {
      tier1: [
        "The distribution of resources in this camp is irrational. I've adjusted it.",
        "I fight for the ones who can't fight for themselves. That's all this is.",
        "I don't need recognition. The work is the point.",
      ],
      tier2: [
        "I watched one of the enemies hesitate today. Just — hesitate. " +
        "And I thought: I know that feeling. The moment before you decide.",
        "Why does everyone assume I'm angry? I'm not angry. I'm paying attention.",
      ],
      tier3: [
        "The one called Sidriel said something I can't stop turning over. " +
        "It said: 'You fight for everyone's worth except your own. " +
        "Do you know why that is?'",
        "I told it it was wrong. I've been arguing with it in my head for three days.",
      ],
      tier4: [
        "Someone asked me today what I want. Just — for myself. " +
        "I've been trying to answer that question for what feels like a very long time.",
      ],
      tier5: [
        "I wanted to be seen. That's what it was. Under all of it.",
        "Justice that forgets the self isn't justice. It's just a better-dressed hunger.",
      ],
    },

    hubGifts: [
      { name: "A balance scale, one side heavier",
        description: "The weights are identical. The scale is wrong. " +
        "Cael stares at it for a very long time." },
      { name: "A letter, addressed but never sent",
        description: "Found in the ruins. The contents are private. " +
        "Cael reads it and says nothing about it, but keeps it." },
      { name: "A single coin, worn smooth",
        description: "Too old to have a face anymore. " +
        "Cael says: 'Everything that was distinct about it is gone.' " +
        "Doesn't elaborate." },
    ],

    flavorText: {
      tier1: "Carries the world's ledger in their head and checks it constantly, " +
             "for everyone but themselves.",
      tier2: "The advocacy is real. The wound that drives it has been patient.",
      tier3: "Zaqiel, whose virtue was the hunger for what is right — " +
             "hasn't yet learned that they are included in 'what is right.'",
      tier4: "Something quiet moving toward something real.",
      tier5: "Justice, including the self. At last.",
    },
  },

  // ── 3. WRATH → Holy Zeal ──────────────────────────────────

  brennan: {
    id: "brennan",
    humanName: "Brennan",
    trueName: "Camael",
    trueNameMeaning: "Burning of God — Strength and divine force",
    sin: "wrath",
    sinLabel: "Wrath",
    costume: "Holy Zeal",
    virtue: "Righteous Anger",
    costumeDescription:
      "Brennan doesn't have a temper problem. Brennan has a justice problem — " +
      "meaning: everywhere they look, there is injustice, and the anger is always " +
      "the appropriate response to it. The theological framework is airtight. " +
      "Jesus overturned tables. The prophets raged. Righteous anger is not a sin. " +
      "What Brennan hasn't asked is whether the anger was there before the causes.",

    surfacePersonality:
      "The fighter. Direct, strong, magnetic in a physical way that makes people " +
      "feel safer near them. Genuinely protective. Has a moral line and will not " +
      "cross it. Is loudly and completely present in every encounter. " +
      "The party relies on this. It is also, sometimes, exhausting.",

    wound:
      "Something was done to Brennan that they have never named. " +
      "The anger makes complete sense as a response to that original thing. " +
      "But the original thing is buried under years of righteous causes, " +
      "and excavating down to it means admitting the anger is about them — " +
      "which feels like making it small. Making it personal. " +
      "Which feels like weakness.",

    crackEvent:
      "They win. The cause is resolved. The injustice is corrected. " +
      "And within days the anger has found a new home. Brennan is standing " +
      "in front of a new target with the same fire and the same certainty, " +
      "and something in them goes very quiet and asks: " +
      "was this ever about the cause?",

    resolution:
      "Righteous anger that knows what it's for. Fire that has a direction " +
      "and a limit — not because the limit is imposed from outside, " +
      "but because Brennan finally knows where the fire comes from " +
      "and has stopped needing it to prove something.",

    historicalSoul: "moses",
    jobArc: ["soldier", "knight", "fated"],
    startingJob: "soldier",

    statLean: { str: 10, def: 8, mag: 3, spd: 6, fth: 5 },

    relationships: {
      aeryn:  { tension: "Two certainties. Almost never disagree about the target. " +
                "Always disagree about the method. The respect is genuine. " +
                "The friction is load-bearing.",
                intimacyRequired: 15 },
      cael:   { tension: "Brennan acts. Cael measures. Brennan thinks Cael's precision " +
                "is hesitation dressed up. Cael thinks Brennan's fire is grief dressed up. " +
                "They might both be right.",
                intimacyRequired: 18 },
      solan:  { tension: "The hardest relationship in the party. " +
                "Brennan cannot be in the same room with someone who sees everything " +
                "and feels nothing. Solan cannot explain that they feel everything " +
                "and that's the problem.",
                intimacyRequired: 35 },
      mira:   { tension: "Uncomplicated mutual appreciation. " +
                "Brennan provides safety. Mira provides comfort. " +
                "Neither has looked underneath that exchange.",
                intimacyRequired: 12 },
      tobias: { tension: "Brennan is the only person who can make Tobias " +
                "stop mid-worry and just be here. Tobias is the only person " +
                "who slows Brennan down without feeling like an obstacle.",
                intimacyRequired: 10 },
      seren:  { tension: "Seren is the one person Brennan cannot read. " +
                "This is deeply unsettling and Brennan covers it with volume.",
                intimacyRequired: 22 },
    },

    hubDialogue: {
      tier1: [
        "There's nothing complicated about this. Wrong things get corrected. That's all.",
        "The others think too much. Sometimes you just have to act.",
        "I don't apologize for the fire. The things I'm burning deserve it.",
      ],
      tier2: [
        "One of them stopped fighting me today. Just... sat down in the middle of the battle. " +
        "Looked at its hands. I almost didn't swing.",
        "I've been angrier than usual. I'm not sure what at.",
      ],
      tier3: [
        "The fallen one — Arariel — it said I've been angry since before I can remember. " +
        "It said: 'You arrived here burning. What did you carry in from before?'",
        "I told it to go to hell. Which, technically.",
      ],
      tier4: [
        "I won. The whole thing. Everything we were fighting for, resolved. " +
        "I thought I'd feel something other than this.",
        "There's a man on the mountain — Moses. He hit a rock because he was tired. " +
        "Cost him everything. He doesn't blame himself anymore. I don't know how he did that.",
      ],
      tier5: [
        "The fire is still there. It's just mine now. Not something that happened to me.",
        "I think I've been punishing myself for something I never decided to feel.",
      ],
    },

    hubGifts: [
      { name: "A sword, snapped in half",
        description: "Brennan picks it up slowly. Sets it down. Picks it up again. " +
        "Says: 'It was the right sword. It just broke at the wrong moment.'" },
      { name: "Ashes in a sealed container",
        description: "Brennan doesn't open it. Holds it a long time. Says: " +
        "'Something worth burning was here.'" },
      { name: "A child's drawing of a fire",
        description: "Brennan stares at this for longer than is comfortable. " +
        "You don't ask. They don't explain." },
    ],

    flavorText: {
      tier1: "The fire arrived before the causes. The causes came to explain it.",
      tier2: "Even the just war has a moment before the first blow " +
             "where everything is still possible.",
      tier3: "Camael, whose virtue was righteous force — " +
             "still learning the difference between fire that warms and fire that takes.",
      tier4: "The anger is real. What made it is also real. Both can be true.",
      tier5: "Burning of God — now burning clean.",
    },
  },

  // ── 4. SLOTH → Contemplation ─────────────────────────────

  solan: {
    id: "solan",
    humanName: "Solan",
    trueName: "Raziel",
    trueNameMeaning: "Secret of God — keeper of divine mysteries",
    sin: "sloth",
    sinLabel: "Sloth",
    costume: "Contemplation",
    virtue: "Sacred Rest",
    costumeDescription:
      "Solan isn't lazy. That would be simple. Solan is — elsewhere. " +
      "The inner life is rich, genuine, and deep. There is prayer and meditation " +
      "and observation and the accumulation of understanding. The understanding " +
      "is always almost complete. Almost. When it's finished, Solan will be ready. " +
      "The 'when' has not arrived in any loop.",

    surfacePersonality:
      "The observer. The most intelligent member of the party by a significant margin. " +
      "Has already mapped the emotional terrain of every encounter before it begins. " +
      "Brilliant, calm, economical with words. Reads as wisdom. " +
      "Occasionally an absence wearing wisdom's clothing.",

    wound:
      "Presence is painful. Being here — fully, in the specific weight of " +
      "what is actually happening — is something Solan cannot sustain. " +
      "The inner life is genuine. It is also a beautifully decorated room " +
      "with no doors leading out. The contemplation that was supposed to " +
      "prepare Solan for the world has become an alternative to it.",

    crackEvent:
      "A soul that needed them specifically. Not someone else. Not a different response. " +
      "Solan. There. In that moment. " +
      "Solan was in retreat. " +
      "The soul is now beginning to calcify into a Type 2 encounter — " +
      "and it is not abstract anymore. " +
      "Solan will see the face of what they didn't do.",

    resolution:
      "Sacred rest that is chosen, not fled to. Stillness that contains the world " +
      "rather than excluding it. The vast intelligence of Raziel turned outward — " +
      "not in service of readiness, but in service of the specific moment " +
      "in front of them. Presence as a practice, not a performance.",

    historicalSoul: "qoheleth",
    jobArc: ["mage", "conjurer", "oracle"],
    startingJob: "mage",

    statLean: { str: 3, def: 5, mag: 10, spd: 4, fth: 9 },

    relationships: {
      aeryn:  { tension: "Solan sees exactly what Aeryn is doing and why. " +
                "Has been deciding whether to say so for what feels like a very long time.",
                intimacyRequired: 25 },
      cael:   { tension: "The two observers. First conversation was longer than " +
                "either expected. Both surprised. Neither mentioned it again.",
                intimacyRequired: 22 },
      brennan:{ tension: "The hardest relationship in the party for Solan too. " +
                "Brennan's presence is so loud it's almost physical. " +
                "Solan understands exactly why Brennan is the way they are " +
                "and has said nothing about it. This is either wisdom or cowardice. " +
                "Solan is not sure.",
                intimacyRequired: 35 },
      mira:   { tension: "Mild mutual appreciation. Neither demands much from the other. " +
                "Solan suspects there is more to Mira than this. Has not investigated.",
                intimacyRequired: 12 },
      tobias: { tension: "Tobias brings food to Solan without being asked. " +
                "Solan accepts without ceremony. This has become a ritual " +
                "that neither would describe as friendship and both would miss.",
                intimacyRequired: 8 },
      seren:  { tension: "The relationship the party doesn't see. Solan and Seren " +
                "have had exactly three real conversations. Each one went very deep " +
                "very fast and then they both retreated. The third one changed something.",
                intimacyRequired: 30 },
    },

    hubDialogue: {
      tier1: [
        "I'll be ready when I've processed what happened. Give me time.",
        "The pattern here is more complex than the others realize. I'm mapping it.",
        "Observation isn't passivity. It's precision.",
      ],
      tier2: [
        "Something in the composition of the air changes when the enemies hesitate. " +
        "I've been cataloguing it. I don't know yet what to do with the catalogue.",
        "I've been sitting with a question that won't resolve. I find I don't mind.",
      ],
      tier3: [
        "A soul I failed to reach in the last run — I saw it again. " +
        "It looked at me. There was recognition in it and also something else. " +
        "I catalogued it. I'm not sure cataloguing was the right response.",
        "The Fallen asked me: 'What are you waiting to be ready for?' " +
        "I have been thinking about that question for three runs.",
      ],
      tier4: [
        "Ecclesiastes. Vanity of vanities. I've been reading it as despair for a long time. " +
        "I think it might actually be relief.",
        "Qoheleth found something small and true in the ash of everything. " +
        "I've been burning things to find out what survives.",
      ],
      tier5: [
        "I know the secret of God. I have always known it. " +
        "The secret is: presence. Just this. Just here.",
        "Raziel. I've been calling myself that in private for longer than I realized.",
      ],
    },

    hubGifts: [
      { name: "An unfinished manuscript",
        description: "Dense, careful handwriting. Stops mid-sentence. " +
        "Solan reads it all. Says: 'They almost got there.'" },
      { name: "A mirror, covered with cloth",
        description: "Solan doesn't uncover it immediately. Leaves it in the corner. " +
        "Looks at it from across the room for several days." },
      { name: "Seeds, dried and labeled",
        description: "Varieties from every region. Meticulous labels. " +
        "Solan says, quietly: 'Someone was planning to stay somewhere.'"},
    ],

    flavorText: {
      tier1: "Knows everything about what is happening and is still deciding " +
             "whether to be present for it.",
      tier2: "The room inside has no windows. This was the design. This was also the problem.",
      tier3: "Raziel held the secrets of heaven. Forgot to hold the present moment.",
      tier4: "Everything is vanity except this: the person in front of you, right now.",
      tier5: "The Secret of God, arrived at last.",
    },
  },

  // ── 5. GREED → Stewardship ───────────────────────────────

  mira: {
    id: "mira",
    humanName: "Mira",
    trueName: "Sachiel",
    trueNameMeaning: "Covered by God — angel of abundance and expansion",
    sin: "greed",
    sinLabel: "Greed",
    costume: "Stewardship",
    virtue: "Provision",
    costumeDescription:
      "Mira doesn't hoard. Mira manages. There is an enormous difference " +
      "and Mira can explain it at length. What has been entrusted must be cared for. " +
      "Abundance signals faithfulness. Scarcity signals spiritual failure. " +
      "The theological framework makes Mira both the most generous person in the room " +
      "and completely immune to any conversation about what the generosity costs others.",

    surfacePersonality:
      "Warm, competent, the logistics mind of the party. " +
      "Makes sure everyone is fed, equipped, and accounted for. " +
      "Gives readily and visibly. Controls completely and invisibly. " +
      "The word 'provider' fits. So does 'owner.'",

    wound:
      "Scarcity — not necessarily material, but felt. The lived experience " +
      "of not-enough, of things being taken, of security being one bad moment " +
      "from collapse. The accumulation is armor against a fear that no amount " +
      "of accumulation has ever actually addressed, " +
      "because the fear predates the resources.",

    crackEvent:
      "Someone who contributed to Mira's abundance — who worked within it, " +
      "helped build it — is suffering. Mira has the resources. " +
      "And Mira opens their mouth and the theological justification comes out. " +
      "And they hear it. For the first time, they actually hear what they're saying. " +
      "The armor shows itself from the outside.",

    resolution:
      "Provision — the genuine care of what has been entrusted, " +
      "in actual trust that there will be enough. " +
      "Mira who gives without conditions, " +
      "not because they've become reckless, " +
      "but because the fear that was running the management has been named " +
      "and the naming changed its power.",

    historicalSoul: "judas",
    jobArc: ["vagrant", "rogue", "heretic"],
    startingJob: "vagrant",

    statLean: { str: 6, def: 7, mag: 5, spd: 7, fth: 5 },

    relationships: {
      aeryn:  { tension: "Mutual respect. Two practical people who share the burden " +
                "of keeping the party functional. Neither is entirely transparent " +
                "about their methods.",
                intimacyRequired: 10 },
      cael:   { tension: "Cael has been watching what Mira has and what Mira does with it. " +
                "Mira suspects this. Neither has named it. " +
                "There is a conversation waiting.",
                intimacyRequired: 14 },
      brennan:{ tension: "Mira provides comfort. Brennan provides safety. " +
                "The exchange is easy and good and neither of them has asked " +
                "what they'd be without it.",
                intimacyRequired: 12 },
      solan:  { tension: "Surface-level mutual appreciation. " +
                "Both sense there is more to the other. Neither has pressed.",
                intimacyRequired: 12 },
      tobias: { tension: "The most complicated relationship in the party. " +
                "Mira and Tobias are running the same wound in opposite directions — " +
                "compulsion and restriction, accumulation and denial — " +
                "and they recognize something in each other without knowing why. " +
                "It is either the beginning of healing or enabling. The game decides.",
                intimacyRequired: 28 },
      seren:  { tension: "Seren is the only person who makes Mira feel " +
                "actually known rather than approved of. " +
                "Mira doesn't know what to do with this yet.",
                intimacyRequired: 20 },
    },

    hubDialogue: {
      tier1: [
        "I've audited the supply stores. We're better positioned than I'd like but adequate.",
        "Generosity without planning is just spending. I take care of this party.",
        "God has provided abundantly. It would be ungrateful to receive it carelessly.",
      ],
      tier2: [
        "I gave something away today that I didn't need. " +
        "And then I thought about it for the rest of the day.",
        "I keep track of what everyone has. I've never thought about why.",
      ],
      tier3: [
        "The Fallen one — it said I've been building a fortress out of provision. " +
        "That every act of care has been a brick in a wall I can control.",
        "I told it that was uncharitable. It said: 'I'm not criticizing you. " +
        "I'm recognizing you. I built the same thing.'",
      ],
      tier4: [
        "Judas. I found him on the mountain. He wasn't trying to betray anything. " +
        "He was trying to hold the moment in his hands before it slipped away. " +
        "I understand that better than I expected.",
      ],
      tier5: [
        "The fear was real. The fear doesn't have to be the architect anymore.",
        "Sachiel. It means 'covered by God.' I've been covering myself. " +
        "I don't think that's what it meant.",
      ],
    },

    hubGifts: [
      { name: "An empty lockbox, key inside",
        description: "Mira holds the key for a long time. Then puts it inside the box. Locks it. " +
        "Stands there with the locked box and the key on the outside. Says nothing." },
      { name: "Seed money from an ancient mint",
        description: "Currency from a civilization that no longer exists. " +
        "Worth nothing. Mira has it appraised anyway." },
      { name: "A letter of debt, marked 'forgiven'",
        description: "Mira reads it three times. Sets it down. " +
        "Picks it up. Says: 'Who decides this?'" },
    ],

    flavorText: {
      tier1: "Generous in ways that are visible. Controlling in ways that aren't. " +
             "The theology covers both.",
      tier2: "The fortress was built against something real. " +
             "The real thing ended a long time ago.",
      tier3: "Sachiel, whose virtue was abundance in trust — " +
             "accumulating against a scarcity that was never coming back.",
      tier4: "The fear named is a different size than the fear unnamed.",
      tier5: "Provision, freely given — and at last, freely received.",
    },
  },

  // ── 6. GLUTTONY → Bodily Purity ──────────────────────────

  tobias: {
    id: "tobias",
    humanName: "Tobias",
    trueName: "Muriel",
    trueNameMeaning: "Myrrh of God — angel of joy, emotion, and sacred sensory experience",
    sin: "gluttony",
    sinLabel: "Gluttony",
    costume: "Bodily Purity",
    virtue: "Joy",
    costumeDescription:
      "Tobias doesn't overindulge. Tobias disciplines. The flesh is weak and must " +
      "be governed — this is the faith, and Tobias lives it. Every meal a " +
      "theological event. Every hunger pang a test. The discipline is real. " +
      "The obsessive attention to the body underneath the discipline is identical, " +
      "structurally, to the compulsion it replaced. The neural pathway is the same. " +
      "The direction is opposite. The compulsion is the same compulsion.",

    surfacePersonality:
      "The warmth of the party. Makes people laugh, finds food in ruined places, " +
      "insists on rest. Beloved. Has an extraordinary capacity to make the present " +
      "moment feel livable. Underneath the warmth is a vigilance about their own body " +
      "that they carry so quietly that no one in the party has named it.",

    wound:
      "The hunger keeps returning. The return of the hunger feels like failure. " +
      "The failure is evidence that the flesh is indeed weak and the discipline " +
      "must be harder. The body that was supposed to stop mattering " +
      "has never mattered more. Joy — genuine, unguarded, sufficient — " +
      "has become something Tobias can only approach carefully " +
      "and never fully enter.",

    crackEvent:
      "An unguarded moment. A meal shared, warmth, laughter, good food " +
      "eaten without thinking. Tobias is halfway through the joy " +
      "before they realize they haven't categorized it yet. " +
      "They've just — been in it. " +
      "The terror that follows the joy is the most revealing thing in the game.",

    resolution:
      "Joy. The full celebration of being alive as an act of gratitude. " +
      "Not recklessness — not the compulsion running in a different direction — " +
      "but the ability to receive good things completely. " +
      "The body not as enemy and not as project but as the place where " +
      "the divine meets the world.",

    historicalSoul: "elijah",
    jobArc: ["cleric", "summoner", "wanderer"],
    startingJob: "cleric",

    statLean: { str: 5, def: 6, mag: 7, spd: 5, fth: 8 },

    relationships: {
      aeryn:  { tension: "Tobias is the only one who can soften Aeryn. " +
                "The warmth bypasses the certainty. " +
                "Aeryn doesn't understand how this works and is quietly grateful for it.",
                intimacyRequired: 12 },
      cael:   { tension: "Tobias makes Cael genuinely laugh. " +
                "This is a small miracle and Tobias doesn't know they're performing it.",
                intimacyRequired: 10 },
      brennan:{ tension: "They slow each other down in the best way. " +
                "Brennan's presence makes Tobias more here. " +
                "Tobias's warmth makes Brennan less loud. Both are better for it.",
                intimacyRequired: 10 },
      solan:  { tension: "Tobias brings food without being asked. " +
                "This has become a ritual neither calls friendship. " +
                "It is one of the most important relationships in the party.",
                intimacyRequired: 8 },
      mira:   { tension: "The same wound running in opposite directions. " +
                "Recognizing each other without knowing why. " +
                "Potentially transformative, potentially the most enabling " +
                "relationship in the party.",
                intimacyRequired: 28 },
      seren:  { tension: "Seren makes Tobias feel welcomed into their own body. " +
                "Tobias doesn't have language for this yet. It is one of the " +
                "most significant things that has ever happened to them.",
                intimacyRequired: 25 },
    },

    hubDialogue: {
      tier1: [
        "I made something from whatever was left in the stores. Eat.",
        "The body requires governance. I take that seriously. You all should.",
        "Rest is not indulgence. Rest is maintenance. There's a difference.",
      ],
      tier2: [
        "I found fruit today. Just — growing there, in the stone. " +
        "I stood there for a while before I picked it. I don't know why.",
        "I've been thinking about joy. What it actually is. " +
        "Not the performance of it.",
      ],
      tier3: [
        "Elijah. On the mountain. I found him under a tree, asking to die. " +
        "Not metaphorically. He'd had enough.",
        "An angel brought him food. Said: 'The journey is too great for you.' " +
        "Not: you're weak. Not: get up. Just — here. Eat. " +
        "I've been sitting with that.",
      ],
      tier4: [
        "I ate without counting today. Just ate. And I didn't — " +
        "I didn't go anywhere in my head. I just stayed in it. " +
        "I cried a little. I'm not sure what that was.",
      ],
      tier5: [
        "Joy isn't the absence of hunger. It's being able to feed the hunger " +
        "and still be here afterward.",
        "Muriel. Myrrh. Something sacred and fragrant and offered willingly. " +
        "I think I understand now.",
      ],
    },

    hubGifts: [
      { name: "A feast, from nothing",
        description: "You bring ingredients without a plan and Tobias makes something " +
        "extraordinary. Halfway through making it they go quiet. " +
        "You don't interrupt. They finish. It's the best thing you've eaten. " +
        "They eat very little of it." },
      { name: "A recipe, in someone's handwriting",
        description: "Old. Stained. Tobias holds it like it's a letter. " +
        "Reads it three times. Says: 'They loved someone when they wrote this.'" },
      { name: "A small perfect apple",
        description: "You give it without explanation. " +
        "Tobias holds it for a long time. Doesn't eat it. " +
        "Later you find it on the windowsill where the light comes in." },
    ],

    flavorText: {
      tier1: "Brings warmth into every room and disciplines themselves quietly in the corner.",
      tier2: "The hunger that was supposed to be conquered is the hunger that is still running everything.",
      tier3: "Muriel, whose virtue was joy — forgot that joy is not something to be managed.",
      tier4: "The body is not the enemy. It never was. It was just the part that needed tending.",
      tier5: "Myrrh of God — the sacred fragrance, finally received.",
    },
  },

  // ── 7. LUST → Celibacy ───────────────────────────────────

  seren: {
    id: "seren",
    humanName: "Seren",
    trueName: "Anael",
    trueNameMeaning: "Joy of God — angel of Venus, sacred connection, agape",
    sin: "lust",
    sinLabel: "Lust",
    costume: "Celibacy",
    virtue: "Sacred Love",
    costumeDescription:
      "Seren has consecrated desire to God. The longing is real — Seren doesn't " +
      "pretend otherwise — but it has been given a formal, permanent, " +
      "theologically sanctioned relationship with denial. " +
      "The suppression intensifies it. This is neuroscience. " +
      "The vow doesn't quiet the desire. It gives the desire something to organize around. " +
      "Seren's identity is built on overcoming the thing they never stop wanting.",

    surfacePersonality:
      "Magnetic in a way that unsettles people — not from anything they do " +
      "but from how seen people feel around them. " +
      "The most perceptive character in the party. " +
      "Reads people with frightening accuracy. " +
      "Draws close with perfect precision and — always — " +
      "something goes wrong, not from cruelty, " +
      "but because Seren doesn't yet know the difference between knowing someone and consuming them.",

    wound:
      "Seren has never been loved. They have been wanted — which they fled. " +
      "They have been admired — which they accepted at careful distance. " +
      "But known, fully, without the performance of purity and the drama of resistance? " +
      "Never. The vow that was supposed to protect them from being consumed " +
      "has prevented them from being known. " +
      "And they don't know if there is a self underneath the vow worth knowing.",

    crackEvent:
      "Someone at the hub sees through the performance. " +
      "Doesn't want Seren. Isn't drawn to Seren. " +
      "Just sees them. Asks a question about something Seren actually cares about. " +
      "Not Seren's beauty. Not Seren's mystery. Something Seren mentioned once, quietly, " +
      "and assumed no one heard. " +
      "Seren realizes they have no idea how to be perceived outside the architecture of desire.",

    resolution:
      "Sacred love — agape. The love that knows fully and stays anyway. " +
      "Not the absence of desire but desire in its complete form — " +
      "the wanting to know rather than to have, " +
      "the capacity to be known without using the knowledge as control, " +
      "the freedom of a self that doesn't need the vow because it doesn't need the armor.",

    historicalSoul: "david",
    jobArc: ["archer", "seer", "unbound"],
    startingJob: "archer",

    statLean: { str: 5, def: 4, mag: 8, spd: 9, fth: 7 },

    relationships: {
      aeryn:  { tension: "Seren knows Aeryn completely. Aeryn knows this. " +
                "It is the only relationship where Aeryn doesn't feel the need " +
                "to perform certainty. This is terrifying and Aeryn stays anyway.",
                intimacyRequired: 30 },
      cael:   { tension: "Seren read Cael on day one. Has been waiting for a moment " +
                "to use it that would help rather than harm. " +
                "Still waiting. This is patience that looks like power.",
                intimacyRequired: 28 },
      brennan:{ tension: "Brennan is unreadable to Seren — the only one. " +
                "This is deeply interesting. Seren doesn't know why Brennan " +
                "is opaque and it is the most compelling problem they have encountered.",
                intimacyRequired: 22 },
      solan:  { tension: "Three real conversations. Each went very deep. " +
                "Both retreated. The third one changed something that " +
                "neither has named yet.",
                intimacyRequired: 30 },
      mira:   { tension: "Seren makes Mira feel actually known rather than approved of. " +
                "This is the most important thing Seren has done for anyone " +
                "and they haven't realized it yet.",
                intimacyRequired: 20 },
      tobias: { tension: "Seren makes Tobias feel welcome in their own body. " +
                "Not through desire — through recognition. " +
                "Of all the things Seren has done with their gift, " +
                "this is the purest expression of what it was always supposed to be.",
                intimacyRequired: 25 },
    },

    hubDialogue: {
      tier1: [
        "I see what I see. I don't always say what I see.",
        "Desire is information. I've learned to treat it that way.",
        "The vow is not repression. The vow is consecration. There is a difference.",
      ],
      tier2: [
        "Someone asked me something today and I couldn't answer it. " +
        "Not because I didn't know the answer. Because I didn't know if there was a self " +
        "to give it from.",
        "I keep watching the souls that come through. The ones who loved well. " +
        "Trying to understand what was different about them.",
      ],
      tier3: [
        "The fallen one — Ladriel — it said I have been in a relationship with my longing " +
        "for so long that I've confused it for myself. " +
        "That the celibacy isn't the absence of lust. It's lust in formal wear.",
        "I told it I was going to think about that very carefully. " +
        "It said: 'You always do. That's part of the pattern.'",
      ],
      tier4: [
        "David. He knew what he was doing when he did it. That's the part no one wants to sit with. " +
        "Not that he was blinded by desire. That he saw clearly and chose anyway. " +
        "He's been sitting with that specific fact for a long time.",
        "He said: 'The wanting isn't the sin. The wanting that forgot about the person wanted — that's where it went wrong.'",
      ],
      tier5: [
        "I've been performing being perceived for so long I don't know " +
        "what I look like to someone who isn't watching.",
        "Anael. Joy of God. I think joy requires being known. " +
        "I think I've been afraid of that more than anything.",
      ],
    },

    hubGifts: [
      { name: "A love letter, addressed to no one",
        description: "Unsigned, undated. The most honest piece of writing " +
        "you have ever read. You don't know how you know that. " +
        "Seren reads it once, folds it, doesn't open it again. " +
        "Keeps it." },
      { name: "A veil, half-burned",
        description: "Seren holds it. Puts it down. Says: " +
        "'Someone burned this themselves. I think they were ready.' " +
        "Doesn't explain further." },
      { name: "A record of every person you've met this run",
        description: "You made it. Everyone's name, what you noticed about them. " +
        "Seren reads it slowly, all the way through. Says, at the end: " +
        "'You see people.' Pause. 'Do you see me?'" },
    ],

    flavorText: {
      tier1: "Has given desire a formal address so it doesn't knock on every door.",
      tier2: "The longing and the vow are the same wound wearing different names.",
      tier3: "Anael, whose virtue was the love that knows fully — " +
             "still learning where knowing ends and consuming begins.",
      tier4: "The question isn't whether the self is worth knowing. " +
             "The question is whether the knowing can be survived.",
      tier5: "Joy of God — known, at last, by the self it was always carrying.",
    },
  },
};

// ── Helpers ──────────────────────────────────────────────────

export const PARTY_ORDER = ["aeryn", "cael", "brennan", "solan", "mira", "tobias", "seren"];

export function getCharacter(id) {
  return CHARACTERS[id] ?? null;
}

export function getAllCharacters() {
  return PARTY_ORDER.map(id => CHARACTERS[id]);
}

export function getRelationshipTension(charIdA, charIdB) {
  const char = CHARACTERS[charIdA];
  return char?.relationships?.[charIdB] ?? null;
}

export function getJobArc(charId) {
  return CHARACTERS[charId]?.jobArc ?? [];
}
