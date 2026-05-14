import { getAdjacentTiles, isTileBlocked, keyOf } from './grid.js'

export function getReachableTiles({ map, grid, units, unit }) {
  const start = grid.find((tile) => tile.x === unit.x && tile.y === unit.y)
  if (!start) return []

  const frontier = [{ tile: start, cost: 0, path: [] }]
  const visited = new Map([[keyOf(start.x, start.y), { tile: start, cost: 0, path: [] }]])

  while (frontier.length) {
    frontier.sort((a, b) => a.cost - b.cost)
    const current = frontier.shift()

    for (const next of getAdjacentTiles(map, grid, current.tile)) {
      if (isTileBlocked(next, units, unit.id)) continue
      const heightDelta = Math.abs((next.height || 0) - (current.tile.height || 0))
      if (heightDelta > (unit.jump || 1)) continue

      const moveCost = next.terrainDef.moveCost || 1
      const newCost = current.cost + moveCost + Math.max(0, heightDelta - 1)
      if (newCost > unit.move) continue

      const key = keyOf(next.x, next.y)
      const existing = visited.get(key)
      if (!existing || newCost < existing.cost) {
        const entry = { tile: next, cost: newCost, path: [...current.path, next] }
        visited.set(key, entry)
        frontier.push(entry)
      }
    }
  }

  return [...visited.values()].filter((entry) => !(entry.tile.x === start.x && entry.tile.y === start.y))
}

export function getThreatenedTiles({ map, grid, units, unit, ability }) {
  const range = ability?.range ?? 1
  return grid.filter((tile) => {
    const distance = Math.abs(tile.x - unit.x) + Math.abs(tile.y - unit.y)
    if (distance > range) return false
    const heightDelta = Math.abs((tile.height || 0) - (grid.find((t) => t.x === unit.x && t.y === unit.y)?.height || 0))
    return heightDelta <= (ability?.heightTolerance ?? 2)
  })
}

export function findClosestReachableTile({ map, grid, units, unit, target }) {
  const reachable = getReachableTiles({ map, grid, units, unit })
  if (!reachable.length) return null

  return reachable
    .map((entry) => ({ ...entry, distance: Math.abs(entry.tile.x - target.x) + Math.abs(entry.tile.y - target.y) }))
    .sort((a, b) => a.distance - b.distance || a.cost - b.cost)[0]
}
