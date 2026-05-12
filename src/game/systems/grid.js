import { getTerrain } from '../data/terrain.js'

export const DIRECTIONS = {
  N: { x: 0, y: -1 },
  E: { x: 1, y: 0 },
  S: { x: 0, y: 1 },
  W: { x: -1, y: 0 }
}

export const keyOf = (x, y) => `${x},${y}`

export function buildGrid(map) {
  const tileOverrides = new Map((map.tiles || []).map((tile) => [keyOf(tile.x, tile.y), tile]))
  const tiles = []

  for (let y = 0; y < map.size.height; y += 1) {
    for (let x = 0; x < map.size.width; x += 1) {
      const override = tileOverrides.get(keyOf(x, y)) || {}
      const terrainId = override.terrain || map.defaultTerrain || 'grass'
      tiles.push({
        x,
        y,
        height: override.height ?? 0,
        terrain: terrainId,
        terrainDef: getTerrain(terrainId),
        state: override.state || null
      })
    }
  }

  return tiles
}

export function getTile(grid, x, y) {
  return grid.find((tile) => tile.x === x && tile.y === y)
}

export function isInsideMap(map, x, y) {
  return x >= 0 && y >= 0 && x < map.size.width && y < map.size.height
}

export function getAdjacentTiles(map, grid, tile) {
  return Object.values(DIRECTIONS)
    .map((dir) => ({ x: tile.x + dir.x, y: tile.y + dir.y }))
    .filter((pos) => isInsideMap(map, pos.x, pos.y))
    .map((pos) => getTile(grid, pos.x, pos.y))
    .filter(Boolean)
}

export function getUnitAt(units, x, y) {
  return units.find((unit) => unit.hp > 0 && unit.x === x && unit.y === y)
}

export function isTileBlocked(tile, units = [], ignoreUnitId = null) {
  if (!tile || tile.terrainDef.blocked) return true
  return units.some((unit) => unit.id !== ignoreUnitId && unit.hp > 0 && unit.x === tile.x && unit.y === tile.y)
}

export function manhattan(a, b) {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y)
}

export function facingFromDelta(dx, dy) {
  if (Math.abs(dx) > Math.abs(dy)) return dx > 0 ? 'E' : 'W'
  return dy > 0 ? 'S' : 'N'
}

export function getFacingAfterMove(from, to) {
  return facingFromDelta(to.x - from.x, to.y - from.y)
}
