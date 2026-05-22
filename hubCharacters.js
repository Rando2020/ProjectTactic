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
//  Sources: Hebrew/Kabbalistic, Roman, Sumerian, Egyptian traditions.
//  All ancient. All recognizable. None borrowed from other games.
// ============================================================

export const HUB_CHARACTERS = {

  // ── AZRAEL ───────────────────────────────────────────────
  azrael: {
    id: "azrael",
    name: "Azrael",
    title: "The Angel of Accompaniment",
    location: "The Dock — east edge of the Antechamber, where the mist comes in",
    tradition: "Hebrew / Islamic",
    appearance:
      "Not what people expect when they hear 'angel of death.' " +
      "Not terrifying — worn. The face of someone who has been present for " +
      "every hard moment anyone has ever had, without exception, " +
      "and has not been broken by it, and doesn't need you to thank him for that. " +
      "Drinking something from a clay vessel he offers to no one.",
    role: "Lore delivery. Dry humor. The party's oldest witness.",
    accessibility: "Available from Run 1. Full depth at Run 10+.",

    personality:
      "Azrael doesn't ferry souls — he accompanies them. There is a difference " +
      "he has had a long time to think about. Under every cosmological regime, " +
      "the function persists: something must be present with the soul at the crossing. " +
      "He was appointed to that before this mountain existed. " +
      "He will be doing it after. He has opinions about the current arrangement. " +
      "He is also, grudgingly, glad the current arrangement is more humane than some previous ones. " +
      "Deeply tired. Deeply funny. The fatigue and the humor are the same thing.",

    theologyNote:
      "In Hebrew tradition, Azrael has half his body in the east and half in the west — " +
      "spanning the whole world, always present at every death simultaneously. " +
      "In this game, he has been spanning the whole mountain since before the party arrived. " +
      "He has seen every loop. He knows the count. He will give it to them " +
      "when they are ready for it.",

    whatHeKnows:
      "Every soul that has arrived. The condition they arrived in. " +
      "How long each boss has been stuck and what they were carrying when they came. " +
      "The number of loops. He won't give it unprompted. " +
      "He's waiting for the right moment, and he'll know it when it comes. " +
      "He also knows what the Seven are — has known since Run 1 — " +
      "and has been watching them figure it out with something between patience and tenderness.",

    dialogueTier1: [
      "You again. Same party, different loop. Most operations have some kind of turnover.",
      "I've been doing this since before this mountain existed. " +
      "Take my professional advice: stop fighting everything and talk to some of it.",
      "You want to know how many times you've been here? No. You don't. Not yet.",
    ],
    dialogueTier2: [
      "You noticed them hesitating. Good. " +
      "The new ones are always the most confused — arrived recently and still think they're somewhere else.",
      "There was a soul last loop. Ordinary man, stone mason. " +
      "Stayed and talked to me for what felt like a month. Then he just — went. " +
      "Sometimes that's how it goes.",
      "I'm not the angel of death, by the way. That's a mistranslation that stuck. " +
      "I'm the angel of accompaniment. There's a difference. " +
      "No one dies alone. That's the whole job.",
    ],
    dialogueTier3: [
      "The Fallen. I remember them from before they fell. " +
      "They were the ones who asked the most questions. Still are, technically.",
      "They're not wrong about everything. I'm not saying join them. " +
      "I'm saying: they're not wrong about everything.",
      "You want to know something? I've been present at every crossing since this began. " +
      "Every soul. Every loop-end. I know what it looks like when one of you is close. " +
      "You're getting there.",
    ],
    dialogueTier4: [
      "You want the number. I can see it. Fine. " +
      "Are you sure? " +
      "[beat] " +
      "Forty-seven loops. You've been here forty-seven times. " +
      "The record is three hundred and twelve. Different group. They got there. " +
      "You're doing better than they were at this stage.",
    ],
    dialogueTier5: [
      "I've been present at a lot of crossings. Most of them don't look the way people expected. " +
      "They look like someone finally putting something down.",
      "When it's time — and it will be time soon — I'll be there. " +
      "That's always been the job. I'm glad it'll be you.",
    ],

    soulKnowledge: {
      canReveal: ["arrival_condition", "stuck_duration", "boss_history"],
      requiresTier: 2,
    },

    gifts: [
      { item: "A coin — old, from a civilization no one names anymore",
        effect: "Unlocks Azrael's count of how many souls the party has helped ascend this run." },
      { item: "A candle that doesn't go out",
        effect: "Azrael holds it a moment before giving it back. " +
        "'I light one of these for everyone. Consider this yours.' Unlocks deeper dialogue." },
    ],
  },

  // ── LILITH ───────────────────────────────────────────────
  lilith: {
    id: "lilith",
    name: "Lilith",
    title: "The Unbound — She Who Left",
    location: "The threshold between the Antechamber and the Mountain. The dark corners. She is never where you look directly.",
    tradition: "Hebrew / Kabbalistic (apocryphal)",
    appearance:
      "Neither the demon of folklore nor the saint of revisionism. Both and neither. " +
      "Something that has been outside every system long enough to stop needing one. " +
      "Moves through the Antechamber like she owns it, which in some sense predates anyone else's claim. " +
      "Tends to the dark the way Persephone — the old name for Ereshkigal — tends the garden. " +
      "Won't explain herself until you've earned it.",
    role: "The third path. Neither angel nor fallen. The one who escaped the loop — or found its edge.",
    accessibility: "Present from Run 1. Visible. Unapproachable until Tier 3. Full depth at Tier 4.",

    personality:
      "The original myth: she was the first, made equal, refused to be subordinate, left. " +
      "Was demonized for the leaving. Has been outside every system since. " +
      "In this game, that makes her the only being in the Antechamber " +
      "who is not part of the mountain's architecture — " +
      "not administering it, not stuck in it, not ascending through it. " +
      "She found a third thing. She is not going to hand it to anyone. " +
      "But she will, eventually, point toward it.",

    whatSheKnows:
      "What exists outside the loop — she has been there. " +
      "The original design of the assignment and what it cost. " +
      "The Fallen angels, whom she predates. " +
      "What the Seven actually are, which she has known since before they arrived. " +
      "She will not say any of this directly. " +
      "She will say things that land three runs later when something else makes them make sense.",

    dialogueTier1: [
      "[She is in the corner. She looks at you once. Looks away. " +
      "There is no hostility in it. She is just — elsewhere.]",
    ],
    dialogueTier2: [
      "You keep coming back. That's the design, yes. " +
      "Most of them don't notice they're designed. Points to you.",
      "The dark corners of this place — they're mine, by prior claim. " +
      "Just so you know whose space you're in when you come looking for quiet.",
    ],
    dialogueTier3: [
      "The Fallen think leaving is freedom. It isn't. " +
      "I left. What you find outside the system is just — outside the system. " +
      "It's not better. It's just different cold.",
      "The loop is real. The loop is also not the only thing that's real. " +
      "I know you can't use that yet. File it.",
    ],
    dialogueTier4: [
      "You're asking the right question finally. Not 'how do we finish' — " +
      "'what are we finishing toward.' " +
      "Those are not the same question and only one of them has an answer worth having.",
      "I left because I could not be one thing. " +
      "You were assigned to be one thing and it broke you open into everything. " +
      "Different routes. Same discovery.",
    ],
    dialogueTier5: [
      "I've been watching you find your way to the edge of what you were assigned to be. " +
      "That's where I am. That's where the third thing is.",
      "I won't tell you what's past the threshold. " +
      "I will tell you: I don't regret the leaving. " +
      "I don't think you'll regret the staying.",
    ],

    gifts: [
      { item: "Nothing — she takes something instead",
        description: "She reaches out and takes a small object from your pocket " +
        "without explaining why. You don't feel robbed. You feel — lighter. " +
        "The object was something you'd been carrying without realizing it." },
      { item: "A feather — dark, from no bird you know",
        description: "She gives this at Tier 4, without ceremony. " +
        "'You'll know what it's for when you need it.' She's right." },
    ],
  },

  // ── AURORA ───────────────────────────────────────────────
  aurora: {
    id: "aurora",
    name: "Aurora",
    title: "Dawn — the first light after",
    location: "The threshold to the Mountain — appears at what passes for morning",
    tradition: "Roman",
    appearance:
      "Young in the way mornings are young — not naive, but clean. " +
      "Light that has not yet accumulated the day's weight. " +
      "Something white that is not quite cloth. " +
      "Gone before you can look directly at her. " +
      "The name itself is the thing: everyone already knows what it means.",
    role: "The breakthrough moment. Appears after crack events. Never stays.",
    accessibility: "Triggered by crack events. Cannot be held. Cannot be sought.",

    personality:
      "Roman Aurora was the goddess who renewed herself every morning, " +
      "opening the gates of heaven for the sun. " +
      "In this game she is the moment of renewal itself — " +
      "not the sustained work, not the long excavation, " +
      "but the specific instant when the work yields something. " +
      "She marks that moment and is gone. " +
      "Whether she causes it or witnesses it is left to the player.",

    whatSheKnows: "The moment. Just the moment. That is sufficient.",

    dialogueTier1: [
      "[She is at the threshold at the start of each run. She does not speak. " +
      "She looks at you once. The run begins.]",
    ],
    dialogueTier2: [
      "Something moved in you just now. I saw it.",
      "[gone]",
    ],
    dialogueTier3: [
      "The crack is not damage. The crack is how it opens.",
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

  // ── ERESHKIGAL ───────────────────────────────────────────
  ereshkigal: {
    id: "ereshkigal",
    name: "Ereshkigal",
    title: "Queen of the Great Below — She Who Remained",
    location: "A courtyard in the Antechamber — tending something. A garden that shouldn't grow here, but does.",
    tradition: "Sumerian",
    appearance:
      "The oldest queen of the dead in recorded human history — " +
      "older than the Egyptian system, older than the Greek. " +
      "Has the bearing of someone who has ruled something genuinely difficult " +
      "for a very long time and has earned every line of it. " +
      "Tending the garden without ceremony. " +
      "Will look up and talk if you come to her.",
    role: "The most genuine ally the party has. Understands their position better than anyone.",
    accessibility: "Available from Run 1. Opens fully over repeated conversations.",

    personality:
      "In the Sumerian myth, Ereshkigal rules the underworld — not by choice initially, " +
      "but by assignment. She was taken there. She remained. She made it hers. " +
      "The myth of Inanna's descent to the underworld is, among other things, " +
      "about Ereshkigal's grief — she is found crying for the men who die young, " +
      "for the women who are abandoned. She feels everything. She just does it from the deep. " +
      "That quality — full presence inside a hard assignment — " +
      "is exactly what the Seven are working toward. She recognizes the project.",

    whatSheKnows:
      "What it means to be assigned somewhere you didn't choose and find meaning in it anyway. " +
      "The difference between resignation and acceptance — which is enormous. " +
      "The old system and what preceded the mountain. " +
      "How to tend things that shouldn't grow in inhospitable places. " +
      "Azrael, Osiris, Lilith — all the others — from long familiarity.",

    dialogueTier1: [
      "You look confused about where you are. Most new ones do. " +
      "You'll stop expecting it to make sense and start expecting it to mean something. " +
      "Those are different things.",
      "The garden shouldn't grow here. It does anyway. I stopped questioning it.",
      "I've been tending this place since before most of what you'd call history. " +
      "Sit down. You look like you need a moment.",
    ],
    dialogueTier2: [
      "You've been here before, you know. I recognize the shape of how you move. " +
      "Sit down. I'll tell you what I've noticed.",
      "The ones who get stuck aren't weaker than the ones who go through. " +
      "They're usually the ones who got close to the truth and got frightened by it.",
      "In my oldest stories, a goddess came down to my realm to challenge me. " +
      "She was stripped of everything at every gate. " +
      "Arrived with nothing. " +
      "The stripping wasn't punishment. It was the condition of entry. " +
      "You understand that better than most.",
    ],
    dialogueTier3: [
      "The Fallen came to me once. Offered me a place in their project. " +
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
      "I chose to stay in the end, you know. After a long time of it feeling like I had no choice. " +
      "The day I understood I could leave — and stayed — " +
      "was the day the place became something I was tending rather than trapped in.",
    ],
    dialogueTier5: [
      "You're ready. I can tell because you stopped trying to leave.",
      "When you go — come back and tell me what it looks like from there. " +
      "I've always wondered.",
    ],

    gifts: [
      { item: "Something from the garden — a flower from the wrong climate entirely",
        effect: "Given to a party member. Opens a specific dialogue about belonging." },
      { item: "Seeds, labeled in a script no one reads anymore",
        description: "'For wherever you end up.' She says nothing else." },
    ],
  },

  // ── SOMNUS ───────────────────────────────────────────────
  somnus: {
    id: "somnus",
    name: "Somnus",
    title: "Sleep — the space between",
    location: "Found in the Antechamber at what passes for night — often asleep himself, until he isn't",
    tradition: "Roman",
    appearance:
      "Soft. Unhurried. Wearing something impractical and comfortable. " +
      "Often half-present even while speaking — the quality of someone " +
      "who exists in the liminal space between states professionally " +
      "and has stopped apologizing for it. " +
      "His name is the root of somnambulant, insomnia, somnolent — " +
      "players feel they already know him before he speaks.",
    role: "Dream keeper. Between-loop witness. Holds what happens when the party isn't running.",
    accessibility: "Available after Run 5. Opens significantly at Tier 2.",

    personality:
      "Roman Somnus was the god of sleep, twin to Mors (death), " +
      "both sons of Nox (Night). He governed the unconscious — " +
      "the place between one day and the next, " +
      "between one loop and the next in this game. " +
      "He has been watching the Seven's dreams since before they knew they were dreaming. " +
      "He has observations. He has been waiting for the right one to ask. " +
      "He treats all dreams with the same gentle clinical interest. " +
      "Especially the distressing ones.",

    whatHeKnows:
      "What happens to the Seven between runs. Where they go. What they dream. " +
      "What their unconscious is working on without their knowledge. " +
      "The dream content for each character — specific, precise, " +
      "revealing in ways that the waking characters haven't accessed. " +
      "He shares these carefully. Only when the character is ready.",

    dialogueTier1: [
      "Oh. You're awake. Good. That's usually the first step.",
      "You've been dreaming of a light you can't name. Most of you have. " +
      "I find that interesting.",
    ],
    dialogueTier2: [
      "You want to know what you dream about between runs. " +
      "That's the first time any of you have asked directly. " +
      "Give me a moment to decide how much to tell you.",
    ],
    dreamRevealsByCharacter: {
      aeryn:
        "You dream of being wrong about something important. Every time. " +
        "And in the dream, being wrong doesn't end you. " +
        "You keep being surprised by this.",
      cael:
        "You dream of being asked what you want. And answering. " +
        "You never remember what you said when you wake up.",
      brennan:
        "You dream of a moment before the fire. " +
        "There is always a moment before the fire. " +
        "You've been trying to stay in that moment longer each time.",
      solan:
        "You dream of being called back to something. " +
        "You keep going the wrong direction on purpose. " +
        "You know you're doing it. This is important.",
      mira:
        "You dream of giving something away — not from abundance, " +
        "from the last of what you have. " +
        "And then you dream of what comes after, which is not what you expected.",
      tobias:
        "You dream of a meal you've never had. " +
        "You are entirely in it. When you wake up you can't remember what it tasted like " +
        "but you can remember what it felt like to be there.",
      seren:
        "You dream of being seen. Just seen. Not desired, not admired. Just met. " +
        "You always cry in this dream. You never know why when you wake up.",
    },
    dialogueTier3: [
      "The Fallen don't dream. They made a choice that took dreaming away from them. " +
      "I'm not sure they realize what that cost.",
    ],
    dialogueTier5: [
      "The dream you're having now is different from the one you were having at the start. " +
      "I keep records. Would you like to know how they've changed? " +
      "It's rather beautiful, actually.",
    ],
  },

  // ── OSIRIS ───────────────────────────────────────────────
  osiris: {
    id: "osiris",
    name: "Osiris",
    title: "The Displaced Judge",
    location: "An old office in the Antechamber that nobody else uses — stone desk, ancient scales, something still running in the background",
    tradition: "Egyptian",
    appearance:
      "Green-skinned in the traditional depiction — not sickly, verdant. " +
      "Something about him suggests things that died and came back changed. " +
      "Formal in the way that people who ran something large and just for a very long time " +
      "stay formal after circumstances shift. " +
      "The scales on his desk are not decorative. He still uses them.",
    role: "The institutional perspective. Critic and, eventually, unexpected ally.",
    accessibility: "Run 10+, introduced by Ereshkigal.",

    personality:
      "In Egyptian mythology, Osiris was killed by his brother Set, resurrected by his wife Isis, " +
      "and became the judge of the dead — weighing each heart against the feather of Ma'at (truth). " +
      "He was displaced when the current system superseded his. " +
      "He was not evil — he was just. Ran the old order with precision. " +
      "Watched it get replaced by something messier, more chaotic, " +
      "and — if he is honest with himself, and he has had a long time to be honest — " +
      "more complete. " +
      "The weighing of hearts was good work. " +
      "This mountain does something the weighing couldn't do: it transforms.",

    whatHeKnows:
      "The old system — how it worked, why it worked, what it couldn't do. " +
      "Every soul that arrived under his regime and how they were adjudicated. " +
      "The Fallen, whom he remembers from before the transition. " +
      "Death and resurrection from the inside — he has done it personally. " +
      "This gives him a specific insight into what the loop is actually doing " +
      "that even Azrael doesn't have.",

    dialogueTier1: [
      "You don't know where you are and you move with confidence anyway. " +
      "That's either courage or foolishness. " +
      "In my experience the difference only emerges in retrospect.",
      "The old system had problems. The new system has different problems. " +
      "Calling this progress requires a specific definition of progress.",
    ],
    dialogueTier2: [
      "I spent my tenure weighing hearts. Every heart, against the feather of truth. " +
      "Simple. Clean. Just. " +
      "What I could not do was change what was in the heart before the weighing. " +
      "This mountain does that. I have watched it do that. " +
      "I am not yet certain whether I find it more elegant or more presumptuous.",
    ],
    dialogueTier3: [
      "The Fallen were processed through my system before they fell. " +
      "I have their records. They all weighed clean. " +
      "They fell after. That's the thing about the old system: " +
      "it measured what was. It couldn't account for what would become.",
      "I died, you know. Was murdered. Was resurrected. Became something different than I was. " +
      "I understand what you're going through more directly than my manner suggests.",
    ],
    dialogueTier4: [
      "I spent a long time resenting the replacement of my work. " +
      "I've arrived at a different position. " +
      "The weighing was justice. This mountain is trying to be mercy. " +
      "I'm not certain that's possible at scale. " +
      "I'm less certain it's impossible than I used to be.",
    ],
    dialogueTier5: [
      "I'll tell you something. Off my formal record. " +
      "I've watched dozens of parties complete this. " +
      "Every single one of them passed through this antechamber at the end. " +
      "Not one of them looked the way they expected to look when they made it. " +
      "They looked lighter. That's all. Just lighter. " +
      "I didn't design that. I still find it interesting every time.",
    ],
  },

  // ── ANAMNESIS ────────────────────────────────────────────
  anamnesis: {
    id: "anamnesis",
    name: "Anamnesis",
    title: "The Holy Remembering — the pool of return",
    location: "The deepest part of the Antechamber — past the rooms everyone uses, past the quiet, past the dark",
    tradition: "Greek Theological / Catholic Liturgical",
    appearance:
      "You are not entirely sure she has a form. " +
      "There is a presence near the water. " +
      "The water is impossibly clear and impossibly still " +
      "and looking into it is not entirely comfortable. " +
      "She is the pool and the presence beside it " +
      "and the quality of attention you feel when you stand near still water " +
      "and something looks back.",
    role: "Late-game memory return. The mechanism of true names. Not a quest — an arrival.",
    accessibility: "Location accessible from Tier 2. Responsive from Tier 3. Full function at Tier 4.",

    theologyNote:
      "'Anamnesis' — from the Greek, meaning the opposite of amnesia. " +
      "In Catholic and Orthodox liturgy, it is the moment in the Eucharist " +
      "when the past event (the Last Supper) is made present and real again. " +
      "Not memory of a thing. The thing itself, returned. " +
      "This is what she does. She doesn't unlock what was hidden. " +
      "She returns what was always yours.",

    personality:
      "Does not push. Does not beckon. Does not teach. " +
      "Holds what was always yours and gives it back when you are ready. " +
      "The readiness is not something she judges — she simply knows it. " +
      "Coming to the pool before you're ready gives you nothing. " +
      "Not because she withholds — because there is nothing yet to give back. " +
      "The memory isn't locked behind her. It's locked behind the work.",

    dialogueTier2: [
      "[The pool is still. Nothing happens. " +
      "But you feel, standing here, that something knows you are standing here.]",
    ],
    dialogueTier3: [
      "[Something surfaces in the water — not an image. A feeling. " +
      "The feeling of being someone specific, in a moment before this one, " +
      "making a choice you said yes to. " +
      "The feeling fades before you can hold it.]",
    ],
    dialogueTier4_fragments: {
      aeryn:
        "You are standing in light so complete it has no source. " +
        "You are asked if you will carry it. You say yes.",
      cael:
        "You are given a set of scales. You hold them perfectly steady. " +
        "You have never held anything this carefully. You say yes.",
      brennan:
        "You are shown something unjust. The fire rises in you — clean and clear. " +
        "It does not destroy the one who shows you. You say yes.",
      solan:
        "You are given every mystery. All at once. " +
        "You are asked if you can hold it without it becoming a weight. You say yes.",
      mira:
        "You are given a world and told: there is enough. Care for what is here. " +
        "You look at it and believe it. You say yes.",
      tobias:
        "You are given the capacity for joy. Complete, unguarded. " +
        "You are told: this is what existence is supposed to feel like. You say yes.",
      seren:
        "You are given the ability to love without consuming. " +
        "To know fully and hold gently. " +
        "You are shown what this looks like and it is the most beautiful thing you have seen. " +
        "You say yes.",
    },
    dialogueTier5: [
      "[The pool shows you your own face. Not the one you're wearing. The other one. " +
      "You recognize it.]",
    ],
  },

  // ── CASIMIR (THE ARCHIVIST) ───────────────────────────────
  archivist: {
    id: "archivist",
    name: "Casimir",
    title: "The Archivist",
    location: "A library corner of the Antechamber — books, maps, and an oil lamp that never goes out",
    tradition: "Original — fully human",
    appearance:
      "Old in a purely human way. Ink stains. Reading glasses. " +
      "More records than anyone asked him to keep. " +
      "Warm — genuinely, simply warm in a way that makes the Antechamber feel livable. " +
      "The only person here who is entirely and unambiguously human. " +
      "This is the most important thing about him.",
    role: "Lore delivery without exposition. The human heart of the hub. Will know before anyone tells him.",
    accessibility: "Available from Run 1. Always has something new.",

    personality:
      "Has been recording 'the pattern' for decades without knowing what he's documenting. " +
      "He maps historical cycles — the rise and fall of civilizations, " +
      "the repetition of certain conflicts, the recurring human responses to recurring conditions. " +
      "He doesn't know he's been mapping every loop. " +
      "He has gotten dangerously close to the truth through pure scholarship. " +
      "He is the character who will know before anyone tells him. " +
      "Players will watch him get there and it will be one of the best things in the game.",

    whatHeKnows:
      "Everything about historical cycles from a scholarly perspective. " +
      "The specific historical souls the party is encountering — " +
      "he has documents about their lives, though he doesn't know they're literally upstairs. " +
      "He will know everything eventually. " +
      "What the party does with that is up to them.",

    dialogueTier1: [
      "You look like you've been somewhere interesting. Sit down. Tell me what you saw.",
      "I've been charting the pattern for thirty years. " +
      "Every hundred years, the same conflicts. Different names. Same shape. " +
      "I used to think it was coincidence.",
      "Here — I found a reference to this region in a text from eight hundred years ago. " +
      "The geography is identical. The parties involved are different. The events are not.",
    ],
    dialogueTier2: [
      "I've been having a very strange feeling lately. " +
      "That I've done this work before. Not just studied history — " +
      "that I specifically have studied these specific patterns before. " +
      "I don't know what to do with that.",
      "I found a reference to something called 'The Appointed' in a medieval text. " +
      "Seven figures. Sent to walk with humanity. " +
      "I've been trying to find more references. There aren't many. " +
      "It's like someone removed them.",
    ],
    dialogueTier3: [
      "I have to ask you something and I need you to answer honestly. " +
      "Have you been to this mountain before? " +
      "Not in memory. In fact. " +
      "Because if you have, there are things in my records I need to show you.",
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
      "it's all one thing, isn't it. " +
      "It's one very long sentence that humanity keeps starting over " +
      "because they keep losing the beginning.",
      "Go finish it. I'll keep the records.",
    ],

    gifts: [
      { item: "A map of the mountain, partial and wrong in interesting ways",
        description: "He gives this in good faith. Some of it is more accurate than he knows." },
      { item: "A record of a historical figure the party has met",
        description: "He has no idea the party knows this person personally. " +
        "The record is accurate and touches things the party hasn't asked about yet." },
      { item: "His thirty years of pattern work, compiled",
        description: "'Use it. It was always for someone other than me.'" },
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

export const HUB_CHARACTER_AVAILABILITY = {
  azrael:     { availableFromRun: 1,  requiresIntroduction: false },
  ereshkigal: { availableFromRun: 1,  requiresIntroduction: false },
  archivist:  { availableFromRun: 1,  requiresIntroduction: false },
  somnus:     { availableFromRun: 5,  requiresIntroduction: false },
  lilith:     { availableFromRun: 1,  requiresIntroduction: false, approachableTier: 3 },
  aurora:     { availableFromRun: 1,  requiresIntroduction: false, triggeredByCrackEvents: true },
  osiris:     { availableFromRun: 10, requiresIntroduction: true, introducedBy: "ereshkigal" },
  anamnesis:  { availableFromRun: 1,  requiresIntroduction: false, functionsTier: 3 },
};

// Map old Greek names to new names — for any existing save migration needed
export const HUB_CHARACTER_NAME_MAP = {
  charon:     "azrael",
  nyx:        "lilith",
  hemera:     "aurora",
  persephone: "ereshkigal",
  hypnos:     "somnus",
  hades:      "osiris",
  mnemosyne:  "anamnesis",
};
