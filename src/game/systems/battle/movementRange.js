import { getAdjacentTiles, getTile, isTileBlocked, keyOf } from '../grid.js'

function getMoveStat(unit) {
  return unit.stats?.move ?? unit.move ?? 3
}

function getJumpStat(unit) {
  return unit.stats?.jump ?? unit.jump ?? 1
}

function getTerrainCost(tile) {
  return tile?.terrainDef?.moveCost ?? tile?.terrainDef?.cost ?? 1
}

function canTraverseHeight(fromTile, toTile, unit) {
  if (!fromTile || !toTile) return false
  return Math.abs((toTile.height ?? 0) - (fromTile.height ?? 0)) <= getJumpStat(unit)
}

export function getMovementRange({ map, grid, units, unit }) {
  if (!map || !grid || !unit || unit.hp <= 0) return []

  const origin = getTile(grid, unit.x, unit.y)
  if (!origin) return []

  const maxMove = getMoveStat(unit)
  const visited = new Map()
  const queue = [{ tile: origin, remainingMove: maxMove, path: [] }]
  visited.set(keyOf(origin.x, origin.y), { tile: origin, remainingMove: maxMove, path: [] })

  while (queue.length) {
    const current = queue.shift()
    const neighbors = getAdjacentTiles(map, grid, current.tile)

    neighbors.forEach((neighbor) => {
      if (!canTraverseHeight(current.tile, neighbor, unit)) return
      if (isTileBlocked(neighbor, units, unit.id)) return

      const cost = getTerrainCost(neighbor)
      const remainingMove = current.remainingMove - cost
      if (remainingMove < 0) return

      const key = keyOf(neighbor.x, neighbor.y)
      const previous = visited.get(key)
      if (previous && previous.remainingMove >= remainingMove) return

      const nextPath = [...current.path, { x: neighbor.x, y: neighbor.y }]
      const next = { tile: neighbor, remainingMove, path: nextPath }
      visited.set(key, next)
      queue.push(next)
    })
  }

  return [...visited.values()]
    .filter((entry) => !(entry.tile.x === origin.x && entry.tile.y === origin.y))
    .map((entry) => ({
      ...entry.tile,
      remainingMove: entry.remainingMove,
      path: entry.path,
    }))
}

export function isTileInMovementRange(range = [], tile) {
  if (!tile) return false
  return range.some((entry) => entry.x === tile.x && entry.y === tile.y)
}
