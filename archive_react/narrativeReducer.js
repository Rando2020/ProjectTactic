// ============================================================
//  THE APPOINTED: AS ABOVE
//  narrativeReducer.js — State management for the full narrative system
// ============================================================

import { createInitialNarrativeState, getRelationshipKey } from './narrativeState.js';
import {
  REVELATION_TIERS, TIER_THRESHOLDS, CLARITY, COSTUME_INTEGRITY
} from '../config/gameConfig.js';

// ── Action Types ─────────────────────────────────────────────

export const NARRATIVE_ACTIONS = {
  // Run lifecycle
  BEGIN_RUN:            'narrative/BEGIN_RUN',
  END_RUN:              'narrative/END_RUN',

  // Clarity
  GAIN_CLARITY:         'narrative/GAIN_CLARITY',
  LOSE_CLARITY:         'narrative/LOSE_CLARITY',

  // Revelation
  GAIN_REVELATION:      'narrative/GAIN_REVELATION',

  // Character arcs
  TRIGGER_CRACK_EVENT:  'narrative/TRIGGER_CRACK_EVENT',
  ADD_TRUE_NAME_FRAGMENT: 'narrative/ADD_TRUE_NAME_FRAGMENT',
  REVEAL_TRUE_NAME:     'narrative/REVEAL_TRUE_NAME',
  LOWER_COSTUME:        'narrative/LOWER_COSTUME',
  REACH_RESOLUTION:     'narrative/REACH_RESOLUTION',

  // Relationships
  GAIN_INTIMACY:        'narrative/GAIN_INTIMACY',
  ADD_SHARED_MOMENT:    'narrative/ADD_SHARED_MOMENT',

  // Hub characters
  MEET_HUB_CHARACTER:   'narrative/MEET_HUB_CHARACTER',
  HUB_CONVERSATION:     'narrative/HUB_CONVERSATION',
  GIVE_HUB_GIFT:        'narrative/GIVE_HUB_GIFT',
  ARCHIVIST_LEARNS_TRUTH: 'narrative/ARCHIVIST_LEARNS_TRUTH',

  // Soul encounters
  MEET_SOUL:            'narrative/MEET_SOUL',
  ADVANCE_SOUL_ENCOUNTER: 'narrative/ADVANCE_SOUL_ENCOUNTER',
  SOUL_DEPARTS:         'narrative/SOUL_DEPARTS',

  // Boss memory
  BOSS_FIGHT_COMPLETE:  'narrative/BOSS_FIGHT_COMPLETE',
  BOSS_TALK_PATH_ATTEMPTED: 'narrative/BOSS_TALK_PATH_ATTEMPTED',
  BOSS_TALK_PATH_COMPLETE: 'narrative/BOSS_TALK_PATH_COMPLETE',
  PLAYER_FLED_BOSS:     'narrative/PLAYER_FLED_BOSS',
  MIRROR_APPEARED:      'narrative/MIRROR_APPEARED',

  // Narrative flags
  SET_FLAG:             'narrative/SET_FLAG',

  // Hub character dialogue tiers
  ADVANCE_HUB_DIALOGUE_TIER: 'narrative/ADVANCE_HUB_DIALOGUE_TIER',

  // Hypnos dream reveals
  GIVE_DREAM_REVEAL:    'narrative/GIVE_DREAM_REVEAL',

  // Mnemosyne
  RETURN_MEMORY_FRAGMENT: 'narrative/RETURN_MEMORY_FRAGMENT',
};

// ── Action Creators ──────────────────────────────────────────

