import { getAbility } from '../data/abilities.js'
import { getTerrainReaction } from '../data/terrain.js'
import { getTile } from './grid.js'
import { calculateDamagePreview, applyDamagePreview } from './damageFormula.js'

export function resolveAbilityUse({ units, grid, attackerId, abilityId, targetUnitId = null, targetCoord = null }) {
  const attacker = units.find((unit) => unit.id === attackerId)
  const ability = getAbility(abilityId)
  const targetUnit = targetUnitId ? units.find((unit) => unit.id === targetUnitId) : null
  const targetTile = targetCoord ? getTile(grid, targetCoord.x, targetCoord.y) : targetUnit ? getTile(grid, targetUnit.x, targetUnit.y) : null

  if (!attacker || !ability) {
    return { units, events: [{ type: 'error', message: 'No attacker or ability found.' }] }
  }

  if ((attacker.mp ?? 0) < (ability.mpCost ?? 0)) {
    return { units, events: [{ type: 'error', message: `${attacker.name} does not have enough MP.` }] }
  }

  const preview = calculateDamagePreview({ attacker, defender: targetUnit, ability, targetTile })
  const events = [{ type: 'ability_used', attackerId, abilityId, targetUnitId, targetCoord, preview }]

  let nextUnits = units.map((unit) => {
    if (unit.id === attackerId) return { ...unit, mp: Math.max(0, (unit.mp ?? 0) - (ability.mpCost ?? 0)) }
    if (targetUnit && unit.id === targetUnit.id) return applyDamagePreview(unit, preview)
    return unit
  })

  nextUnits = applySupportEffects(nextUnits, targetUnit, ability)

  const terrainReaction = targetTile ? getTerrainReaction(targetTile.terrain, ability.element) : null
  if (terrainReaction) {
    events.push({ type: 'terrain_reaction', reaction: terrainReaction, tile: targetTile, element: ability.element })
  }

  for (const effect of ability.effects || []) {
    if (effect.type === 'status' && targetUnit) {
      events.push({ type: 'status_attempt', targetUnitId: targetUnit.id, status: effect.status, chance: effect.chance, turns: effect.turns })
    }
    if (effect.type === 'shatter_void_anchor') {
      events.push({ type: 'objective_progress', objective: 'resolve_void_anchor', tile: targetTile })
    }
  }

  return { units: nextUnits, events }
}

function applySupportEffects(units, targetUnit, ability) {
  if (!targetUnit) return units
  return units.map((unit) => {
    if (unit.id !== targetUnit.id) return unit
    let next = { ...unit }
    for (const effect of ability.effects || []) {
      if (effect.type === 'restore_temper') next.temper = Math.min(next.stats.temper, (next.temper ?? 0) + effect.amount)
      if (effect.type === 'restore_ether') next.ether = Math.min(next.stats.ether, (next.ether ?? 0) + effect.amount)
      if (effect.type === 'status') next.statuses = [...(next.statuses || []), { id: effect.status, turns: effect.turns ?? 1 }]
    }
    return next
  })
}

export function checkBattleObjective({ map, units }) {
  if (map.objective?.type === 'defeat_all') {
    const enemiesAlive = units.some((unit) => unit.team === 'enemy' && unit.hp > 0)
    const playersAlive = units.some((unit) => unit.team === 'player' && unit.hp > 0)
    if (!playersAlive) return { complete: true, result: 'defeat' }
    if (!enemiesAlive) return { complete: true, result: 'victory', rewards: map.rewards }
  }
  return { complete: false, result: 'ongoing' }
}
