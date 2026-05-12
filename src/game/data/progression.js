// Vaelthar: Eidolon Chronicles
// Character, armor, and job progression data.
// Data-first progression layer for character sheets, save files, job unlocks, and future map combat.

export const CHARACTER_LEVEL_TABLE = [
  { level: 1, xp: 0 },
  { level: 2, xp: 100 },
  { level: 3, xp: 240 },
  { level: 4, xp: 420 },
  { level: 5, xp: 650 },
  { level: 6, xp: 930 },
  { level: 7, xp: 1260 },
  { level: 8, xp: 1640 },
  { level: 9, xp: 2070 },
  { level: 10, xp: 2550 },
  { level: 11, xp: 3080 },
  { level: 12, xp: 3660 },
  { level: 13, xp: 4290 },
  { level: 14, xp: 4970 },
  { level: 15, xp: 5700 },
  { level: 16, xp: 6480 },
  { level: 17, xp: 7310 },
  { level: 18, xp: 8190 },
  { level: 19, xp: 9120 },
  { level: 20, xp: 10100 },
  { level: 21, xp: 11150 },
  { level: 22, xp: 12280 },
  { level: 23, xp: 13490 },
  { level: 24, xp: 14780 },
  { level: 25, xp: 16150 },
  { level: 26, xp: 17620 },
  { level: 27, xp: 19190 },
  { level: 28, xp: 20860 },
  { level: 29, xp: 22640 },
  { level: 30, xp: 24540 },
]

export const JOB_LEVEL_TABLE = [
  { level: 0, jp: 0, title: 'Untrained', unlocks: ['Job can be viewed but has no learned kit.'] },
  { level: 1, jp: 30, title: 'Initiate', unlocks: ['Equippable job', 'Skill slot 1'] },
  { level: 2, jp: 90, title: 'Apprentice', unlocks: ['Skill slot 2', 'Eligible for first related-job unlocks'] },
  { level: 3, jp: 180, title: 'Adept', unlocks: ['Skill slot 3', 'Eligible for hybrid-job requirements'] },
  { level: 4, jp: 320, title: 'Specialist', unlocks: ['Skill slot 4', 'Improved passive scaling'] },
  { level: 5, jp: 520, title: 'Veteran', unlocks: ['Ascended prerequisite tier', 'Limit Break upgrade seed'] },
  { level: 6, jp: 800, title: 'Master', unlocks: ['Mastered job badge', 'Primal or endgame prerequisite tier'] },
  { level: 7, jp: 1200, title: 'Transcendent', unlocks: ['Late-game summon and relic scaling'] },
  { level: 8, jp: 1700, title: 'Mythic', unlocks: ['Mythic mastery badge', 'Future prestige hooks'] },
]

export const JOB_LEVELING_REQUIREMENTS = {
  sourceStat: 'JP',
  scope: 'per-character-per-job',
  activeJobShare: 1,
  spilloverShare: 0.15,
  benchShare: 0,
  masteryLevel: 6,
  ascendedPrimaryRequirementLevel: 5,
  ascendedCapstoneRequirementLevel: 6,
  mythicLevel: 8,
  recommendedAwards: {
    actionUsed: 6,
    weaknessHit: 4,
    statusApplied: 4,
    armorBroken: 6,
    comboTriggered: 8,
    resonanceSuccess: 20,
    battleClear: 18,
    bossClear: 35,
  },
  ui: {
    showCurrentJp: true,
    showJpToNextLevel: true,
    showMissingJobRequirements: true,
    showAscendedPreviewAtJobLevel: 3,
  },
}

export const ARMOR_SYSTEMS = {
  temper: {
    id: 'temper',
    label: 'Temper',
    shortLabel: 'TMP',
    color: '#f59e0b',
    icon: '🟧',
    characterSheetSection: 'Armor',
    defenseAxis: 'physical',
    description: 'Physical armor. It reduces incoming weapon pressure and protects against Bleed, Knockdown, Slow, Weaken, and Berserk.',
    protectedStatuses: ['bleed', 'knockdown', 'slow', 'weaken', 'berserk'],
    restoredBy: ['Ironcore Shard', 'Bulwark', 'Seraph passive', 'Warder training bonuses'],
    strippedBy: ['Sunder Strike', 'Null Breaker passive', 'heavy physical hits', 'earth armor-break effects'],
    zeroArmorRule: '+15% incoming physical damage and full physical status chance.',
  },
  ether: {
    id: 'ether',
    label: 'Ether',
    shortLabel: 'ETH',
    color: '#8b5cf6',
    icon: '🟪',
    characterSheetSection: 'Armor',
    defenseAxis: 'magical',
    description: 'Magical armor. It reduces incoming spell pressure and protects against Burn, Freeze, Stun, Silence, Curse, and Blind.',
    protectedStatuses: ['burning', 'chilled', 'frozen', 'stun', 'silence', 'blind', 'cursed', 'blessed'],
    restoredBy: ['Resonance Phial', 'Veil', 'Holy Guardian effects', 'Etherweaver training bonuses'],
    strippedBy: ['Flare', 'Dragon fire', 'Null Echo', 'Dark drain effects', 'elemental shatter reactions'],
    zeroArmorRule: '+15% incoming magical damage and full magical status chance.',
  },
}

