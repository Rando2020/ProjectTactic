import { getAbility } from '../data/abilities.js'
import { findClosestReachableTile } from './pathfinding.js'
import { manhattan } from './grid.js'

export function chooseEnemyAction({ map, grid, units, unit }) {
  const livingPlayers = units.filter((candidate) => candidate.team === 'player' && candidate.hp > 0)
  if (!livingPlayers.length) return { type: 'wait', unitId: unit.id }

  const preferredAbility = chooseAbilityForEnemy(unit)
  const ability = getAbility(preferredAbility)
  const target = livingPlayers
    .map((player) => ({ player, distance: manhattan(unit, player) }))
    .sort((a, b) => a.distance - b.distance || a.player.hp - b.player.hp)[0]?.player

  if (!target) return { type: 'wait', unitId: unit.id }

  const inRange = manhattan(unit, target) <= (ability.range?.max ?? ability.range ?? 1)
  if (inRange) {
    return { type: 'ability', unitId: unit.id, abilityId: ability.id, targetUnitId: target.id }
  }

  const move = findClosestReachableTile({ map, grid, units, unit, target })
  if (move) {
    return { type: 'move', unitId: unit.id, to: { x: move.tile.x, y: move.tile.y }, path: move.path }
  }

  return { type: 'wait', unitId: unit.id }
}

export function previewEnemyIntent({ map, grid, units, unit }) {
  const action = chooseEnemyAction({ map, grid, units, unit })
  if (action.type === 'ability') {
    const ability = getAbility(action.abilityId)
    const target = units.find((candidate) => candidate.id === action.targetUnitId)
    return {
      unitId: unit.id,
      label: `${unit.name} plans ${ability.name}`,
      action,
      targetUnitId: target?.id,
      threatenedTiles: target ? [{ x: target.x, y: target.y }] : []
    }
  }
  if (action.type === 'move') {
    return {
      unitId: unit.id,
      label: `${unit.name} is advancing`,
      action,
      threatenedTiles: [action.to]
    }
  }
  return { unitId: unit.id, label: `${unit.name} is waiting`, action, threatenedTiles: [] }
}

function chooseAbilityForEnemy(unit) {
  const preferred = unit.abilities?.find((abilityId) => abilityId !== 'basic_attack')
  if (preferred && (unit.mp ?? 0) >= (getAbility(preferred).mpCost ?? 0)) return preferred
  return 'basic_attack'
}
