import { getAbility } from '../data/abilities.js'
import { findClosestReachableTile } from './pathfinding.js'
import { manhattan } from './grid.js'

// AI Strategy profiles - each defines decision-making behavior
const AI_PROFILES = {
  aggressive_bruiser: {
    // Charges enemies, prefers high-damage ability
    selectTarget: (unit, allies, enemies) => {
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy), threat: calculateThreat(enemy) }))
        .sort((a, b) => a.distance - b.distance || b.threat - a.threat)[0]?.enemy
    },
    selectAbility: (unit, target, enemies) => {
      // Prefer power_slash for burst damage
      const powerSlash = unit.abilities?.find(id => id === 'power_slash')
      if (powerSlash && (unit.mp ?? 0) >= (getAbility(powerSlash).mpCost ?? 0)) return powerSlash
      return unit.abilities?.find(id => id !== 'basic_attack') || 'basic_attack'
    },
    shouldHeal: () => false,
    description: 'Charges forward with high damage'
  },

  ranged_disruptor: {
    // Stays at range, prefers crowd control
    selectTarget: (unit, allies, enemies) => {
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy) }))
        .sort((a, b) => a.distance - b.distance)[0]?.enemy
    },
    selectAbility: (unit, target, enemies) => {
      // Prefer spark_chain for AoE disruption
      const sparkChain = unit.abilities?.find(id => id === 'spark_chain')
      if (sparkChain && (unit.mp ?? 0) >= (getAbility(sparkChain).mpCost ?? 0)) return sparkChain
      return unit.abilities?.find(id => id !== 'basic_attack') || 'basic_attack'
    },
    shouldHeal: () => false,
    description: 'Disrupts from range'
  },

  terrain_caster: {
    // Uses environmental effects, flexible targeting
    selectTarget: (unit, allies, enemies) => {
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy), threat: calculateThreat(enemy) }))
        .sort((a, b) => b.threat - a.threat)[0]?.enemy
    },
    selectAbility: (unit, target, enemies) => {
      // Cycle through spell abilities based on MP
      const spells = unit.abilities?.filter(id => id !== 'basic_attack') || []
      const available = spells.find(id => (unit.mp ?? 0) >= (getAbility(id).mpCost ?? 0))
      return available || 'basic_attack'
    },
    shouldHeal: () => false,
    description: 'Exploits terrain effects'
  },

  slow_tank: {
    // Holds position, only moves if necessary
    selectTarget: (unit, allies, enemies) => {
      // Target closest enemy
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy) }))
        .sort((a, b) => a.distance - b.distance)[0]?.enemy
    },
    selectAbility: (unit, target, enemies) => {
      // Prefer sunder_strike to break armor
      const sundering = unit.abilities?.find(id => id === 'sunder_strike')
      if (sundering && (unit.mp ?? 0) >= (getAbility(sundering).mpCost ?? 0)) return sundering
      return 'basic_attack'
    },
    shouldHeal: () => false,
    shouldMove: (unit, target) => {
      // Only move if target is out of attack range
      return manhattan(unit, target) > 1
    },
    description: 'Holds defensive position'
  },

  defensive_healer: {
    // Prioritizes ally healing over damage
    selectTarget: (unit, allies, enemies) => {
      // Check if any ally is wounded
      const woundedAlly = allies
        .filter(a => a.hp < (a.stats?.hp ?? a.hp) * 0.7)
        .sort((a, b) => (a.hp / (a.stats?.hp ?? a.hp)) - (b.hp / (b.stats?.hp ?? b.hp)))[0]

      if (woundedAlly) return woundedAlly
      // Otherwise target closest enemy
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy) }))
        .sort((a, b) => a.distance - b.distance)[0]?.enemy
    },
    selectAbility: (unit, target, allies, enemies) => {
      // If target is an ally, heal
      if (target && allies.some(a => a.id === target.id)) {
        const healAbility = unit.abilities?.find(id => id === 'curaga' || id === 'mend')
        if (healAbility && (unit.mp ?? 0) >= (getAbility(healAbility).mpCost ?? 0)) return healAbility
      }
      // If low on health, use protect
      if ((unit.hp / (unit.stats?.hp ?? unit.hp)) < 0.5) {
        const protect = unit.abilities?.find(id => id === 'protect')
        if (protect && (unit.mp ?? 0) >= (getAbility(protect).mpCost ?? 0)) return protect
      }
      return unit.abilities?.find(id => id !== 'basic_attack') || 'basic_attack'
    },
    shouldHeal: (unit, allies) => {
      return allies.some(a => a.hp < (a.stats?.hp ?? a.hp) * 0.7)
    },
    description: 'Focuses on ally healing'
  },

  aggressive_dps: {
    // All-in damage, prefers weakest target
    selectTarget: (unit, allies, enemies) => {
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy), hp: enemy.hp }))
        .sort((a, b) => a.hp - b.hp || a.distance - b.distance)[0]?.enemy
    },
    selectAbility: (unit, target, enemies) => {
      // Prefer power_slash or double_strike for burst
      const burst = unit.abilities?.find(id => id === 'double_strike' || id === 'power_slash')
      if (burst && (unit.mp ?? 0) >= (getAbility(burst).mpCost ?? 0)) return burst
      return unit.abilities?.find(id => id !== 'basic_attack') || 'basic_attack'
    },
    shouldHeal: () => false,
    description: 'High-risk physical damage dealer'
  },

  spell_focused: {
    // Prioritizes spell usage over physical
    selectTarget: (unit, allies, enemies) => {
      return enemies
        .map((enemy) => ({ enemy, distance: manhattan(unit, enemy), threat: calculateThreat(enemy) }))
        .sort((a, b) => b.threat - a.threat || a.distance - b.distance)[0]?.enemy
    },
    selectAbility: (unit, target, enemies) => {
      // Prefer elemental spells
      const spells = unit.abilities?.filter(id => ['firaga', 'inferno', 'flare', 'blizzaga'].includes(id)) || []
      const available = spells.find(id => (unit.mp ?? 0) >= (getAbility(id).mpCost ?? 0))
      if (available) return available
      return unit.abilities?.find(id => id !== 'basic_attack') || 'basic_attack'
    },
    shouldHeal: () => false,
    description: 'Elemental spell specialist'
  }
}