export const CHARACTER_SHEET_SCHEMA = {
  identity: ['id', 'name', 'portrait', 'storyRole'],
  progression: ['level', 'xp', 'xpToNext', 'currentJobId', 'currentJobLevel', 'currentJobJp', 'jpToNextJobLevel', 'jobLevels', 'jobRequirements', 'unlockedJobs', 'masteredJobs', 'ascendedJobs'],
  coreStats: ['hp', 'mp', 'strength', 'mind', 'speed', 'bravery', 'faith'],
  armor: ['temper', 'maxTemper', 'ether', 'maxEther'],
  combat: ['ct', 'limitGauge', 'resonance', 'knownGuardians'],
}

export const JOBS = {
  warder: { id: 'warder', name: 'Warder', tier: 'base', archetype: 'frontline physical defender', primaryArmor: 'temper', unlock: { characterLevel: 1, jobLevels: {} }, ascendsTo: 'nullBreaker', statGrowth: { hp: 14, mp: 2, strength: 4, mind: 1, speed: 1, maxTemper: 9, maxEther: 3 } },
  arcanist: { id: 'arcanist', name: 'Arcanist', tier: 'base', archetype: 'elemental spell attacker', primaryArmor: 'ether', unlock: { characterLevel: 1, jobLevels: {} }, ascendsTo: 'etherweaver', statGrowth: { hp: 7, mp: 9, strength: 1, mind: 5, speed: 1, maxTemper: 3, maxEther: 8 } },
  resonant: { id: 'resonant', name: 'Resonant', tier: 'base', archetype: 'guardian binder and summon specialist', primaryArmor: 'ether', unlock: { characterLevel: 1, jobLevels: {} }, ascendsTo: 'primalBinder', statGrowth: { hp: 9, mp: 7, strength: 2, mind: 4, speed: 2, maxTemper: 4, maxEther: 8 } },
  luminary: { id: 'luminary', name: 'Luminary', tier: 'base', archetype: 'healer and armor restorer', primaryArmor: 'ether', unlock: { characterLevel: 1, jobLevels: {} }, ascendsTo: 'seraph', statGrowth: { hp: 8, mp: 8, strength: 1, mind: 5, speed: 1, maxTemper: 4, maxEther: 9 } },
  skywarden: { id: 'skywarden', name: 'Skywarden', tier: 'base', archetype: 'mobile aerial striker', primaryArmor: 'temper', unlock: { characterLevel: 4, jobLevels: { warder: 2 } }, ascendsTo: 'drakeAscendant', statGrowth: { hp: 11, mp: 4, strength: 4, mind: 2, speed: 3, maxTemper: 7, maxEther: 4 } },
  chronist: { id: 'chronist', name: 'Chronist', tier: 'base', archetype: 'turn-order and CT manipulator', primaryArmor: 'ether', unlock: { characterLevel: 4, jobLevels: { arcanist: 2 } }, ascendsTo: 'timeSovereign', statGrowth: { hp: 8, mp: 7, strength: 1, mind: 4, speed: 4, maxTemper: 3, maxEther: 7 } },
  oathbound: { id: 'oathbound', name: 'Oathbound', tier: 'base', archetype: 'paladin protector and party anchor', primaryArmor: 'temper', unlock: { characterLevel: 6, jobLevels: { warder: 2, luminary: 2 } }, ascendsTo: 'aegisVow', statGrowth: { hp: 13, mp: 5, strength: 3, mind: 3, speed: 1, maxTemper: 9, maxEther: 6 } },
  voidcaller: { id: 'voidcaller', name: 'Voidcaller', tier: 'base', archetype: 'dark caster and Ether breaker', primaryArmor: 'ether', unlock: { characterLevel: 6, jobLevels: { arcanist: 3, resonant: 1 } }, ascendsTo: 'abyssalMagister', statGrowth: { hp: 8, mp: 9, strength: 1, mind: 5, speed: 2, maxTemper: 3, maxEther: 8 } },
  nullResonant: { id: 'nullResonant', name: 'Null Resonant', tier: 'base', archetype: 'dangerous hybrid of Guardian resonance and Null corruption', primaryArmor: 'ether', unlock: { characterLevel: 10, jobLevels: { resonant: 3, voidcaller: 2 } }, ascendsTo: 'eclipseHarbinger', statGrowth: { hp: 10, mp: 8, strength: 2, mind: 5, speed: 2, maxTemper: 4, maxEther: 9 } },
  nullBreaker: { id: 'nullBreaker', name: 'Null Breaker', tier: 'ascended', baseJob: 'warder', archetype: 'anti-armor executioner', primaryArmor: 'temper', unlock: { characterLevel: 12, jobLevels: { warder: 5, skywarden: 2, oathbound: 2 } }, passive: { id: 'temperRend', description: 'Every physical hit strips 18 Temper before damage is finalized.' }, statGrowth: { hp: 16, mp: 3, strength: 5, mind: 2, speed: 2, maxTemper: 11, maxEther: 4 } },
  etherweaver: { id: 'etherweaver', name: 'Etherweaver', tier: 'ascended', baseJob: 'arcanist', archetype: 'combo caster and magical armor specialist', primaryArmor: 'ether', unlock: { characterLevel: 12, jobLevels: { arcanist: 5, chronist: 3, voidcaller: 2 } }, passive: { id: 'extendedComboChain', description: 'Elemental combo chain window increases from 7 seconds to 10 seconds.' }, statGrowth: { hp: 8, mp: 11, strength: 1, mind: 6, speed: 2, maxTemper: 3, maxEther: 11 } },
  primalBinder: { id: 'primalBinder', name: 'Primal Binder', tier: 'ascended', baseJob: 'resonant', archetype: 'summon master and Guardian liberator', primaryArmor: 'ether', unlock: { characterLevel: 14, jobLevels: { resonant: 6, luminary: 2, voidcaller: 2 }, flags: ['freedAnyPrimalGuardian'] }, passive: { id: 'guardianAmplifier', description: 'All Guardian summons gain +20% power and +10% Resonance Window success chance.' }, statGrowth: { hp: 10, mp: 10, strength: 2, mind: 6, speed: 2, maxTemper: 5, maxEther: 11 } },
  seraph: { id: 'seraph', name: 'Seraph', tier: 'ascended', baseJob: 'luminary', archetype: 'supreme healer and dual armor restorer', primaryArmor: 'ether', unlock: { characterLevel: 12, jobLevels: { luminary: 5, resonant: 2, oathbound: 3 } }, passive: { id: 'mendingLight', description: 'All healing also restores 35 Temper and 35 Ether to the target.' }, statGrowth: { hp: 9, mp: 11, strength: 1, mind: 6, speed: 2, maxTemper: 6, maxEther: 12 } },
  drakeAscendant: { id: 'drakeAscendant', name: 'Drake Ascendant', tier: 'ascended', baseJob: 'skywarden', archetype: 'jump attacker with dragonfire Ether break', primaryArmor: 'temper', unlock: { characterLevel: 12, jobLevels: { skywarden: 5, warder: 3, arcanist: 2 } }, passive: { id: 'aerialPressure', description: 'Jump and dive skills ignore 25% Temper and strip 15 Ether if the attack is fire-aligned.' }, statGrowth: { hp: 13, mp: 5, strength: 5, mind: 3, speed: 4, maxTemper: 9, maxEther: 6 } },
  timeSovereign: { id: 'timeSovereign', name: 'Time Sovereign', tier: 'ascended', baseJob: 'chronist', archetype: 'elite CT control and reaction strategist', primaryArmor: 'ether', unlock: { characterLevel: 13, jobLevels: { chronist: 5, arcanist: 3, resonant: 2 } }, passive: { id: 'ctOverflow', description: 'When this unit gains CT above 100, excess CT converts into +10% action power for the next action.' }, statGrowth: { hp: 9, mp: 9, strength: 1, mind: 5, speed: 5, maxTemper: 4, maxEther: 9 } },
  aegisVow: { id: 'aegisVow', name: 'Aegis Vow', tier: 'ascended', baseJob: 'oathbound', archetype: 'protector that redistributes armor and damage', primaryArmor: 'temper', unlock: { characterLevel: 13, jobLevels: { oathbound: 5, warder: 3, luminary: 3 } }, passive: { id: 'sharedAegis', description: 'At the start of battle, allies gain 15% of this unit’s max Temper as bonus Temper.' }, statGrowth: { hp: 15, mp: 6, strength: 4, mind: 4, speed: 1, maxTemper: 12, maxEther: 8 } },
  abyssalMagister: { id: 'abyssalMagister', name: 'Abyssal Magister', tier: 'ascended', baseJob: 'voidcaller', archetype: 'Null caster that drains and converts Ether', primaryArmor: 'ether', unlock: { characterLevel: 14, jobLevels: { voidcaller: 5, arcanist: 3, nullResonant: 3 } }, passive: { id: 'etherPredation', description: 'Dark and Null skills drain 10 Ether and convert half into caster Ether.' }, statGrowth: { hp: 9, mp: 11, strength: 1, mind: 7, speed: 2, maxTemper: 3, maxEther: 12 } },
  eclipseHarbinger: { id: 'eclipseHarbinger', name: 'Eclipse Harbinger', tier: 'ascended', baseJob: 'nullResonant', archetype: 'endgame hybrid of Resonance and Null power', primaryArmor: 'ether', unlock: { characterLevel: 18, jobLevels: { nullResonant: 6, voidcaller: 4, resonant: 4 }, flags: ['freedVaelthorn'] }, passive: { id: 'twilightResonance', description: 'Holy and Dark actions can both extend combo chains and increase Limit gain by 20%.' }, statGrowth: { hp: 12, mp: 12, strength: 3, mind: 7, speed: 3, maxTemper: 6, maxEther: 13 } },
}

