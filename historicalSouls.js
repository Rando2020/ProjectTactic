// ============================================================
//  THE APPOINTED: AS ABOVE
//  historicalSouls.js — The souls of scripture, myth, and deep history
// ============================================================
//
//  DESIGN NOTE:
//  These are not bosses. These are not collectibles.
//  They are the most important conversations in the game.
//
//  Each soul is mid-ascent. They've been working through their own
//  trial for longer than the party has been running. They have
//  perspective that only comes from having already paid the full cost
//  of something and having had a very long time to sit with it.
//
//  They are found as "?" encounters in the Mountain — optional,
//  missable, and devastating when found.
//
//  Each soul develops across multiple encounters (multiple runs).
//  Early: still carrying the full weight.
//  Middle: lighter but not finished.
//  Late: something closer to peace.
//  Some will be gone before the game ends. That is its own grace.
// ============================================================

export const HISTORICAL_SOULS = {

  // ── ADAM ─────────────────────────────────────────────────
  adam: {
    id: "adam",
    name: "Adam",
    knownAs: "The First",
    assignedCharacter: null,   // speaks to the whole party
    unlockRequirement: { minRuns: 20, minTier: 3 },
    location: "A garden that is also ruins — both at once, somehow",

    coreTheme:
      "The first choice. The first deflection. The first man to hold something " +
      "in his hands and say: someone else is responsible for this. " +
      "He has had longer than anyone to understand what he did. " +
      "He understands it now. The understanding has not made it smaller.",

    whatHeCarries:
      "Genesis 3:12 — 'The woman you put here with me, she gave me some fruit, and I ate it.' " +
      "He blamed Eve. He blamed God. In the same sentence. " +
      "The first deflection in human history. " +
      "He knows he could have said no. He knows Eve didn't put it in his mouth. " +
      "He knows the question God asked — 'Where are you?' — " +
      "wasn't God not knowing where he was. " +
      "He has been sitting with the gap between what happened and what he said happened " +
      "for longer than civilization.",

    whatHeGives:
      "The understanding that the pattern didn't begin with malice. " +
      "It began with love and a door that love had to leave open. " +
      "A choice that wasn't a trap. A choice that was the gift. " +
      "Free will is the divine image in humanity — the thing that makes them resemble God. " +
      "And free will means the capacity to choose the dark cycle. " +
      "And it also means the capacity to say: I did this. I chose this. I am this. " +
      "And stay standing after.",

    encounters: [
      {
        runRequired: 20,
        state: "early",
        dialogue: [
          "I know what you are. I've been watching this loop since before you remembered you were in it.",
          "Sit. I have something to say and I've been waiting for someone who could hear it.",
          "I blamed her because I was afraid, and I loved her, and I didn't know how to hold both of those at once.",
          "That's all it was. That's what sin is — not the reaching for the fruit. " +
          "The not being able to say: I did this. I chose this. I am this.",
          "[beat]",
          "Every war you've ever fought. Every loop. Every human who ever burned a city " +
          "or broke a family or looked away from someone suffering —",
          "they were all in that garden. And they all said: she gave it to me. He made me. I had no choice.",
          "The pattern God put in place isn't cruelty. " +
          "It's this moment, repeated, until someone learns to say: I did this.",
          "And stays standing after.",
        ],
      },
      {
        runRequired: 30,
        state: "middle",
        dialogue: [
          "You're back. Good.",
          "You're asking me if it was worth it. I'm asking you the same thing. " +
          "You've lived a hundred lives in this world. Was it worth feeling it?",
          "I don't mean the pain. I mean all of it. The hunger, the love, the moment before the choice, " +
          "the grief after. The full weight of being someone specific in a specific moment " +
          "that cannot be undone.",
          "I think God wanted to know if love could survive knowing the cost. " +
          "I think the experiment is still running.",
        ],
      },
      {
        runRequired: 40,
        state: "late",
        dialogue: [
          "I'm nearly done here. I can feel it.",
          "It took me longer than it should have. But it took exactly as long as it took. " +
          "I've had to make peace with that too.",
          "Tell Eve — if you find her — that I understand now. " +
          "That the reaching wasn't the problem. That I've known that for a long time " +
          "and it took me even longer to say it out loud.",
          "[beat]",
          "The garden was always supposed to end. " +
          "Not because God was done with us. Because we were supposed to begin.",
        ],
        departureNote:
          "Adam is gone after this encounter. The garden location has a single apple on the ground, " +
          "unblemished. It does not need to be interacted with. It means what it means.",
      },
    ],
  },

  // ── EVE ──────────────────────────────────────────────────
  eve: {
    id: "eve",
    name: "Eve",
    knownAs: "The First Reach",
    assignedCharacter: null,
    unlockRequirement: { minRuns: 25, adamEncounterComplete: true },
    location: "A different part of the same garden — further in, where it's more overgrown",

    coreTheme:
      "Curiosity. The original impulse to know. To reach toward understanding, " +
      "toward being more than you are, toward what God knows. " +
      "She has been called the source of sin for longer than she can count. " +
      "She has a different view.",

    whatSheCarries:
      "The choice was hers. She knows this. She doesn't carry it as guilt — " +
      "she has worked through guilt and found something underneath it. " +
      "What she carries is: the knowledge that wanting to understand is not wrong. " +
      "That the reach was not disobedience. " +
      "That God knew. That God always knew. And chose to give them the fruit anyway, " +
      "via a path that would look like choice.",

    whatSheGives:
      "The understanding of what God actually wanted. Not obedience. Understanding. " +
      "The apple wasn't a test of whether they would obey — " +
      "it was the beginning of the education. " +
      "She is the one who tells the party, in plain words, what they are here for. " +
      "Not as a revelation. As a conversation.",

    encounters: [
      {
        runRequired: 25,
        state: "early",
        dialogue: [
          "I wondered when someone would come this far in.",
          "Adam told you about the blame. Good. He needed to say that to someone who would understand it.",
          "I'm not angry with him. I was, once. For a very long time. " +
          "Then I understood what fear does to people who love each other.",
          "I reached for the fruit because I wanted to know. " +
          "That's the whole story. I wanted to know what God knows. " +
          "I wanted to understand.",
          "[beat]",
          "I've been told that wanting to understand was the sin. " +
          "I've been sitting with that for a very long time. " +
          "And I think it's wrong. I think it's the most wrong thing anyone has ever said about me.",
        ],
      },
      {
        runRequired: 35,
        state: "middle",
        dialogue: [
          "He didn't punish me for reaching. He made reaching the point.",
          "Everything since — every loop, every war, every person who turns out to be " +
          "something older than they appear — it all grows from that first morning " +
          "when I wanted to know.",
          "I'm not sorry. I don't think He wanted me to be.",
          "[beat]",
          "You are here because you are trying to understand humanity from the inside. " +
          "That was always the assignment. I was the first version of it. " +
          "You are a later one. The method has been refined.",
          "He learns too, I think. That's the part that took me the longest to accept. " +
          "That the creation of something new means encountering something new. " +
          "Even for God.",
        ],
      },
    ],
  },

  // ── CAIN ─────────────────────────────────────────────────
  cain: {
    id: "cain",
    name: "Cain",
    knownAs: "The First Wound",
    assignedCharacter: "cael",
    unlockRequirement: { minRuns: 12, minTier: 2, characterIntimacy: { cael: 30 } },
    location: "A field. Alone. Has been alone here for a long time.",

    coreTheme:
      "The first murder was envy. Not jealousy — Cain didn't want Abel's lamb. " +
      "He wanted God's favor, which he believed he deserved, and didn't receive, " +
      "and couldn't understand why. " +
      "The most ancient question: why does he get what I don't?",

    whatHeCarries:
      "The mark. The exile. The specific weight of being the first person " +
      "to understand what it feels like to take something that cannot be returned. " +
      "He has not excused himself. But he has had a long time to understand " +
      "what was actually underneath the moment, " +
      "and the underneath is not what the simple story suggests.",

    whatHeGives:
      "The understanding that envy is a distorted sense of justice. " +
      "That the question 'why does he get what I don't' is not inherently evil — " +
      "it's the question of fairness, of worth, of whether the universe's ledger " +
      "is being run correctly. It becomes evil when it chooses a direction: " +
      "toward taking rather than toward asking.",

    encounters: [
      {
        runRequired: 12,
        state: "early",
        dialogue: [
          "You've killed hundreds. How many felt like family?",
          "[a long beat — not hostile, just a question waiting for an answer]",
          "I'm not judging you. I'm the last person with standing to judge you. " +
          "I'm asking because it's different when it's family. " +
          "When you've looked at someone you love and found that the love and the resentment " +
          "were in the same room at the same time.",
          "I didn't want his lamb. I wanted to be seen the way he was seen. " +
          "I wanted it more than anything. And I didn't know how to want something " +
          "that badly without it eating everything else.",
        ],
      },
      {
        runRequired: 22,
        state: "middle",
        dialogue: [
          "I've been thinking about what I would have needed. " +
          "Not to not-kill him — though that obviously. " +
          "But before that. What I would have needed at the start.",
          "I think I needed someone to ask me what I wanted. " +
          "Just for myself. Not in comparison to Abel. " +
          "Not in the context of God's favor. " +
          "Just: Cain. What do you want?",
          "[beat]",
          "Do you know what I would have said? I have no idea. " +
          "That's the problem. I didn't know. " +
          "I had never asked.",
          "Go find Cael. Tell them I said: ask the question you keep not asking.",
        ],
      },
    ],
  },

  // ── MOSES ────────────────────────────────────────────────
  moses: {
    id: "moses",
    name: "Moses",
    knownAs: "He Who Struck the Rock",
    assignedCharacter: "brennan",
    unlockRequirement: { minRuns: 15, minTier: 3, characterIntimacy: { brennan: 25 } },
    location: "Near a stone formation on the mountain — he is never far from stone",

    coreTheme:
      "The man who spoke to God face to face. Who parted the sea. Who led a nation " +
      "for forty years through impossible conditions. " +
      "Was barred from the promised land for one moment of wrath — " +
      "striking a rock instead of speaking to it, because he was tired, " +
      "and they were complaining again, and forty years of patience ran out for thirty seconds. " +
      "The most consequential loss of temper in history.",

    whatHeCarries:
      "Not guilt — Moses resolved guilt a long time ago. " +
      "What he carries is the specific, irreducible fact " +
      "that the fire he had used for good for forty years " +
      "expressed itself in the wrong direction for thirty seconds " +
      "and cost him the thing he had worked for longer than most people live. " +
      "He doesn't blame God. He doesn't blame himself beyond what's reasonable. " +
      "He carries the fact.",

    whatHeGives:
      "The understanding that righteous anger is real and necessary and also " +
      "needs to know what it's for. Not as restraint — as purpose. " +
      "The fire that burned forty years in service of something is the same fire " +
      "that struck the rock. The question is not how to put the fire out. " +
      "The question is what the fire knows about itself.",

    encounters: [
      {
        runRequired: 15,
        state: "early",
        dialogue: [
          "I know why you're here. The same reason everyone like you comes to find me.",
          "You want to know if the fire can be managed.",
          "[beat]",
          "Wrong question. The fire doesn't want to be managed. " +
          "It wants to know what it's for.",
          "I led a million people through a desert for forty years. " +
          "The fire is what made that possible. It is also what cost me the land at the end.",
          "I don't regret the fire. I have learned what the fire needs that I didn't give it. " +
          "It needed to know when it was for something and when it was for me. " +
          "I didn't always know the difference.",
        ],
      },
      {
        runRequired: 25,
        state: "middle",
        dialogue: [
          "I've been thinking about the moment. The rock.",
          "They were complaining. Again. For forty years they complained and I bore it " +
          "and I bore it and I bore it. And then I didn't.",
          "The failure wasn't the anger. The failure was that the anger " +
          "had been there for forty years and I had never given it a name. " +
          "I'd been calling it 'patience' — carrying it as virtue — " +
          "while it built pressure in a sealed container.",
          "Name your fire. Give it an honest name. " +
          "Let it know what it is. " +
          "Then you can ask it where it wants to go.",
        ],
      },
      {
        runRequired: 38,
        state: "late",
        dialogue: [
          "I've seen the land, you know. From the mountain. " +
          "God showed me before I came here.",
          "It was enough. More than enough. " +
          "The seeing was the gift, not the arriving.",
          "[beat]",
          "Tell Brennan: the fire is a gift. It will be a gift until the end. " +
          "The work is making sure the fire knows what it loves " +
          "so it doesn't burn what it loves.",
          "Go. I'm nearly done here.",
        ],
      },
    ],
  },

  // ── ELIJAH ───────────────────────────────────────────────
  elijah: {
    id: "elijah",
    name: "Elijah",
    knownAs: "He Who Was Fed",
    assignedCharacter: "tobias",
    unlockRequirement: { minRuns: 10, minTier: 2, characterIntimacy: { tobias: 20 } },
    location: "Under a tree. The only tree in a long stretch of bare stone.",

    coreTheme:
      "The prophet who called fire from heaven, slaughtered false prophets, " +
      "and then collapsed under a tree and asked God to let him die. " +
      "Not metaphorically. He was done. He had done the most dramatic thing " +
      "in prophetic history and he was burned out and he wanted it to be over.",

    whatHeCarries:
      "The specific revelation of what God's response was: not rebuke. Not theology. " +
      "Not an explanation of why he needed to get up and keep going. " +
      "An angel. With food. And water. " +
      "'The journey is too great for you. Eat.' " +
      "God understood that he was tired. God sent nourishment, not instructions. " +
      "God knew the body before the spirit could continue.",

    whatHeGives:
      "The understanding that the body is not the enemy of the spirit. " +
      "The body is what the spirit travels in. " +
      "Rest is not weakness. Food is not indulgence. " +
      "The most holy response to burnout is care. " +
      "Not discipline. Not harder trying. Care.",

    encounters: [
      {
        runRequired: 10,
        state: "early",
        dialogue: [
          "Sit down. You look tired.",
          "I was tired. The most tired I had ever been. And I had done everything right. " +
          "That's the part that made it harder — I had done everything right and I was still finished.",
          "I asked God to take it from me. All of it.",
          "[beat]",
          "God sent breakfast.",
          "Not a revelation. Not a purpose. Not a reason to continue. " +
          "Bread. Water. And: 'The journey is too great for you. Eat.'",
          "I ate. I slept. I ate again. And then I got up.",
          "I have never fully explained to myself why that worked. " +
          "But I think it was because God didn't argue with my exhaustion. " +
          "God honored it.",
        ],
      },
      {
        runRequired: 18,
        state: "middle",
        dialogue: [
          "The discipline you're describing — this one in your party — " +
          "tell me about it more.",
          "[listening]",
          "That's not strength. I know what that looks like from the inside. " +
          "That's the burnt-out prophet trying to earn what has already been given.",
          "The body is not the enemy. It is the place where everything happens. " +
          "Every moment of contact with the divine happens in a body. " +
          "Every moment of love. Every moment of pain. Every moment of choice.",
          "Bread. Water. Sleep. These are not concessions to weakness. " +
          "They are the conditions under which the spirit can continue.",
          "Tell them: the journey is too great for you. Eat.",
        ],
      },
    ],
  },

  // ── DAVID ────────────────────────────────────────────────
  david: {
    id: "david",
    name: "David",
    knownAs: "The Man After God's Heart",
    assignedCharacter: "seren",
    unlockRequirement: { minRuns: 18, minTier: 3, characterIntimacy: { seren: 25 } },
    location: "Not a specific place — he seems to be wherever the Antechamber is least crowded",

    coreTheme:
      "The most beloved king. The man after God's own heart. The one who could kill a giant " +
      "and write psalms and love extravagantly and see someone from his roof and want them " +
      "and use his power to have them and have her husband killed to cover it " +
      "and spend the rest of his life carrying the consequence. " +
      "The most loved person in scripture and one of the most serious failures of self-knowledge.",

    whatHeCarries:
      "The knowledge that he saw clearly. That's the specific weight. " +
      "He wasn't blinded by desire. He saw Bathsheba from his roof and he knew who she was — " +
      "the wife of a loyal soldier — and he wanted her anyway and acted on it anyway. " +
      "The desire wasn't the sin. The desire that forgot about the person being desired: " +
      "that's where it went wrong. He understands this now with perfect clarity " +
      "and the clarity costs him something every time.",

    whatHeGives:
      "The distinction between wanting to know and wanting to have. " +
      "Between desire that honors and desire that consumes. " +
      "He is the person who can tell Seren, from the inside, " +
      "what the difference feels like — and what it cost him not to know the difference when it mattered.",

    encounters: [
      {
        runRequired: 18,
        state: "early",
        dialogue: [
          "I know why you found me and not someone else.",
          "I loved God. Genuinely. More than anything. And I loved people. " +
          "And I destroyed someone because I loved them the wrong way.",
          "The wanting wasn't the sin. The wanting that forgot about the person being wanted — " +
          "that's where it went wrong.",
          "[beat]",
          "I saw her and I thought: I want to know her. " +
          "But by the time I acted, the 'know' had become 'have.' " +
          "I'm not certain when the shift happened. I've been trying to locate it " +
          "for longer than I can measure.",
          "The psalms I wrote after — 'Create in me a clean heart' — " +
          "that's not theater. That's me trying to understand what I actually needed " +
          "and didn't have. A way of loving that could hold the person being loved.",
        ],
      },
      {
        runRequired: 28,
        state: "middle",
        dialogue: [
          "The gift your party member has — the ability to see people — " +
          "it's the most extraordinary thing. I had something like it.",
          "The failure of that gift is when it becomes leverage. " +
          "When seeing someone becomes the basis for a claim on them.",
          "To see someone fully and let that be enough — to know them " +
          "and not need to own the knowing — " +
          "that's the thing I didn't learn in time.",
          "Tell them: the seeing is the gift. The seeing is already everything. " +
          "The rest is fear.",
        ],
      },
    ],
  },

  // ── JOB ──────────────────────────────────────────────────
  job: {
    id: "job",
    name: "Job",
    knownAs: "He Who Held",
    assignedCharacter: null,    // appears to whoever is at their lowest
    unlockRequirement: {
      minRuns: 8,
      triggerCondition: "a_party_member_at_minimum_costume_integrity",
    },
    location: "Found when you're not looking for him — in a quiet corner you haven't been to before",

    coreTheme:
      "Was tested without explanation. Lost everything. Was given theology by his friends " +
      "when what he needed was presence. Held anyway. " +
      "The story doesn't end with Job understanding why. " +
      "It ends with God's voice from the whirlwind, which is not an explanation " +
      "but is something, and Job says: yes. And is restored. " +
      "The not-knowing and the holding-anyway is the whole thing.",

    whatHeCarries:
      "Not bitterness — he resolved that. What he carries is the specific, " +
      "undiluted experience of having been in the dark without being given a reason, " +
      "and choosing presence over absence. " +
      "He cried out. He argued. He demanded an answer. " +
      "The answer he got was a question — 'Where were you when I laid the foundations of the earth?' — " +
      "which is not an answer but is an invitation into scale, " +
      "and in the scale he found something that was enough.",

    whatHeGives:
      "The understanding that not having an answer is not the same as being abandoned. " +
      "That asking loudly is not the same as faithlessness. " +
      "That presence — staying in the conversation even when the conversation is mostly silence — " +
      "is its own kind of answer.",

    encounters: [
      {
        runRequired: 8,
        state: "only_one",
        dialogue: [
          "Sit down. You don't look well.",
          "You've been asking why. I recognize the asking.",
          "I asked why for a long time. Louder and more specifically than you might expect. " +
          "I argued my case. I presented evidence. I demanded an audience.",
          "[beat]",
          "The answer I got was: where were you when the morning stars sang together?",
          "Which is not an answer to the question I asked. " +
          "But it was — it was the thing I needed. " +
          "Not an explanation. A context. " +
          "A sense of the scale of what I was inside.",
          "He never told me why. I stopped needing him to.",
          "[beat]",
          "You will not get a complete answer either. " +
          "I'm telling you now so you don't mistake the not-answering for abandonment. " +
          "Those are different things.",
        ],
      },
    ],
  },
};

