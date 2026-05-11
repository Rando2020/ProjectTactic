export const MISSIONS = {
  ashvale_null_drake: {
    id: 'ashvale_null_drake',
    questId: 'cracked_bell',
    townId: 'ashvale',
    title: 'Eastern Road Breach',
    subtitle: 'Tutorial skirmish',
    biome: 'Cracked shrine road',
    recommendedLevel: 1,
    difficulty: 'Story',
    objective: 'Defeat the Null Drake and protect Ashvale civilians.',
    bonusObjectives: ['Win within 6 rounds', 'Trigger one SURGE', 'No ally is KO’d'],
    enemyPreview: ['Null Drake', 'Null Shade'],
    rewards: { jp: 30, gold: 120, items: ['Vitae Draught'] },
    unlockFlagsOnComplete: ['completed_intro_battle'],
    unlockTownIdsOnComplete: ['mirefen'],
    unlockQuestIdsOnComplete: ['road_to_mirefen'],
    tacticalTags: ['tutorial', 'guardian-echo', 'low-threat'],
    map: {
      width: 8,
      height: 6,
      terrain: 'broken-road',
      hazards: ['void fissure'],
      elevationNotes: 'Small ridge teaches height advantage later.'
    }
  },

  mirefen_reaction_trial: {
    id: 'mirefen_reaction_trial',
    questId: 'road_to_mirefen',
    townId: 'mirefen',
    title: 'Marshlight Reaction Trial',
    subtitle: 'Elemental reaction skirmish',
    biome: 'Flooded reed marsh',
    recommendedLevel: 2,
    difficulty: 'Normal',
    objective: 'Use Wet reactions to freeze or electrify enemies before they reach the shrine skiff.',
    bonusObjectives: ['Trigger FREEZE', 'Trigger ELECTRIFY', 'Keep the skiff intact'],
    enemyPreview: ['Bog Imp', 'Drowned Nullkin', 'Reed Shade'],
    rewards: { jp: 55, gold: 180, items: ['Resonance Phial'] },
    unlockFlagsOnComplete: ['completed_mirefen_trial'],
    unlockTownIdsOnComplete: ['stormglass'],
    unlockQuestIdsOnComplete: ['stormglass_trials'],
    tacticalTags: ['water', 'ice', 'thunder', 'reaction-training'],
    map: {
      width: 9,
      height: 7,
      terrain: 'marsh',
      hazards: ['deep water', 'conductive pools'],
      elevationNotes: 'Low ground floods after round three.'
    }
  },

  stormglass_deflect_trial: {
    id: 'stormglass_deflect_trial',
    questId: 'stormglass_trials',
    townId: 'stormglass',
    title: 'Between Thunderbeats',
    subtitle: 'Timing and defense trial',
    biome: 'Copper-glass ramparts',
    recommendedLevel: 3,
    difficulty: 'Tactical',
    objective: 'Survive precision strikes and use DEFLECT to halve incoming burst damage.',
    bonusObjectives: ['Land 3 DEFLECTS', 'Win without using revive', 'Defeat the Storm Warden last'],
    enemyPreview: ['Storm Warden', 'Glass Imp', 'Copper Archer'],
    rewards: { jp: 80, gold: 260, items: ['Ironcore Shard'] },
    unlockFlagsOnComplete: ['completed_stormglass_trial'],
    unlockTownIdsOnComplete: [],
    unlockQuestIdsOnComplete: [],
    tacticalTags: ['deflect', 'thunder', 'positioning', 'timing'],
    map: {
      width: 10,
      height: 7,
      terrain: 'stormglass-rampart',
      hazards: ['lightning rods', 'glass edge'],
      elevationNotes: 'High ground amplifies thunder damage.'
    }
  }
}

export const getMission = (missionId) => MISSIONS[missionId]

export const getMissionsForTown = (townId) =>
  Object.values(MISSIONS).filter((mission) => mission.townId === townId)