export const JOB_UNLOCK_REQUIREMENTS = Object.fromEntries(
  Object.values(JOBS).map(job => [job.id, { jobId: job.id, jobName: job.name, tier: job.tier, characterLevel: job.unlock?.characterLevel ?? 1, jobLevels: job.unlock?.jobLevels ?? {}, flags: job.unlock?.flags ?? [] }]),
)

export const JOB_LEVEL_REQUIREMENT_MATRIX = Object.values(JOBS).reduce((matrix, job) => {
  Object.entries(job.unlock?.jobLevels ?? {}).forEach(([requiredJobId, requiredLevel]) => {
    matrix[requiredJobId] ??= []
    matrix[requiredJobId].push({ unlocksJobId: job.id, unlocksJobName: job.name, unlocksTier: job.tier, requiredLevel, characterLevel: job.unlock?.characterLevel ?? 1 })
  })
  return matrix
}, {})

export const ASCENDED_CLASS_PATHS = Object.values(JOBS)
  .filter(job => job.tier === 'ascended')
  .reduce((paths, job) => {
    paths[job.baseJob] = job.id
    return paths
  }, {})

export function getLevelFromXp(xp = 0) {
  return [...CHARACTER_LEVEL_TABLE].reverse().find(row => xp >= row.xp)?.level ?? 1
}

