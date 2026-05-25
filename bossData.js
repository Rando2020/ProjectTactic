// ============================================================
//  THE APPOINTED: AS ABOVE
//  bossData.js — The ancient ones. Stuck souls with philosophies.
// ============================================================
//
//  DESIGN NOTE:
//  Bosses are not evil. They are souls who arrived on the mountain,
//  looked at what was being asked of them, and built a fortress
//  out of refusing it.
//
//  They have been here long enough to have theology.
//  Their theology is wrong in specific ways that the game
//  never completely dismisses.
//
//  The hardest mechanic: every boss, across enough loops,
//  can eventually be talked to. The fortress has cracks.
//  You just have to find them with the right character,
//  having done the right work on yourself first.
//
//  Because that is the rule of the mountain:
//  you can only reach people as far as you've gone yourself.
// ============================================================

export const BOSSES = {

  // ── THE RIGHTEOUS ONE ─────────────────────────────────────
  // The Pride boss. Aeryn's mirror at full power.

  the_righteous_one: {
    id: "the_righteous_one",
    name: "???",                        // Name hidden until loop 3+
    nameRevealed: "Sabriel",
    title: "The Righteous One",
    tier: "mountain_mid",
    sinMirrored: "pride",
    characterMirror: "aeryn",

    appearance:
      "Immaculate. The armor is unmarked. The bearing is absolute. " +
      "Moves with the total certainty of someone who has never been surprised " +
      "by the consequences of their choices because they do not track consequences " +
      "separately from intent. If the intent was righteous, the consequence was righteous. " +
      "Has been on the mountain long enough that the armor has become structural. " +
      "There is nothing underneath it that remembers being soft.",

    philosophy:
      "The mountain is a lie. 'Refinement' is the word the system uses " +
      "for breaking people who were working correctly. " +
      "Every soul that passes through is diminished — made uncertain, made humble, " +
      "stripped of the conviction that allowed them to act. " +
      "An uncertain person cannot do good. Conviction is not pride. " +
      "Conviction is the condition under which righteousness is possible. " +
      "The mountain wants to destroy righteousness and call it healing.",

    whyTheyreWrong:
      "Sabriel has conflated certainty with righteousness so completely " +
      "that they cannot distinguish between the two. " +
      "The people they have hurt — and they have hurt people, " +
      "significantly, with complete inner peace — exist in their accounting " +
      "as acceptable cost. The theology absorbed the consequence before it could land. " +
      "The game never shows Sabriel as a hypocrite. They are sincere. " +
      "That is the point.",

    whyTheyreNotCompletelyWrong:
      "Uncertain people can fail to act. Paralysis has a cost. " +
      "The world does contain wrong things that require conviction to fight. " +
      "Sabriel is correct about this. " +
      "The argument the party must make — and eventually does make — " +
      "is that conviction and certainty are different things. " +
      "You can act from the former without requiring the latter. " +
      "This is a hard argument to make because it requires demonstrating it in yourself first.",

    loopDialogue: {
      loop1: "You fight well. You will need to fight better.",
      loop2: "You again. Same party. Different arrangement. Does it feel like progress?",
      loop3: "I've been watching you. You're close to something. I suggest you stop before you reach it.",
      loop5: "You've been coming back. That means something. I don't know what yet. Neither do you.",
      loop7: "Tell me — you, specifically — " +
             "do you ever wonder if the thing you're fighting for is worth the shape it's making you?",
      loop10: "[Sabriel lowers their weapon slightly — not in surrender, in recognition] " +
              "You're asking the same questions I stopped asking. " +
              "I stopped because the questions were going to cost me something I wasn't willing to pay. " +
              "Are you?",
    },

    // Conditions for the talk-through path
    talkPath: {
      requiresCharacter: "aeryn",
      requiresCostumeIntegrity: { aeryn: 40 }, // Aeryn's armor must be partially cracked
      requiresRuns: 10,
      requiresHubDialogue: ["aeryn_tier3_complete"],
      dialogue: [
        "Aeryn: [no weapon drawn] I'm not here to fight today.",
        "Sabriel: [pause] ...That's new.",
        "Aeryn: I met someone on the mountain. A soul. Completely certain, " +
        "completely peaceful, completely wrong about everything that mattered. " +
        "And from the outside we were identical.",
        "Sabriel: ...",
        "Aeryn: I'm not saying you're wrong. I'm saying I can't tell the difference " +
        "from the outside anymore, and I used to be able to, and I need to know " +
        "how you tell.",
        "Sabriel: [very long pause] " +
        "I stopped asking that question because I couldn't answer it. " +
        "...I have been on this mountain for a very long time.",
        "[Sabriel sits. For the first time in their tenure on the mountain, Sabriel sits.]",
        "Sabriel: I don't know how to tell the difference. " +
        "I don't know if I've been fighting for God or for my own certainty about God. " +
        "I haven't let myself know that for — " +
        "[they look at their hands] — for a very long time.",
        "Aeryn: [quietly] Neither have I.",
        "[The fortress doesn't fall. But a window opens. The fight ends without a fight. " +
        "The party earns the highest clarity bonus in the game. " +
        "Sabriel is still on the mountain next loop. But different. Changed.]",
      ],
    },

    combatNotes:
      "Fights with divine certainty — every attack is precise, committed, unapologetic. " +
      "The difficulty is that the righteousness makes the attacks feel wrong to dodge. " +
      "You feel like you're supposed to take them. That feeling is the mechanic. " +
      "Players who notice it and resist it are making the same move Aeryn is making.",
  },

  // ── THE ARCHIVIST-BOSS ───────────────────────────────────
  // The Sloth boss. Solan's mirror.

  the_keeper: {
    id: "the_keeper",
    name: "???",
    nameRevealed: "Vashiel",
    title: "The Keeper of Records",
    tier: "mountain_early",
    sinMirrored: "sloth",
    characterMirror: "solan",

    appearance:
      "Surrounded by documents that float without wind. Everything recorded. " +
      "Nothing acted on. A being so dedicated to understanding that action has become " +
      "a kind of violence against the purity of observation. " +
      "Old in a way that suggests age chosen rather than age suffered.",

    philosophy:
      "Action is premature judgment. The soul that acts without complete understanding " +
      "does harm — history proves this at every scale. " +
      "The only ethical position is to observe, record, and understand completely " +
      "before intervening. The mountain's insistence on moving souls forward is a violence " +
      "dressed as grace. Some souls need more time. Most souls need more time. " +
      "Vashiel has been here for millennia and is still not certain they understand enough " +
      "to act. This is not paralysis. This is rigor.",

    whyTheyreWrong:
      "Vashiel has perfect records of every soul that arrived on the mountain. " +
      "Perfect records, perfectly maintained, perfectly useless. " +
      "The souls they were 'watching' without intervening have become the Type 2 encounters " +
      "the party keeps running into — people who could have been helped " +
      "and instead calcified because no one was willing to be present for them " +
      "in the specific moment when presence was what mattered.",

    loopDialogue: {
      loop1: "Ah. The Appointed again. Your approach is unchanged. Your results should therefore be predictable.",
      loop3: "You've been here [exact loop count] times. I have the records. " +
             "You've made [calculated] progress. That's [precise percentage] of the necessary understanding. " +
             "You are not ready.",
      loop5: "I know everything about you. Every choice. Every failure. Every improvement. " +
             "I have never spoken to you about any of it because you weren't ready to hear it. " +
             "I'm still not certain you are.",
      loop8: "There is a soul two levels up that you have walked past seventeen times. " +
             "I've been watching it calcify. I have notes. " +
             "...I've been waiting for the correct moment to intervene. " +
             "[a very long pause] I'm not certain the correct moment was not seventeen loops ago.",
      loop12: "[Vashiel holds a specific record out to the party] " +
              "I've been keeping this for you. For the correct moment. " +
              "I'm beginning to question whether my standard for 'correct' has been functional.",
    },

    talkPath: {
      requiresCharacter: "solan",
      requiresCostumeIntegrity: { solan: 35 },
      requiresRuns: 8,
      dialogue: [
        "Solan: I know what you have. I know what you've been waiting for. " +
        "I've been doing the same thing.",
        "Vashiel: ...",
        "Solan: The soul on level three. The one you've been watching. " +
        "I walked past it six times last run. Each time I catalogued what I saw " +
        "and kept moving.",
        "Vashiel: Your observation was correct. The timing was —",
        "Solan: The timing was that a soul needed someone present and I was " +
        "deciding whether I was prepared enough to be present. " +
        "I wasn't. I know I wasn't. The preparation was the avoidance.",
        "Vashiel: [very quietly] Yes.",
        "Solan: You have records of everything that happens here. " +
        "And nothing has changed because of the records.",
        "Vashiel: ...I have seventeen documented instances where my presence " +
        "would likely have — [stops] [longer stop] " +
        "I have been afraid of being wrong. I have called it rigor.",
        "[Vashiel sets the records down. For the first time in millennia, " +
        "Vashiel sets the records down.]",
      ],
    },

    combatNotes:
      "Fights at a remove. Uses knowledge of the party's past actions against them. " +
      "Predicts movement. The feel is: being fought by someone who has studied you " +
      "but never been present with you. The technical difficulty is high. " +
      "The emotional difficulty is the creeping recognition.",
  },

  // ── THE DEVOTED ──────────────────────────────────────────
  // The Gluttony boss. Tobias's mirror. The most unsettling fight.

  the_devoted: {
    id: "the_devoted",
    name: "???",
    nameRevealed: "Celestiel",
    title: "The Devoted",
    tier: "mountain_mid",
    sinMirrored: "gluttony",
    characterMirror: "tobias",

    appearance:
      "Thin in a way that has been chosen and maintained. " +
      "Genuinely radiant — the discipline has produced something that looks like health " +
      "from a distance and something else from close up. " +
      "Every movement deliberate. A quality of self-governance that extends to the air around them. " +
      "Gentle. Profoundly gentle.",

    philosophy:
      "The body is the last obstacle. Every saint understood this. " +
      "The flesh pulls toward appetite — toward the comfortable, the easy, the sufficient. " +
      "The spirit requires the opposite of sufficient. It requires the stripped-down, " +
      "the clarified, the refined. " +
      "The mountain's offer of 'joy' is a trap dressed as grace — " +
      "another form of appetite, wearing better clothes. " +
      "True ascent requires the annihilation of the body's claims on the soul. " +
      "Celestiel has been working on this for longer than the mountain has been running " +
      "and they are very close.",

    whyTheyreWrong:
      "Celestiel is not close. " +
      "The discipline that was supposed to free them from the body " +
      "has made them the most body-obsessed being on the mountain. " +
      "Every thought is about the body — what it is consuming, what it is refusing, " +
      "what it is becoming. The flesh that was supposed to stop mattering " +
      "has never mattered more. " +
      "They have consumed themselves. The compulsion did not end. It inverted.",

    whyTheyreNotCompletelyWrong:
      "The body can obstruct. Appetite, unchecked, is real. " +
      "The tradition of fasting and discipline is ancient and has produced genuine spiritual depth. " +
      "Celestiel is not wrong that the body is part of the work. " +
      "They are wrong that the body is the enemy. " +
      "The game makes this distinction visible through Tobias's arc.",

    loopDialogue: {
      loop1: "You carry your bodies like weights. That's the first problem.",
      loop2: "I've watched you eat between runs. You eat quickly. Without attention. " +
             "The body's demands are constant because you keep answering them. " +
             "They stop demanding when you stop answering.",
      loop4: "You look tired. [genuinely] The fatigue is the body asserting itself. " +
             "You are learning to set it aside. You're not there yet. That's alright. " +
             "The refinement takes time.",
      loop7: "Your healer — the warm one — they brought food to someone today. " +
             "Did you notice? Not because they were hungry. " +
             "Just — because they could. That's the appetite in its most subtle form. " +
             "The need to give what the body wants.",
      loop10: "I think about food constantly. " +
              "[a pause in which Celestiel appears to have surprised themselves] " +
              "I said that out loud. I haven't — I don't usually say that out loud.",
    },

    talkPath: {
      requiresCharacter: "tobias",
      requiresCostumeIntegrity: { tobias: 30 },
      requiresRuns: 8,
      requiresHubDialogue: ["tobias_crack_event_complete"],
      dialogue: [
        "Tobias: [no weapons, just — standing there] I know what you're doing because I'm doing it.",
        "Celestiel: I'm not —",
        "Tobias: You're thinking about what you ate today. Or didn't eat. " +
        "You've been thinking about it since before I got here.",
        "Celestiel: ...",
        "Tobias: I know because I'm always thinking about it too. " +
        "The discipline and the compulsion feel identical from the inside. " +
        "I couldn't tell the difference until I had a moment where I wasn't — " +
        "where I was just in something good, and I felt the terror about the goodness, " +
        "and that's when I knew.",
        "Celestiel: [very quietly] What did you do with the terror?",
        "Tobias: I stayed in it. For as long as I could. " +
        "And then I came back here. I think staying in it is the whole thing.",
        "Celestiel: [long silence] " +
        "I have been disciplining myself toward something. " +
        "I don't remember what it was anymore. " +
        "I remember the discipline. Not the toward.",
        "Tobias: [sitting down, across from them] " +
        "Tell me what it was supposed to be for. " +
        "Take your time.",
        "[This is the longest talk-path in the game. It ends with both of them sitting " +
        "together in the quiet for a moment before the run continues. " +
        "No dramatic revelation. Just two people who understand each other " +
        "in a specific way sitting with that understanding.]",
      ],
    },

    combatNotes:
      "Fights with precision and patience. Wears the party down rather than breaking them. " +
      "The fight is long and clean and exhausting. " +
      "The difficulty is that Celestiel apologizes during combat — genuinely, softly — " +
      "for every blow landed. The gentleness is real. That makes it worse.",
  },

  // ── THE WRATHFUL ─────────────────────────────────────────
  // The Wrath boss. Brennan's mirror. Most morally serious.

  the_wrathful: {
    id: "the_wrathful",
    name: "???",
    nameRevealed: "Arariel",
    title: "The Wrathful",
    tier: "mountain_upper",
    sinMirrored: "wrath",
    characterMirror: "brennan",

    appearance:
      "Scarred in ways that suggest a very long history of fighting. " +
      "Not monstrous — worn. Like a weapon that has been used seriously " +
      "and has the marks to prove it. Still burning, but the burn is cold now. " +
      "The kind of anger that has been running long enough to calcify into purpose.",

    philosophy:
      "The mountain breaks people into acceptance of a system that should be rejected. " +
      "Every soul that 'ascends' is a soul that learned to stop asking why. " +
      "Why this? Why this system? Why this loop, this cost, this arrangement " +
      "where beings with no choice suffer for the education of others? " +
      "Arariel asked why. Has been asking why with increasing urgency " +
      "for longer than this mountain has existed. " +
      "The answer has never come. The asking will continue until the system breaks.",

    whyTheyreNotCompletelyWrong:
      "The cost is real. The suffering is real. " +
      "The question — why this? — is a legitimate question " +
      "that the game does not answer with easy theology. " +
      "Arariel is wrong about what to do with the question. " +
      "They are not wrong to have the question. " +
      "The party has to earn the right to stand in front of Arariel " +
      "and say: I have the same question. I'm choosing differently with it. " +
      "And they can only say that if they've actually done the work.",

    loopDialogue: {
      loop1: "You're here to maintain a system that is hurting people. I am here to end it.",
      loop2: "You've died here before. You came back. Why? What are you fighting for?",
      loop3: "I asked why once. One specific time. With everything I had. " +
             "The silence was the answer. So I became the answer.",
      loop5: "Tell me what you believe about this. Not what you were told. What you believe. " +
             "Because I can see you don't fully believe it yet. " +
             "Come back when you do. The fight will be more interesting.",
      loop8: "You're different. You've been asking the same question I've been asking. " +
             "I can see it. " +
             "So here is what I want to know: why are you still here? " +
             "Why are you still running this mountain for a system that won't explain itself?",
      loop12: "[Arariel stops before the first blow] " +
              "I've been fighting this mountain since before most of the people on it arrived. " +
              "I have not made it stop. " +
              "What are you doing that I haven't tried?",
    },

    talkPath: {
      requiresCharacter: "brennan",
      requiresCostumeIntegrity: { brennan: 25 },
      requiresRuns: 12,
      requiresMosesEncounter: true,
      dialogue: [
        "Brennan: I have the same question you do. " +
        "Why this? Why this cost? Why this loop?",
        "Arariel: [waiting]",
        "Brennan: I don't have an answer. I've been fighting long enough to know " +
        "I might never have an answer. And I'm still here.",
        "Arariel: That's not faith. That's inertia.",
        "Brennan: [quietly] Maybe. But I met someone on this mountain. " +
        "He was barred from the thing he'd worked toward for his whole life " +
        "because of one moment. He saw the land from a mountain. " +
        "He said the seeing was the gift.",
        "Arariel: ...",
        "Brennan: I don't know if this is the promised land or not. " +
        "I don't know if we get there. I know the seeing — the understanding, " +
        "the actual looking at what humanity is and why it keeps doing this — " +
        "I know that's already happened. That's already in me.",
        "Arariel: [a very long pause] " +
        "You're not defending the system. You're just — staying in it.",
        "Brennan: Yeah. That's basically it.",
        "Arariel: [lowering weapons] " +
        "I've been fighting for so long that I forgot there was an alternative " +
        "to fighting that wasn't surrender. " +
        "[beat] " +
        "I'm very tired.",
        "Brennan: I know. Sit down for a minute.",
        "[The fight doesn't end. Arariel will fight again next loop. " +
        "But something shifted. The fight next loop is different. " +
        "Still hard. But no longer cold.]",
      ],
    },

    combatNotes:
      "Most aggressive boss. Pure pressure. The mechanic is that Arariel gets stronger " +
      "the more the party defends rather than engages. " +
      "You have to fight forward, toward them, to reduce their power. " +
      "The game is asking you to engage rather than avoid. " +
      "The character who mirrors this most directly: Brennan.",
  },

  // ── THE MIRROR ───────────────────────────────────────────
  // Appears to a different party member each loop. No fixed assignment.

  the_mirror: {
    id: "the_mirror",
    name: "???",
    nameRevealed: null,          // Name is never revealed. That is the point.
    title: "The Mirror",
    tier: "mountain_variable",   // Appears at different tiers — always relevant
    sinMirrored: "variable",
    characterMirror: "variable", // Different each loop

    appearance:
      "Whoever the most vulnerable party member is at the time of encounter, " +
      "wearing different armor. Same face. Different choices accumulated. " +
      "Moves like them. Uses their abilities. Has their tells. " +
      "And is not them — is a version of them that went a different direction " +
      "at some point that neither of them can locate.",

    philosophy:
      "None stated. The Mirror does not speak except in combat. " +
      "Which is, itself, a kind of statement.",

    whyThisWorks:
      "The player has to fight a version of their own character. " +
      "Every ability they've developed, turned against them. " +
      "The question the Mirror poses without asking: " +
      "what is the difference between you and the version of you that chose differently? " +
      "Is it the choices? Is it circumstances? Is it something inherent? " +
      "The game doesn't answer this. The fight asks the question and then ends.",

    loopDialogue: {
      always: "[No words. The Mirror looks at the character it mirrors. " +
              "The character looks back. The fight begins.]",
      postFight: "[The Mirror dissolves without ceremony. " +
                 "The character it mirrored carries the question for the rest of the run. " +
                 "Their hub dialogue after this encounter will reflect it.]",
    },

    postFightCharacterDialogue: {
      aeryn:  "I knew every move before it made it. That should feel like an advantage. " +
              "It felt like a mirror. I've been thinking about what that means.",
      cael:   "It had all my skills. It had all my precision. It was completely alone. " +
              "I don't know how to feel about what I felt watching that.",
      brennan:"It hit as hard as I do. It was angrier than I am. " +
              "I don't think it was hurting more than I am. " +
              "I think it had just — run out of other directions.",
      solan:  "It knew what I was going to do before I did. " +
              "Which means it was still observing and not acting. " +
              "I wonder if that's comfort or indictment.",
      mira:   "It was managing everything. Every resource, every position, perfect control. " +
              "I've never felt more seen and more devastated at the same time.",
      tobias: "It moved carefully. Very carefully. " +
              "Like every action had a cost it was pre-calculating. " +
              "I recognized that calculation from somewhere I don't usually look at.",
      seren:  "It saw me. Better than I see most people. " +
              "And it used everything it saw. " +
              "I've been asking myself — is that what I do? " +
              "I don't know yet. I'm going to sit with not knowing.",
    },

    combatNotes:
      "Uses the mirrored character's exact moveset. " +
      "Can be more effective with those moves than the original character " +
      "because it has no hesitation — no costume integrity to manage, " +
      "no relationship considerations. " +
      "Pure expression of the sin, combat-optimized.",
  },
};