/**
 * Calculate threat level for a unit (used for targeting priority)
 * Higher HP and damage = higher threat
 */
function calculateThreat(unit) {
  const hpComponent = unit.hp / (unit.stats?.hp ?? unit.hp)
  const damageComponent = (unit.stats?.physical ?? 0) + (unit.stats?.magic ?? 0)
  return (hpComponent * 0.3) + (damageComponent * 0.7)
}

/**
 * Choose the best enemy action, ensuring it matches the intent preview
 * CRITICAL: This function must be deterministic and match previewEnemyIntent exactly
 */
export function chooseEnemyAction({ map, grid, units, unit }) {
  const allies = units.filter((u) => u.team === unit.team && u.hp > 0 && u.id !== unit.id)
  const enemies = units.filter((candidate) => candidate.team !== unit.team && candidate.hp > 0)

  if (!enemies.length) return { type: 'wait', unitId: unit.id }

  const profile = AI_PROFILES[unit.aiProfile] || AI_PROFILES.aggressive_bruiser
  let target = profile.selectTarget(unit, allies, enemies)

  if (!target) return { type: 'wait', unitId: unit.id }

  // Check if healer should heal instead
  if (profile.shouldHeal && profile.shouldHeal(unit, allies)) {
    target = profile.selectTarget(unit, allies, enemies) // Re-select to get ally if available
  }

  // Select ability based on target type (ability vs heal)
  const isHealingAlly = allies.some(a => a.id === target.id)
  const ability = profile.selectAbility(unit, target, enemies, allies)
  const abilityObj = getAbility(ability)

  if (!abilityObj) return { type: 'wait', unitId: unit.id }

  // Check if in range
  const distance = manhattan(unit, target)
  const maxRange = abilityObj.range?.max ?? abilityObj.range ?? 1
  const inRange = distance <= maxRange

  if (inRange) {
    return { type: 'ability', unitId: unit.id, abilityId: ability, targetUnitId: target.id }
  }

  // Try to move into range
  if (!profile.shouldMove || profile.shouldMove(unit, target)) {
    const move = findClosestReachableTile({ map, grid, units, unit, target })
    if (move) {
      return { type: 'move', unitId: unit.id, to: { x: move.tile.x, y: move.tile.y }, path: move.path }
    }
  }

  return { type: 'wait', unitId: unit.id }
}

/**
 * Preview what enemy WILL do - MUST MATCH chooseEnemyAction exactly
 * This is critical for player trust in the UI
 */
export function previewEnemyIntent({ map, grid, units, unit }) {
  const action = chooseEnemyAction({ map, grid, units, unit })

  if (action.type === 'ability') {
    const ability = getAbility(action.abilityId)
    const target = units.find((candidate) => candidate.id === action.targetUnitId)
    const profile = AI_PROFILES[unit.aiProfile]

    // Determine if this is a heal or attack
    const isHealing = unit.team === target?.team
    const actionLabel = isHealing
      ? `${unit.name} will cast ${ability.name} on ${target?.name}`
      : `${unit.name} will cast ${ability.name} on ${target?.name}`

    return {
      unitId: unit.id,
      label: actionLabel,
      action,
      targetUnitId: target?.id,
      threatenedTiles: target ? [{ x: target.x, y: target.y }] : [],
      strategyHint: profile?.description
    }
  }

  if (action.type === 'move') {
    return {
      unitId: unit.id,
      label: `${unit.name} is advancing`,
      action,
      threatenedTiles: [action.to],
      strategyHint: 'Moving into attack range'
    }
  }

  return { unitId: unit.id, label: `${unit.name} is waiting`, action, threatenedTiles: [], strategyHint: 'No valid action' }
}

/**
 * Validation function - ensures intent preview matches actual action
 * Call this in development to catch intent mismatches
 */
export function validateEnemyIntent({ map, grid, units, unit }) {
  const intent = previewEnemyIntent({ map, grid, units, unit })
  const action = chooseEnemyAction({ map, grid, units, unit })

  const matches = {
    type: intent.action.type === action.type,
    abilityId: intent.action.abilityId === action.abilityId,
    targetUnitId: intent.action.targetUnitId === action.targetUnitId,
    destination: !action.to || (intent.action.to?.x === action.to.x && intent.action.to?.y === action.to.y)
  }

  const isValid = Object.values(matches).every(Boolean)

  if (!isValid) {
    console.warn(`❌ Intent mismatch for ${unit.name}:`, {
      unit: unit.id,
      intent: intent.action,
      actual: action,
      matches
    })
  }

  return { isValid, matches, intent, action }
}