export function getXpForNextLevel(xp = 0) {
  const currentLevel = getLevelFromXp(xp)
  const next = CHARACTER_LEVEL_TABLE.find(row => row.level === currentLevel + 1)
  return next ? Math.max(0, next.xp - xp) : 0
}

export function getJobLevelFromJp(jp = 0) {
  return [...JOB_LEVEL_TABLE].reverse().find(row => jp >= row.jp)?.level ?? 0
}

export function getJpForNextJobLevel(jp = 0) {
  const currentLevel = getJobLevelFromJp(jp)
  const next = JOB_LEVEL_TABLE.find(row => row.level === currentLevel + 1)
  return next ? Math.max(0, next.jp - jp) : 0
}

export function getCharacterJobJp(character, jobId) {
  return character?.jobJp?.[jobId] ?? character?.jobLevels?.[jobId]?.jp ?? 0
}

export function getCharacterJobLevel(character, jobId) {
  return getJobLevelFromJp(getCharacterJobJp(character, jobId))
}

export function getJobProgress(character, jobId) {
  const jp = getCharacterJobJp(character, jobId)
  const level = getJobLevelFromJp(jp)
  const current = JOB_LEVEL_TABLE.find(row => row.level === level)
  const next = JOB_LEVEL_TABLE.find(row => row.level === level + 1)
  return { jobId, jobName: JOBS[jobId]?.name ?? jobId, jp, level, title: current?.title ?? 'Untrained', jpToNextLevel: getJpForNextJobLevel(jp), nextLevel: next?.level ?? null, nextTitle: next?.title ?? null, unlocksAtCurrentLevel: current?.unlocks ?? [], unlocksAtNextLevel: next?.unlocks ?? [] }
}

