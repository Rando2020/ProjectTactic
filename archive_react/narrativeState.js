// ============================================================
//  THE APPOINTED: AS ABOVE
//  narrativeState.js — Initial state + state shape documentation
// ============================================================

import { REVELATION_TIERS, CLARITY, COSTUME_INTEGRITY } from '../config/gameConfig.js';

// ── Initial State ────────────────────────────────────────────

export function createInitialNarrativeState() {
  return {

    // ── Meta ──────────────────────────────────────────────
    gameTitle: "The Appointed: As Above",
    totalRuns: 0,
    currentRun: 0,

    // ── Revelation ────────────────────────────────────────
    // How much of the truth has been uncovered.
    // This is global — affects what every system shows.
    revelationTier: REVELATION_TIERS.TIER_1,
    revelationPoints: 0,

    // ── Clarity (per-run) ─────────────────────────────────
    // Resets each run. Built through meaningful engagement.
    clarity: CLARITY.START,

    // ── Character Truth Progress ──────────────────────────
    // Each character has their own arc toward their true name.
    // costumeIntegrity: 100 = fully in costume. 0 = true name surfaces.
    characters: {
      aeryn: {
        humanName: "Aeryn",
        trueName: null,               // null until revealed
        trueNameFragments: 0,         // 0-3 fragments before full name
        costumeIntegrity: 100,
        currentJob: "soldier",
        level: 1,
        intimacyUnlocked: {},         // { charId: intimacyScore }
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
      cael: {
        humanName: "Cael",
        trueName: null,
        trueNameFragments: 0,
        costumeIntegrity: 100,
        currentJob: "archer",
        level: 1,
        intimacyUnlocked: {},
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
      brennan: {
        humanName: "Brennan",
        trueName: null,
        trueNameFragments: 0,
        costumeIntegrity: 100,
        currentJob: "soldier",
        level: 1,
        intimacyUnlocked: {},
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
      solan: {
        humanName: "Solan",
        trueName: null,
        trueNameFragments: 0,
        costumeIntegrity: 100,
        currentJob: "mage",
        level: 1,
        intimacyUnlocked: {},
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
      mira: {
        humanName: "Mira",
        trueName: null,
        trueNameFragments: 0,
        costumeIntegrity: 100,
        currentJob: "vagrant",
        level: 1,
        intimacyUnlocked: {},
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
      tobias: {
        humanName: "Tobias",
        trueName: null,
        trueNameFragments: 0,
        costumeIntegrity: 100,
        currentJob: "cleric",
        level: 1,
        intimacyUnlocked: {},
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
      seren: {
        humanName: "Seren",
        trueName: null,
        trueNameFragments: 0,
        costumeIntegrity: 100,
        currentJob: "archer",
        level: 1,
        intimacyUnlocked: {},
        hubVisits: 0,
        crackEventTriggered: false,
        resolutionReached: false,
        currentDialogueTier: 1,
      },
    },

    // ── Relationships ─────────────────────────────────────
    // Intimacy between party members. Unlocks tension dialogue,
    // special joint encounters, and combined abilities.
    relationships: {
      // Format: "charA_charB" (alphabetical) -> intimacy score
      aeryn_cael:    { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      aeryn_brennan: { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      aeryn_solan:   { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      aeryn_mira:    { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      aeryn_tobias:  { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      aeryn_seren:   { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      cael_brennan:  { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      cael_solan:    { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      cael_mira:     { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      cael_tobias:   { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      cael_seren:    { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      brennan_solan: { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      brennan_mira:  { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      brennan_tobias:{ intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      brennan_seren: { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      solan_mira:    { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      solan_tobias:  { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      solan_seren:   { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      mira_tobias:   { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      mira_seren:    { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
      tobias_seren:  { intimacy: 0, momentsShared: [], tensionDialogueUnlocked: false },
    },

    // ── Hub Character Progress ────────────────────────────
    hubCharacters: {
      charon:     { met: false, conversations: 0, giftsGiven: [], dialogueTier: 1 },
      nyx:        { met: false, conversations: 0, giftsGiven: [], dialogueTier: 1 },
      hemera:     { met: false, appearances: 0 },
      persephone: { met: false, conversations: 0, giftsGiven: [], dialogueTier: 1 },
      hades:      { met: false, introduced: false, conversations: 0, dialogueTier: 1 },
      hypnos:     { met: false, conversations: 0, dreamRevealsGiven: [] },
      mnemosyne:  { met: false, visits: 0, fragmentsReturned: [] },
      archivist:  { met: false, conversations: 0, giftsGiven: [], knowsTheTruth: false },
    },

    // ── Soul Encounters ───────────────────────────────────
    // Which historical souls have been met and at what state
    soulEncounters: {
      adam:    { met: false, encounterState: null, departed: false },
      eve:     { met: false, encounterState: null },
      cain:    { met: false, encounterState: null },
      moses:   { met: false, encounterState: null, departed: false },
      elijah:  { met: false, encounterState: null },
      david:   { met: false, encounterState: null },
      job:     { met: false, encounterState: null },
    },

    // ── Boss Memory ───────────────────────────────────────
    // Bosses track encounters. This changes their dialogue and enables talk paths.
    bossEncounters: {
      the_righteous_one: {
        totalFights: 0,
        lastKilledBy: null,      // which character dealt killing blow
        playerFled: false,
        talkPathAttempted: false,
        talkPathCompleted: false,
        currentDialogueLoop: null,
      },
      the_keeper: {
        totalFights: 0,
        lastKilledBy: null,
        playerFled: false,
        talkPathAttempted: false,
        talkPathCompleted: false,
        currentDialogueLoop: null,
      },
      the_devoted: {
        totalFights: 0,
        lastKilledBy: null,
        playerFled: false,
        talkPathAttempted: false,
        talkPathCompleted: false,
        currentDialogueLoop: null,
      },
      the_wrathful: {
        totalFights: 0,
        lastKilledBy: null,
        playerFled: false,
        talkPathAttempted: false,
        talkPathCompleted: false,
        currentDialogueLoop: null,
      },
      the_mirror: {
        totalAppearances: 0,
        charactersTargeted: [],     // which characters it has mirrored
        lastTarget: null,
      },
    },

    // ── Narrative Flags ───────────────────────────────────
    // Boolean flags for story gates. Add as needed.
    narrativeFlags: {
      // Tier 1 flags
      first_enemy_hesitation: false,
      first_run_complete: false,

      // Tier 2 flags
      enemy_spoke_words: false,           // "I had a name"
      aeryn_tier2_dialogue_seen: false,
      cael_tier2_dialogue_seen: false,
      brennan_tier2_dialogue_seen: false,
      solan_tier2_dialogue_seen: false,
      mira_tier2_dialogue_seen: false,
      tobias_tier2_dialogue_seen: false,
      seren_tier2_dialogue_seen: false,

      // Crack events
      aeryn_crack_event_complete: false,
      cael_crack_event_complete: false,
      brennan_crack_event_complete: false,
      solan_crack_event_complete: false,
      mira_crack_event_complete: false,
      tobias_crack_event_complete: false,
      seren_crack_event_complete: false,

      // Tier 3 flags
      fallen_angel_first_encounter: false,
      fallen_remembers_party: false,

      // Tier 4 flags
      party_knows_what_they_are: false,
      raziel_revelation_spoken: false,  // Solan says "we are the trial and the tried"

      // Tier 5 flags
      adam_departed: false,
      moses_departed: false,
      ascent_begun: false,

      // Hub-specific
      archivist_tier3_conversation: false,
      persephone_introduced_hades: false,
      charon_gave_loop_count: false,
      hypnos_dream_reveals_complete: false,
      mnemosyne_first_fragment: false,
    },

    // ── Run History ───────────────────────────────────────
    // A lightweight record of each run for boss/soul memory references
    runHistory: [],
    // Each entry: { run, soulsHelped, bossesDefeated, bossesFlед, clarityAtEnd,
    //               crackEventsThisRun, killingBlows: {bossId: charId} }
  };
}

// ── Relationship Key Helper ───────────────────────────────────
// Always alphabetical so we don't need both directions
export function getRelationshipKey(charIdA, charIdB) {
  return [charIdA, charIdB].sort().join('_');
}

export function getRelationship(state, charIdA, charIdB) {
  const key = getRelationshipKey(charIdA, charIdB);
  return state.relationships[key] ?? null;
}

export function getCharacterNarrativeState(state, charId) {
  return state.characters[charId] ?? null;
}