export const narrativeActions = {
  beginRun: () => ({
    type: NARRATIVE_ACTIONS.BEGIN_RUN,
  }),

  endRun: (runSummary) => ({
    type: NARRATIVE_ACTIONS.END_RUN,
    payload: runSummary,
    // runSummary: { soulsHelped, bossesDefeated, bossesFlед, clarityAtEnd,
    //               crackEventsThisRun, killingBlows }
  }),

  gainClarity: (amount, reason) => ({
    type: NARRATIVE_ACTIONS.GAIN_CLARITY,
    payload: { amount, reason },
  }),

  loseClarity: (amount, reason) => ({
    type: NARRATIVE_ACTIONS.LOSE_CLARITY,
    payload: { amount, reason },
  }),

  gainRevelation: (points, source) => ({
    type: NARRATIVE_ACTIONS.GAIN_REVELATION,
    payload: { points, source },
  }),

  triggerCrackEvent: (charId) => ({
    type: NARRATIVE_ACTIONS.TRIGGER_CRACK_EVENT,
    payload: { charId },
  }),

  addTrueNameFragment: (charId) => ({
    type: NARRATIVE_ACTIONS.ADD_TRUE_NAME_FRAGMENT,
    payload: { charId },
  }),

  revealTrueName: (charId, trueName) => ({
    type: NARRATIVE_ACTIONS.REVEAL_TRUE_NAME,
    payload: { charId, trueName },
  }),

  lowerCostume: (charId, amount) => ({
    type: NARRATIVE_ACTIONS.LOWER_COSTUME,
    payload: { charId, amount },
  }),

  reachResolution: (charId) => ({
    type: NARRATIVE_ACTIONS.REACH_RESOLUTION,
    payload: { charId },
  }),

  gainIntimacy: (charIdA, charIdB, amount) => ({
    type: NARRATIVE_ACTIONS.GAIN_INTIMACY,
    payload: { charIdA, charIdB, amount },
  }),

  addSharedMoment: (charIdA, charIdB, momentId) => ({
    type: NARRATIVE_ACTIONS.ADD_SHARED_MOMENT,
    payload: { charIdA, charIdB, momentId },
  }),

  meetHubCharacter: (hubCharId) => ({
    type: NARRATIVE_ACTIONS.MEET_HUB_CHARACTER,
    payload: { hubCharId },
  }),

  hubConversation: (hubCharId) => ({
    type: NARRATIVE_ACTIONS.HUB_CONVERSATION,
    payload: { hubCharId },
  }),

  giveHubGift: (hubCharId, giftId) => ({
    type: NARRATIVE_ACTIONS.GIVE_HUB_GIFT,
    payload: { hubCharId, giftId },
  }),

  archivistLearnsTheTruth: () => ({
    type: NARRATIVE_ACTIONS.ARCHIVIST_LEARNS_TRUTH,
  }),

  meetSoul: (soulId) => ({
    type: NARRATIVE_ACTIONS.MEET_SOUL,
    payload: { soulId },
  }),

  advanceSoulEncounter: (soulId, newState) => ({
    type: NARRATIVE_ACTIONS.ADVANCE_SOUL_ENCOUNTER,
    payload: { soulId, newState },
  }),

  soulDeparts: (soulId) => ({
    type: NARRATIVE_ACTIONS.SOUL_DEPARTS,
    payload: { soulId },
  }),

  bossFightComplete: (bossId, killedByCharId, loopCount) => ({
    type: NARRATIVE_ACTIONS.BOSS_FIGHT_COMPLETE,
    payload: { bossId, killedByCharId, loopCount },
  }),

  bossTalkPathAttempted: (bossId) => ({
    type: NARRATIVE_ACTIONS.BOSS_TALK_PATH_ATTEMPTED,
    payload: { bossId },
  }),

  bossTalkPathComplete: (bossId) => ({
    type: NARRATIVE_ACTIONS.BOSS_TALK_PATH_COMPLETE,
    payload: { bossId },
  }),

  playerFledBoss: (bossId) => ({
    type: NARRATIVE_ACTIONS.PLAYER_FLED_BOSS,
    payload: { bossId },
  }),

  mirrorAppeared: (targetCharId) => ({
    type: NARRATIVE_ACTIONS.MIRROR_APPEARED,
    payload: { targetCharId },
  }),

  setFlag: (flagName, value = true) => ({
    type: NARRATIVE_ACTIONS.SET_FLAG,
    payload: { flagName, value },
  }),

  advanceHubDialogueTier: (hubCharId) => ({
    type: NARRATIVE_ACTIONS.ADVANCE_HUB_DIALOGUE_TIER,
    payload: { hubCharId },
  }),

  giveDreamReveal: (charId) => ({
    type: NARRATIVE_ACTIONS.GIVE_DREAM_REVEAL,
    payload: { charId },
  }),

  returnMemoryFragment: (charId, fragmentText) => ({
    type: NARRATIVE_ACTIONS.RETURN_MEMORY_FRAGMENT,
    payload: { charId, fragmentText },
  }),
};

// ── Reducer ──────────────────────────────────────────────────