export function meetsJobLevelRequirements(character, jobId) {
  const job = JOBS[jobId]
  if (!job) return false
  const characterLevel = character?.level ?? getLevelFromXp(character?.xp ?? 0)
  if (characterLevel < (job.unlock?.characterLevel ?? 1)) return false
  return Object.entries(job.unlock?.jobLevels ?? {}).every(([requiredJobId, requiredLevel]) => getCharacterJobLevel(character, requiredJobId) >= requiredLevel)
}

export function meetsFlagRequirements(character, jobId) {
  const requiredFlags = JOBS[jobId]?.unlock?.flags ?? []
  const characterFlags = new Set(character?.progressionFlags ?? [])
  return requiredFlags.every(flag => characterFlags.has(flag))
}

export function canUnlockJob(character, jobId) {
  return meetsJobLevelRequirements(character, jobId) && meetsFlagRequirements(character, jobId)
}

export function getUnlockedJobs(character) {
  return Object.keys(JOBS).filter(jobId => canUnlockJob(character, jobId))
}

export function getAscendedJobs(character) {
  return getUnlockedJobs(character).filter(jobId => JOBS[jobId].tier === 'ascended')
}

export function getLockedJobRequirements(character, jobId) {
  const job = JOBS[jobId]
  if (!job) return []
  const characterLevel = character?.level ?? getLevelFromXp(character?.xp ?? 0)
  const requirements = []
  if (characterLevel < (job.unlock?.characterLevel ?? 1)) requirements.push({ type: 'characterLevel', required: job.unlock.characterLevel, current: characterLevel })
  Object.entries(job.unlock?.jobLevels ?? {}).forEach(([requiredJobId, requiredLevel]) => {
    const current = getCharacterJobLevel(character, requiredJobId)
    if (current < requiredLevel) requirements.push({ type: 'jobLevel', jobId: requiredJobId, jobName: JOBS[requiredJobId]?.name ?? requiredJobId, required: requiredLevel, current, jp: getCharacterJobJp(character, requiredJobId), jpToRequiredLevel: Math.max(0, (JOB_LEVEL_TABLE.find(row => row.level === requiredLevel)?.jp ?? 0) - getCharacterJobJp(character, requiredJobId)) })
  })
  const flags = new Set(character?.progressionFlags ?? [])
  ;(job.unlock?.flags ?? []).forEach(flag => { if (!flags.has(flag)) requirements.push({ type: 'flag', flag }) })
  return requirements
}

export function getJobUnlockPreview(character, sourceJobId) {
  const sourceProgress = getJobProgress(character, sourceJobId)
  return (JOB_LEVEL_REQUIREMENT_MATRIX[sourceJobId] ?? []).map(target => ({ ...target, isRequirementMet: sourceProgress.level >= target.requiredLevel, lockedRequirements: getLockedJobRequirements(character, target.unlocksJobId), ascendsFrom: JOBS[target.unlocksJobId]?.baseJob ?? null }))
}

export function getJobRequirementSummary(character, jobId) {
  const job = JOBS[jobId]
  if (!job) return null
  return {
    jobId,
    jobName: job.name,
    tier: job.tier,
    canUnlock: canUnlockJob(character, jobId),
    requiredCharacterLevel: job.unlock?.characterLevel ?? 1,
    requiredJobLevels: Object.entries(job.unlock?.jobLevels ?? {}).map(([requiredJobId, requiredLevel]) => ({ jobId: requiredJobId, jobName: JOBS[requiredJobId]?.name ?? requiredJobId, requiredLevel, currentLevel: getCharacterJobLevel(character, requiredJobId), jpToRequiredLevel: Math.max(0, (JOB_LEVEL_TABLE.find(row => row.level === requiredLevel)?.jp ?? 0) - getCharacterJobJp(character, requiredJobId)) })),
    requiredFlags: job.unlock?.flags ?? [],
    missingRequirements: getLockedJobRequirements(character, jobId),
  }
}

export function calculateArmorCaps(baseCaps, level, jobId) {
  const job = JOBS[jobId]
  const growth = job?.statGrowth ?? {}
  return { maxTemper: Math.round((baseCaps?.maxTemper ?? 100) + (growth.maxTemper ?? 0) * Math.max(0, level - 1)), maxEther: Math.round((baseCaps?.maxEther ?? 100) + (growth.maxEther ?? 0) * Math.max(0, level - 1)) }
}
