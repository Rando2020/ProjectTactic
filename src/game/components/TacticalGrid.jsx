import { useMemo } from 'react'
import { buildGrid, getTile, getAdjacentTiles, getUnitAt, keyOf } from '../systems/grid.js'
import { getReachableTiles } from '../systems/pathfinding.js'

const TERRAIN_CLASSES = {
  grass: 'terrain-grass',
  road: 'terrain-road',
  stone: 'terrain-stone',
  shrine: 'terrain-shrine',
  shallow_water: 'terrain-shallow-water',
  deep_water: 'terrain-deep-water',
  ice: 'terrain-ice',
  burning: 'terrain-burning',
  wall: 'terrain-wall',
  high_ground: 'terrain-high-ground',
}

function getFacingGlyph(facing) {
  return { N: '↑', E: '→', S: '↓', W: '←' }[facing] ?? '•'
}

export default function TacticalGrid({
  map,
  units,
  selectedUnitId,
  activeCommand,
  onSelectUnit,
  onSelectMoveTile,
  onSelectAttackTarget,
  showCoordinates = true,
}) {
  const grid = useMemo(() => buildGrid(map), [map])
  const selectedUnit = units.find((unit) => unit.id === selectedUnitId)

  const adjacentTiles = useMemo(() => {
    if (!selectedUnit) return []
    const origin = getTile(grid, selectedUnit.x, selectedUnit.y)
    if (!origin) return []
    return getAdjacentTiles(map, grid, origin)
  }, [grid, map, selectedUnit])

  const movementEntries = useMemo(() => {
    if (activeCommand !== 'move' || !selectedUnit) return []
    return getReachableTiles({ map, grid, units, unit: selectedUnit })
  }, [activeCommand, grid, map, selectedUnit, units])

  const moveEntriesByKey = new Map(movementEntries.map((entry) => [keyOf(entry.tile.x, entry.tile.y), entry]))
  const attackTargetIds = new Set(
    activeCommand === 'attack'
      ? adjacentTiles
          .map((tile) => getUnitAt(units, tile.x, tile.y))
          .filter((unit) => unit && unit.team === 'enemy')
          .map((unit) => unit.id)
      : []
  )

  function handleTileClick(tile) {
    const unit = getUnitAt(units, tile.x, tile.y)
    if (unit) {
      if (attackTargetIds.has(unit.id)) {
        onSelectAttackTarget?.(unit.id)
        return
      }
      onSelectUnit?.(unit.id)
      return
    }

    const moveEntry = moveEntriesByKey.get(keyOf(tile.x, tile.y))
    if (moveEntry) {
      onSelectMoveTile?.(tile, moveEntry)
    }
  }

  return (
    <div className="tactics-board-shell">
      <div className="tactics-board-scroll">
        <div
          className="iso-board"
          style={{
            '--map-width': map.size.width,
            '--map-height': map.size.height,
          }}
        >
          {grid.map((tile) => {
            const unit = getUnitAt(units, tile.x, tile.y)
            const tileKey = keyOf(tile.x, tile.y)
            const selected = unit?.id === selectedUnitId
            const moveEntry = moveEntriesByKey.get(tileKey)
            const highlighted = Boolean(moveEntry)
            const targetable = unit && attackTargetIds.has(unit.id)
            const terrainClass = TERRAIN_CLASSES[tile.terrain] ?? 'terrain-grass'

            return (
              <button
                key={tileKey}
                type="button"
                className={[
                  'iso-tile',
                  terrainClass,
                  selected ? 'is-selected' : '',
                  highlighted ? 'is-move-target' : '',
                  targetable ? 'is-attack-target' : '',
                  unit ? `has-${unit.team}` : '',
                ].filter(Boolean).join(' ')}
                style={{
                  '--tile-x': tile.x,
                  '--tile-y': tile.y,
                  '--tile-height': tile.height ?? 0,
                }}
                onClick={() => handleTileClick(tile)}
                title={`${tile.terrainDef.name} h${tile.height}`}
              >
                <span className="iso-tile-face" />
                <span className="iso-tile-height">h{tile.height}</span>
                {showCoordinates && <span className="iso-coords">{tile.x},{tile.y}</span>}
                {highlighted && <span className="iso-move-cost">{moveEntry.remaining}</span>}
                {unit && (
                  <span className="iso-unit-token">
                    <span>{unit.team === 'player' ? '◆' : '◇'}</span>
                    <strong>{unit.name.split(' ')[0]}</strong>
                    <em>{getFacingGlyph(unit.facing)}</em>
                  </span>
                )}
              </button>
            )
          })}
        </div>
      </div>
      <p className="muted">
        Select a player unit, choose Move or Attack, then click a highlighted tile or enemy target. Move highlights now use unit move, terrain cost, blocking, and jump limits.
      </p>
    </div>
  )
}