export function narrativeReducer(state, action) {
  if (!state) return createInitialNarrativeState();

  switch (action.type) {

    case NARRATIVE_ACTIONS.BEGIN_RUN: {
      return {
        ...state,
        currentRun: state.currentRun + 1,
        totalRuns: state.totalRuns + 1,
        clarity: CLARITY.START,
      };
    }

    case NARRATIVE_ACTIONS.END_RUN: {
      const summary = action.payload;
      const newHistory = [...state.runHistory, {
        run: state.currentRun,
        ...summary,
      }];
      return {
        ...state,
        runHistory: newHistory,
      };
    }

    case NARRATIVE_ACTIONS.GAIN_CLARITY: {
      const newClarity = Math.min(
        CLARITY.MAX,
        state.clarity + action.payload.amount
      );
      return { ...state, clarity: newClarity };
    }

    case NARRATIVE_ACTIONS.LOSE_CLARITY: {
      const newClarity = Math.max(
        CLARITY.MIN,
        state.clarity - action.payload.amount
      );
      return { ...state, clarity: newClarity };
    }

    case NARRATIVE_ACTIONS.GAIN_REVELATION: {
      const newPoints = state.revelationPoints + action.payload.points;
      // Check for tier advancement
      let newTier = state.revelationTier;
      for (const [tier, threshold] of Object.entries(TIER_THRESHOLDS)) {
        if (newPoints >= threshold) {
          newTier = Math.max(newTier, parseInt(tier));
        }
      }
      return {
        ...state,
        revelationPoints: newPoints,
        revelationTier: newTier,
      };
    }

    case NARRATIVE_ACTIONS.LOWER_COSTUME: {
      const { charId, amount } = action.payload;
      const char = state.characters[charId];
      if (!char) return state;
      const newIntegrity = Math.max(0, char.costumeIntegrity - amount);
      return {
        ...state,
        characters: {
          ...state.characters,
          [charId]: { ...char, costumeIntegrity: newIntegrity },
        },
      };
    }

    case NARRATIVE_ACTIONS.TRIGGER_CRACK_EVENT: {
      const { charId } = action.payload;
      const char = state.characters[charId];
      if (!char) return state;

      // Crack event lowers costume significantly, gains revelation and clarity
      const newIntegrity = Math.max(
        0,
        char.costumeIntegrity + COSTUME_INTEGRITY.CRACK_EVENT
      );

      return {
        ...state,
        clarity: Math.min(CLARITY.MAX, state.clarity + CLARITY.CRACK_EVENT_TRIGGERED),
        revelationPoints: state.revelationPoints + 30,
        characters: {
          ...state.characters,
          [charId]: {
            ...char,
            costumeIntegrity: newIntegrity,
            crackEventTriggered: true,
          },
        },
        narrativeFlags: {
          ...state.narrativeFlags,
          [`${charId}_crack_event_complete`]: true,
        },
      };
    }

    case NARRATIVE_ACTIONS.ADD_TRUE_NAME_FRAGMENT: {
      const { charId } = action.payload;
      const char = state.characters[charId];
      if (!char) return state;
      const newFragments = char.trueNameFragments + 1;

      return {
        ...state,
        clarity: Math.min(CLARITY.MAX, state.clarity + CLARITY.TRUE_NAME_FRAGMENT),
        characters: {
          ...state.characters,
          [charId]: {
            ...char,
            trueNameFragments: newFragments,
            // Automatically lower costume when fragments are collected
            costumeIntegrity: Math.max(
              0,
              char.costumeIntegrity + COSTUME_INTEGRITY.TRUE_NAME_FRAGMENT
            ),
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.REVEAL_TRUE_NAME: {
      const { charId, trueName } = action.payload;
      const char = state.characters[charId];
      if (!char) return state;

      // True name reveal is a major revelation moment
      return {
        ...state,
        revelationPoints: state.revelationPoints + 50,
        clarity: Math.min(CLARITY.MAX, state.clarity + CLARITY.TRUE_NAME_FRAGMENT),
        characters: {
          ...state.characters,
          [charId]: {
            ...char,
            trueName,
            costumeIntegrity: 0,
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.REACH_RESOLUTION: {
      const { charId } = action.payload;
      const char = state.characters[charId];
      if (!char) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 100,
        characters: {
          ...state.characters,
          [charId]: {
            ...char,
            resolutionReached: true,
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.GAIN_INTIMACY: {
      const { charIdA, charIdB, amount } = action.payload;
      const key = getRelationshipKey(charIdA, charIdB);
      const rel = state.relationships[key];
      if (!rel) return state;

      const newIntimacy = rel.intimacy + amount;
      return {
        ...state,
        relationships: {
          ...state.relationships,
          [key]: {
            ...rel,
            intimacy: newIntimacy,
            tensionDialogueUnlocked: newIntimacy >= 15 || rel.tensionDialogueUnlocked,
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.ADD_SHARED_MOMENT: {
      const { charIdA, charIdB, momentId } = action.payload;
      const key = getRelationshipKey(charIdA, charIdB);
      const rel = state.relationships[key];
      if (!rel) return state;

      if (rel.momentsShared.includes(momentId)) return state;
      return {
        ...state,
        relationships: {
          ...state.relationships,
          [key]: {
            ...rel,
            momentsShared: [...rel.momentsShared, momentId],
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.MEET_HUB_CHARACTER: {
      const { hubCharId } = action.payload;
      const hubChar = state.hubCharacters[hubCharId];
      if (!hubChar || hubChar.met) return state;

      return {
        ...state,
        hubCharacters: {
          ...state.hubCharacters,
          [hubCharId]: { ...hubChar, met: true },
        },
        revelationPoints: state.revelationPoints + 10,
      };
    }

    case NARRATIVE_ACTIONS.HUB_CONVERSATION: {
      const { hubCharId } = action.payload;
      const hubChar = state.hubCharacters[hubCharId];
      if (!hubChar) return state;

      const conversations = (hubChar.conversations ?? 0) + 1;

      // Auto-advance dialogue tier based on conversation count
      const currentTier = hubChar.dialogueTier ?? 1;
      const newTier = conversations >= 8 ? Math.min(5, currentTier + 1)
                    : conversations >= 4 ? Math.min(4, currentTier + 1)
                    : currentTier;

      return {
        ...state,
        clarity: Math.min(CLARITY.MAX, state.clarity + CLARITY.HUB_RELATIONSHIP_MOMENT),
        hubCharacters: {
          ...state.hubCharacters,
          [hubCharId]: {
            ...hubChar,
            conversations,
            dialogueTier: newTier,
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.GIVE_HUB_GIFT: {
      const { hubCharId, giftId } = action.payload;
      const hubChar = state.hubCharacters[hubCharId];
      if (!hubChar) return state;

      if (hubChar.giftsGiven?.includes(giftId)) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 15,
        hubCharacters: {
          ...state.hubCharacters,
          [hubCharId]: {
            ...hubChar,
            giftsGiven: [...(hubChar.giftsGiven ?? []), giftId],
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.ARCHIVIST_LEARNS_TRUTH: {
      return {
        ...state,
        revelationPoints: state.revelationPoints + 40,
        hubCharacters: {
          ...state.hubCharacters,
          archivist: {
            ...state.hubCharacters.archivist,
            knowsTheTruth: true,
          },
        },
        narrativeFlags: {
          ...state.narrativeFlags,
          archivist_tier4_conversation: true,
        },
      };
    }

    case NARRATIVE_ACTIONS.MEET_SOUL: {
      const { soulId } = action.payload;
      const soul = state.soulEncounters[soulId];
      if (!soul || soul.met) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 20,
        clarity: Math.min(CLARITY.MAX, state.clarity + CLARITY.SOUL_CONVERSATION),
        soulEncounters: {
          ...state.soulEncounters,
          [soulId]: { ...soul, met: true, encounterState: 'early' },
        },
      };
    }

    case NARRATIVE_ACTIONS.ADVANCE_SOUL_ENCOUNTER: {
      const { soulId, newState } = action.payload;
      const soul = state.soulEncounters[soulId];
      if (!soul) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 25,
        soulEncounters: {
          ...state.soulEncounters,
          [soulId]: { ...soul, encounterState: newState },
        },
      };
    }

    case NARRATIVE_ACTIONS.SOUL_DEPARTS: {
      const { soulId } = action.payload;
      const soul = state.soulEncounters[soulId];
      if (!soul) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 40,
        soulEncounters: {
          ...state.soulEncounters,
          [soulId]: { ...soul, departed: true, encounterState: 'departed' },
        },
        narrativeFlags: {
          ...state.narrativeFlags,
          [`${soulId}_departed`]: true,
        },
      };
    }

    case NARRATIVE_ACTIONS.BOSS_FIGHT_COMPLETE: {
      const { bossId, killedByCharId, loopCount } = action.payload;
      const boss = state.bossEncounters[bossId];
      if (!boss) return state;

      return {
        ...state,
        bossEncounters: {
          ...state.bossEncounters,
          [bossId]: {
            ...boss,
            totalFights: boss.totalFights + 1,
            lastKilledBy: killedByCharId,
            currentDialogueLoop: loopCount,
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.BOSS_TALK_PATH_ATTEMPTED: {
      const { bossId } = action.payload;
      const boss = state.bossEncounters[bossId];
      if (!boss) return state;

      return {
        ...state,
        bossEncounters: {
          ...state.bossEncounters,
          [bossId]: { ...boss, talkPathAttempted: true },
        },
      };
    }

    case NARRATIVE_ACTIONS.BOSS_TALK_PATH_COMPLETE: {
      const { bossId } = action.payload;
      const boss = state.bossEncounters[bossId];
      if (!boss) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 60,
        clarity: Math.min(CLARITY.MAX, state.clarity + CLARITY.BOSS_DIALOGUE_UNLOCKED),
        bossEncounters: {
          ...state.bossEncounters,
          [bossId]: { ...boss, talkPathCompleted: true },
        },
      };
    }

    case NARRATIVE_ACTIONS.PLAYER_FLED_BOSS: {
      const { bossId } = action.payload;
      const boss = state.bossEncounters[bossId];
      if (!boss) return state;

      return {
        ...state,
        clarity: Math.max(CLARITY.MIN, state.clarity + CLARITY.FALLEN_ARGUMENT_FLED),
        bossEncounters: {
          ...state.bossEncounters,
          [bossId]: { ...boss, playerFled: true },
        },
      };
    }

    case NARRATIVE_ACTIONS.MIRROR_APPEARED: {
      const { targetCharId } = action.payload;
      const mirror = state.bossEncounters.the_mirror;

      return {
        ...state,
        bossEncounters: {
          ...state.bossEncounters,
          the_mirror: {
            ...mirror,
            totalAppearances: mirror.totalAppearances + 1,
            charactersTargeted: mirror.charactersTargeted.includes(targetCharId)
              ? mirror.charactersTargeted
              : [...mirror.charactersTargeted, targetCharId],
            lastTarget: targetCharId,
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.SET_FLAG: {
      const { flagName, value } = action.payload;
      return {
        ...state,
        narrativeFlags: {
          ...state.narrativeFlags,
          [flagName]: value,
        },
      };
    }

    case NARRATIVE_ACTIONS.ADVANCE_HUB_DIALOGUE_TIER: {
      const { hubCharId } = action.payload;
      const hubChar = state.hubCharacters[hubCharId];
      if (!hubChar) return state;

      return {
        ...state,
        hubCharacters: {
          ...state.hubCharacters,
          [hubCharId]: {
            ...hubChar,
            dialogueTier: Math.min(5, (hubChar.dialogueTier ?? 1) + 1),
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.GIVE_DREAM_REVEAL: {
      const { charId } = action.payload;
      const hypnos = state.hubCharacters.hypnos;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 15,
        hubCharacters: {
          ...state.hubCharacters,
          hypnos: {
            ...hypnos,
            dreamRevealsGiven: [...(hypnos.dreamRevealsGiven ?? []), charId],
          },
        },
      };
    }

    case NARRATIVE_ACTIONS.RETURN_MEMORY_FRAGMENT: {
      const { charId, fragmentText } = action.payload;
      const mnemosyne = state.hubCharacters.mnemosyne;
      const char = state.characters[charId];
      if (!char) return state;

      return {
        ...state,
        revelationPoints: state.revelationPoints + 30,
        hubCharacters: {
          ...state.hubCharacters,
          mnemosyne: {
            ...mnemosyne,
            visits: (mnemosyne.visits ?? 0) + 1,
            fragmentsReturned: [...(mnemosyne.fragmentsReturned ?? []), charId],
          },
        },
        characters: {
          ...state.characters,
          [charId]: {
            ...char,
            trueNameFragments: char.trueNameFragments + 1,
          },
        },
        narrativeFlags: {
          ...state.narrativeFlags,
          mnemosyne_first_fragment: true,
        },
      };
    }

    default:
      return state;
  }
}

// ── Integration snippet ───────────────────────────────────────
//
// In your main progressionReducer.js or gameReducer.js:
//
//   import { narrativeReducer, NARRATIVE_ACTIONS } from './narrativeReducer.js';
//
//   export function gameReducer(state, action) {
//     if (Object.values(NARRATIVE_ACTIONS).includes(action.type)) {
//       return {
//         ...state,
//         narrative: narrativeReducer(state.narrative, action),
//       };
//     }
//     // ... existing cases
//   }
//
// In initialGameState.js, add:
//   import { createInitialNarrativeState } from './narrativeState.js';
//   narrative: createInitialNarrativeState(),
