/**
 * Mystery Events - Hidden encounters that reveal when entered
 * These create variety and surprise in roguelike runs
 *
 * Can be: treasure cache, ambush, blessing, trap, etc.
 * Percentage weights shift throughout the run to encourage risk-taking
 */

export const MYSTERY_EVENT_TYPES = {
  // POSITIVE OUTCOMES (improve chances on deeper floors)
  treasure_cache: {
    id: 'treasure_cache',
    name: 'Treasure Cache',
    description: 'A hidden stash of valuables',
    icon: '💰',
    color: { border: 'rgba(251,191,36,.45)', bg: 'rgba(251,191,36,.08)' },
    outcome: 'Gain significant gold and rare items',
    reward: { goldMultiplier: 1.5, items: 2 }
  },
  blessed_shrine: {
    id: 'blessed_shrine',
    name: 'Blessed Shrine',
    description: 'Holy ground radiating power',
    icon: '✨',
    color: { border: 'rgba(56,189,248,.45)', bg: 'rgba(56,189,248,.08)' },
    outcome: 'Grants a free Guardian boon',
    reward: { freeBoon: true, healing: 0.25 }
  },
  guardian_gift: {
    id: 'guardian_gift',
    name: 'Guardian Gift',
    description: 'A freed Guardian leaves behind a blessing',
    icon: '⭐',
    color: { border: 'rgba(168,85,247,.5)', bg: 'rgba(168,85,247,.1)' },
    outcome: 'All party members heal and gain temporary buffs',
    reward: { healing: 0.5, buffs: ['haste', 'protect'] }
  },
  merchant_caravan: {
    id: 'merchant_caravan',
    name: 'Merchant Caravan',
    description: 'Traveling traders offer wares',
    icon: '🏪',
    color: { border: 'rgba(134,239,172,.25)', bg: 'rgba(134,239,172,.08)' },
    outcome: 'Access to special equipment at discount',
    reward: { shop: true, discount: 0.2 }
  },

  // NEUTRAL OUTCOMES (constant throughout)
  abandoned_camp: {
    id: 'abandoned_camp',
    name: 'Abandoned Camp',
    description: 'Signs of recent travelers',
    icon: '⛺',
    color: { border: 'rgba(255,255,255,.18)', bg: 'rgba(255,255,255,.06)' },
    outcome: 'Small cache of supplies, no combat',
    reward: { gold: 50, items: 1 }
  },
  old_ruins: {
    id: 'old_ruins',
    name: 'Ancient Ruins',
    description: 'Crumbling stone structures',
    icon: '🏛️',
    color: { border: 'rgba(255,255,255,.18)', bg: 'rgba(255,255,255,.06)' },
    outcome: 'Explore for modest treasure or rest',
    reward: { gold: 75, healing: 0.15 }
  },

  // NEGATIVE OUTCOMES (more likely on early floors)
  ambush: {
    id: 'ambush',
    name: 'Ambush!',
    description: 'Enemies emerge from the shadows',
    icon: '⚔️',
    color: { border: 'rgba(248,113,113,.45)', bg: 'rgba(248,113,113,.08)' },
    outcome: 'Unexpected battle against tough foes',
    threat: 'elite_battle'
  },
  trap_corridor: {
    id: 'trap_corridor',
    name: 'Trap Corridor',
    description: 'Dangerous mechanisms lie ahead',
    icon: '💣',
    color: { border: 'rgba(248,113,113,.45)', bg: 'rgba(248,113,113,.08)' },
    outcome: 'Party takes damage from environmental hazards',
    penalty: { damage: 0.2 }
  },
  curse_site: {
    id: 'curse_site',
    name: 'Cursed Ground',
    description: 'Dark energy emanates from this place',
    icon: '💀',
    color: { border: 'rgba(194,97,254,.4)', bg: 'rgba(194,97,254,.08)' },
    outcome: 'Party members gain negative status effects',
    penalty: { statuses: ['curse', 'slow'] }
  },
  mimic_hoard: {
    id: 'mimic_hoard',
    name: 'Mimic Hoard',
    description: 'Treasure that might bite back',
    icon: '😈',
    color: { border: 'rgba(248,113,113,.45)', bg: 'rgba(248,113,113,.08)' },
    outcome: 'Battle against shape-shifters for loot',
    threat: 'battle'
  }
}

