import { getTile, manhattan } from './grid.js'

export function normalizeRange(ability) {
  if (!ability?.range) return { min: 1, max: 1, shape: 'single', heightTolerance: 1 }
  if (typeof ability.range === 'number') return { min: 1, max: ability.range, shape: 'single', heightTolerance: 2 }
  return { min: ability.range.min ?? 0, max: ability.range.max ?? 1, shape: ability.range.shape ?? 'single', heightTolerance: ability.range.heightTolerance ?? 2 }
}

export function isTileInAbilityRange({ caster, casterTile, targetTile, ability }) {
  if (!caster || !targetTile || !ability) return false
  const range = normalizeRange(ability)
  const distance = manhattan(casterTile || caster, targetTile)
  const heightDelta = Math.abs((targetTile.height ?? 0) - ((casterTile || caster).height ?? 0))
  return distance >= range.min && distance <= range.max && heightDelta <= range.heightTolerance
}

export function getTargetableTiles({ map, grid, caster, ability }) {
  const casterTile = getTile(grid, caster.x, caster.y)
  return grid.filter((targetTile) => isTileInAbilityRange({ caster, casterTile, targetTile, ability }))
}

export function getAreaTiles({ grid, centerTile, ability }) {
  const range = normalizeRange(ability)
  const radius = ability?.area?.radius ?? 0
  if (!centerTile) return []
  if (radius <= 0 || range.shape === 'single') return [centerTile]
  return grid.filter((tile) => manhattan(tile, centerTile) <= radius)
}

export function getUnitsInArea({ units, areaTiles }) {
  const keys = new Set(areaTiles.map((tile) => `${tile.x},${tile.y}`))
  return units.filter((unit) => unit.hp > 0 && keys.has(`${unit.x},${unit.y}`))
}

export function isValidTargetForAbility({ caster, targetUnit, targetTile, ability }) {
  if (!ability) return false
  if (ability.target === 'enemy') return Boolean(targetUnit && targetUnit.team !== caster.team)
  if (ability.target === 'ally') return Boolean(targetUnit && targetUnit.team === caster.team)
  if (ability.target === 'self') return Boolean(targetUnit && targetUnit.id === caster.id)
  if (ability.target === 'enemy_or_tile') return Boolean(targetTile)
  if (ability.target === 'objective') return Boolean(targetTile?.terrain === 'void_anchor' || targetTile?.tags?.includes('objective'))
  return Boolean(targetUnit || targetTile)
}