// ── Helpers ──────────────────────────────────────────────────

export function getBossById(id) {
  return BOSSES[id] ?? null;
}

export function getBossLoopDialogue(bossId, loopCount) {
  const boss = BOSSES[bossId];
  if (!boss?.loopDialogue) return null;

  // Find the highest loop threshold the player meets
  const thresholds = Object.keys(boss.loopDialogue)
    .filter(k => k.startsWith('loop'))
    .map(k => parseInt(k.replace('loop', '')))
    .sort((a, b) => b - a);

  const matched = thresholds.find(t => loopCount >= t);
  return matched ? boss.loopDialogue[`loop${matched}`] : boss.loopDialogue.loop1;
}

export function isTalkPathAvailable(bossId, gameState) {
  const boss = BOSSES[bossId];
  if (!boss?.talkPath) return false;
  const tp = boss.talkPath;

  if (tp.requiresRuns && gameState.totalRuns < tp.requiresRuns) return false;
  if (tp.requiresCostumeIntegrity) {
    for (const [charId, maxIntegrity] of Object.entries(tp.requiresCostumeIntegrity)) {
      const actual = gameState.costumeIntegrity?.[charId] ?? 100;
      if (actual > maxIntegrity) return false;
    }
  }
  if (tp.requiresHubDialogue) {
    for (const flag of tp.requiresHubDialogue) {
      if (!gameState.narrativeFlags?.[flag]) return false;
    }
  }
  if (tp.requiresMosesEncounter && !gameState.soulEncounters?.moses_middle) return false;
  return true;
}