/**
 * Get mystery event outcome for current floor
 * Positive events more likely on deeper floors (risk/reward)
 * Negative events more likely on early floors
 */
export function getMysteryEvent(floorNum, rng, maxFloor = 10) {
  const floorProgress = floorNum / maxFloor

  // Weight pools based on floor progression
  const positive = [
    { id: 'treasure_cache', weight: 6 + Math.floor(floorProgress * 4) },
    { id: 'blessed_shrine', weight: 4 + Math.floor(floorProgress * 3) },
    { id: 'guardian_gift', weight: 2 + Math.floor(floorProgress * 2) },
    { id: 'merchant_caravan', weight: 3 + Math.floor(floorProgress * 1) }
  ]

  const neutral = [
    { id: 'abandoned_camp', weight: 5 },
    { id: 'old_ruins', weight: 5 }
  ]

  const negative = [
    { id: 'ambush', weight: 8 - Math.floor(floorProgress * 3) },
    { id: 'trap_corridor', weight: 6 - Math.floor(floorProgress * 2) },
    { id: 'curse_site', weight: 4 - Math.floor(floorProgress * 1) },
    { id: 'mimic_hoard', weight: 5 - Math.floor(floorProgress * 2) }
  ]

  // Build weighted pool
  const pool = [
    ...positive.flatMap(e => Array(Math.max(0, e.weight)).fill(e.id)),
    ...neutral.flatMap(e => Array(Math.max(0, e.weight)).fill(e.id)),
    ...negative.flatMap(e => Array(Math.max(0, e.weight)).fill(e.id))
  ]

  const eventId = pool[Math.floor(rng() * pool.length)]
  return MYSTERY_EVENT_TYPES[eventId]
}

/**
 * Resolve mystery event outcomes
 * Called when player enters the mystery node
 */
export function resolveMysteryEvent(eventId, gameState) {
  const event = MYSTERY_EVENT_TYPES[eventId]
  if (!event) return gameState

  // Handle different event types
  if (event.reward) {
    // Positive event
    let updated = gameState

    if (event.reward.goldMultiplier) {
      updated = {
        ...updated,
        activeRun: {
          ...updated.activeRun,
          runGold: Math.floor((updated.activeRun?.runGold ?? 0) * event.reward.goldMultiplier)
        }
      }
    }

    if (event.reward.freeBoon) {
      // Trigger boon pick screen instead of advancing
      updated = {
        ...updated,
        currentScreen: 'boonPick',
        _mysteryRewardBoon: true
      }
    }

    if (event.reward.healing && updated.party) {
      updated = {
        ...updated,
        party: updated.party.map(u => ({
          ...u,
          hp: Math.min(u.hp_max ?? u.hp, Math.ceil(u.hp + (u.hp_max ?? u.hp) * event.reward.healing))
        }))
      }
    }

    return updated
  }

  if (event.threat) {
    // Battle event - transition to battle screen
    return {
      ...gameState,
      currentScreen: 'deployment',
      _mysteryBattleType: event.threat
    }
  }

  if (event.penalty) {
    // Negative event
    let updated = gameState

    if (event.penalty.damage && updated.party) {
      updated = {
        ...updated,
        party: updated.party.map(u => ({
          ...u,
          hp: Math.max(1, u.hp - Math.ceil((u.hp_max ?? u.hp) * event.penalty.damage))
        }))
      }
    }

    if (event.penalty.statuses && updated.party) {
      // Would need to apply status effects here
      // For now just show a warning message
      updated = {
        ...updated,
        _mysteryPenalty: event.penalty
      }
    }

    return updated
  }

  return gameState
}
