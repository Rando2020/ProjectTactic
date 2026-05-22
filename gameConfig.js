// ============================================================
//  THE APPOINTED: AS ABOVE
//  gameConfig.js — Global constants, tier definitions, theming
// ============================================================

export const GAME_TITLE = "The Appointed";
export const GAME_SUBTITLE = "As Above";
export const GAME_FULL_TITLE = "The Appointed: As Above";

// ── Revelation Tiers ────────────────────────────────────────
// How much of the truth the party (and player) has uncovered.
// Every system checks this to decide what to surface.
//
//  TIER 1 – "The War"         Surface layer. Demons. Tactics.
//  TIER 2 – "The Cracks"      Something is wrong. Souls don't act right.
//  TIER 3 – "The Fallen"      Real enemies revealed. Fallen Angels.
//  TIER 4 – "The Pattern"     They know what they are. What now?
//  TIER 5 – "The Ascent"      Endgame. The loop's true purpose.

export const REVELATION_TIERS = {
  TIER_1: 1,  // The War
  TIER_2: 2,  // The Cracks
  TIER_3: 3,  // The Fallen
  TIER_4: 4,  // The Pattern
  TIER_5: 5,  // The Ascent
};

export const TIER_LABELS = {
  1: "The War",
  2: "The Cracks",
  3: "The Fallen",
  4: "The Pattern",
  5: "The Ascent",
};

export const TIER_THRESHOLDS = {
  // Total "revelation points" needed to unlock each tier
  1: 0,
  2: 150,
  3: 400,
  4: 750,
  5: 1200,
};

// ── Clarity Meter ───────────────────────────────────────────
// Per-run resource. Built through meaningful encounters,
// relationships, and self-examination. Lost through
// unchecked sin expression. Affects mountain navigability.

export const CLARITY = {
  MIN: 0,
  MAX: 100,
  START: 30,
  // Gains
  SOUL_CONVERSATION: 8,
  BOSS_DIALOGUE_UNLOCKED: 15,
  HUB_RELATIONSHIP_MOMENT: 10,
  CRACK_EVENT_TRIGGERED: 20,
  TRUE_NAME_FRAGMENT: 25,
  // Losses
  SIN_UNCHECKED: -5,       // party member acts from unexamined sin
  SOUL_ABANDONED: -10,     // left a Type 2 soul without engaging
  FALLEN_ARGUMENT_FLED: -8,
};

// ── Run Tracking ────────────────────────────────────────────
export const RUN_MILESTONES = {
  FIRST_CRACK: 3,          // Run 3: first enemy hesitates mid-battle
  FIRST_SOUL: 5,           // Run 5: first historical soul encounter available
  BOSS_FIRST_MEMORY: 7,    // Run 7: first boss references past encounter
  CHARON_OPENS_UP: 10,     // Run 10: Charon starts sharing observations
  ENEMY_SPEAKS: 12,        // Run 12: mid-tier enemy says "I had a name"
  MNEMOSYNE_AVAILABLE: 15, // Run 15: Memory pool opens
  ADAM_AVAILABLE: 20,      // Run 20: Adam encounter unlocks
  FALLEN_REMEMBER_YOU: 25, // Run 25: Fallen Angels start referencing your history
};

// ── Costume Integrity ────────────────────────────────────────
// Each character's "costume" — the sanctified version of their sin —
// has an integrity value 0-100. Starts at 100. Cracks events lower it.
// When it reaches 0, the true name surfaces.

export const COSTUME_INTEGRITY = {
  START: 100,
  CRACK_EVENT: -15,
  MIRROR_ENCOUNTER: -20,
  HISTORICAL_SOUL_MET: -10,
  TRUE_NAME_FRAGMENT: -12,
  HUB_DEEP_CONVERSATION: -8,
  BOSS_SEES_THROUGH: -18,
};

// ── World Setting ────────────────────────────────────────────
export const WORLD = {
  NAME: "The Mountain",
  HUB_NAME: "The Antechamber",
  UPPER_REACHES: "The High Terraces",
  LOWER_DEPTHS: "The Deep Strata",
  BEYOND: "The Threshold",
};

// ── Aesthetic Constants ───────────────────────────────────────
export const PALETTE = {
  // Hub — warm decay, holy ruin
  HUB_BG: "#0a0806",
  HUB_WARM: "#c8a96e",
  HUB_STONE: "#3d3530",
  HUB_LIGHT: "#f0e8d0",
  HUB_SHADOW: "#1a1410",

  // Mountain — cold, ascending
  MOUNTAIN_BG: "#070a0f",
  MOUNTAIN_MIST: "#8fa3b8",
  MOUNTAIN_ICE: "#c8dde8",

  // Sin colors — each character has a thematic color
  PRIDE_GOLD: "#d4af37",
  ENVY_VERDIGRIS: "#4a8c6f",
  WRATH_CRIMSON: "#9b2335",
  SLOTH_DUSK: "#6b5b8a",
  GREED_AMBER: "#b8860b",
  GLUTTONY_ASH: "#8a9a8a",
  LUST_IVORY: "#e8d8c8",

  // Revelation tier colors — shift as truth is uncovered
  TIER_1: "#4a6fa5",    // cold blue — tactical, distant
  TIER_2: "#7a5c8a",    // violet — unease
  TIER_3: "#8a3a3a",    // deep red — fallen
  TIER_4: "#c8a040",    // gold — understanding
  TIER_5: "#e8e0d0",    // near-white — transcendence
};

export const FONTS = {
  TITLE: "'Cinzel Decorative', serif",
  HEADER: "'Cinzel', serif",
  BODY: "'Crimson Text', serif",
  UI: "'Cormorant Garamond', serif",
};

// ── Sin / Virtue Map ─────────────────────────────────────────
// The core theological engine of the game.
// Costume = the sanctified western Christian version of the sin.
// Virtue = what the sin was before it blurred.
// Arc = the journey from costume back to virtue.

export const SIN_VIRTUE_MAP = {
  pride:    { sin: "Pride",    costume: "Righteousness",     virtue: "Dignity",      color: PALETTE.PRIDE_GOLD },
  envy:     { sin: "Envy",     costume: "Righteous Advocacy",virtue: "Justice",      color: PALETTE.ENVY_VERDIGRIS },
  wrath:    { sin: "Wrath",    costume: "Holy Zeal",         virtue: "Righteous Anger",color: PALETTE.WRATH_CRIMSON },
  sloth:    { sin: "Sloth",    costume: "Contemplation",     virtue: "Sacred Rest",  color: PALETTE.SLOTH_DUSK },
  greed:    { sin: "Greed",    costume: "Stewardship",       virtue: "Provision",    color: PALETTE.GREED_AMBER },
  gluttony: { sin: "Gluttony", costume: "Bodily Purity",     virtue: "Joy",          color: PALETTE.GLUTTONY_ASH },
  lust:     { sin: "Lust",     costume: "Celibacy",          virtue: "Sacred Love",  color: PALETTE.LUST_IVORY },
};
