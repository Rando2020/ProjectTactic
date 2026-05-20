import { PREFIXES, SUFFIXES, ELITE_TIERS, PREFIX_LIST, SUFFIX_LIST } from '../data/eliteAffixes.js'

function seededRng(seed) {
  let s = (seed >>> 0) || 1
  return () => { s = Math.imul(s, 1664525) + 1013904223 | 0; return (s >>> 0) / 4294967296 }
}

export const FLOOR_ELITE_RATES = [
  { normal:0.70, marked:0.18, elite:0.09, champion:0.03 },
  { normal:0.55, marked:0.25, elite:0.15, champion:0.05 },
  { normal:0.35, marked:0.30, elite:0.25, champion:0.10 },
  { normal:0.10, marked:0.30, elite:0.40, champion:0.20 },
]
export const BOSS_ELITE_RATES = { normal:0, marked:0, elite:0.30, champion:0.70 }

export function getEliteRatesForFloor(floor = 1, isBoss = false) {
  if (isBoss) return BOSS_ELITE_RATES
  return FLOOR_ELITE_RATES[Math.min(floor - 1, FLOOR_ELITE_RATES.length - 1)]
}

export function rollElite(unit, seed, ratesOverride = null) {
  const rng   = seededRng(seed)
  const rates = ratesOverride ?? FLOOR_ELITE_RATES[0]
  const r     = rng()
  let tier = 'normal'
  if (r < rates.champion)                                              tier = 'champion'
  else if (r < rates.champion + rates.elite)                           tier = 'elite'
  else if (r < rates.champion + rates.elite + rates.marked)            tier = 'marked'
  if (tier === 'normal') return unit

  const tierDef   = ELITE_TIERS[tier]
  const numPre    = tier === 'champion' ? 2 : 1
  const numSuf    = tier === 'marked'   ? 0 : 1
  const shuffled  = [...PREFIX_LIST].sort(() => rng() - 0.5)
  const prefixes  = shuffled.slice(0, numPre).map(id => PREFIXES[id])
  const suffixes  = numSuf > 0 ? [SUFFIXES[SUFFIX_LIST[Math.floor(rng() * SUFFIX_LIST.length)]]] : []

  const prefixLabels = prefixes.map(p => p.label).join(' ')
  const suffixLabel  = suffixes.length ? ` ${suffixes[0].label}` : ''
  const eliteName    = `${prefixLabels} ${unit.name}${suffixLabel}`.trim()

  let modified = {
    ...unit, name: eliteName, eliteTier: tier, eliteColor: tierDef.color,
    jpMult: (unit.jpMult ?? 1) * tierDef.jpMult, prefixes, suffixes,
  }
  modified.hp     = Math.round((unit.hp     ?? unit.stats?.hp     ?? 100) * tierDef.hpMult)
  modified.temper = Math.round((unit.temper ?? unit.stats?.temper ?? 50)  * tierDef.hpMult)
  modified.ether  = Math.round((unit.ether  ?? unit.stats?.ether  ?? 50)  * tierDef.hpMult)
  for (const p of prefixes) {
    const m = p.statMods ?? {}
    if (m.hpMult)        modified.hp     = Math.round(modified.hp * m.hpMult)
    if (m.damageMult)    modified.damageMult   = (modified.damageMult ?? 1) * m.damageMult
    if (m.statusImmune)  modified.statusImmune = true
    if (m.dodgeChance)   modified.dodgeChance  = m.dodgeChance
    if (m.immunities)    modified.immunities   = [...(modified.immunities ?? []), ...m.immunities]
  }
  return modified
}

export function applyEliteRollsForFloor(units, runSeed = 0, floor = 1, isBoss = false) {
  const rates = getEliteRatesForFloor(floor, isBoss)
  return units.map((unit, index) => {
    if (unit.team !== 'enemy') return unit
    return rollElite(unit, (runSeed * 31 + index * 7919) >>> 0, rates)
  })
}

export function getEliteSummary(unit) {
  if (!unit.eliteTier) return null
  return {
    tier: unit.eliteTier, tierLabel: ELITE_TIERS[unit.eliteTier].label,
    tierColor: ELITE_TIERS[unit.eliteTier].color,
    affixes: [
      ...(unit.prefixes ?? []).map(p => ({ label:p.label, color:p.color, description:p.description })),
      ...(unit.suffixes ?? []).map(s => ({ label:s.label, color:s.color, description:s.description })),
    ],
  }
}