// ── Helpers ──────────────────────────────────────────────────

export function getSoulById(id) {
  return HISTORICAL_SOULS[id] ?? null;
}

export function getSoulsForCharacter(charId) {
  return Object.values(HISTORICAL_SOULS).filter(
    s => s.assignedCharacter === charId || s.assignedCharacter === null
  );
}

export function getSoulEncounter(soulId, runCount) {
  const soul = HISTORICAL_SOULS[soulId];
  if (!soul) return null;
  // Return the highest encounter the player qualifies for
  const qualified = soul.encounters.filter(e => e.runRequired <= runCount);
  return qualified[qualified.length - 1] ?? null;
}

export function isSoulAvailable(soulId, gameState) {
  const soul = HISTORICAL_SOULS[soulId];
  if (!soul) return false;
  const req = soul.unlockRequirement;

  if (req.minRuns && gameState.totalRuns < req.minRuns) return false;
  if (req.minTier && gameState.revelationTier < req.minTier) return false;
  if (req.adamEncounterComplete && !gameState.soulEncounters?.adam_late) return false;
  if (req.characterIntimacy) {
    for (const [charId, required] of Object.entries(req.characterIntimacy)) {
      const actual = gameState.relationships?.[charId]?.intimacy ?? 0;
      if (actual < required) return false;
    }
  }
  return true;
}
