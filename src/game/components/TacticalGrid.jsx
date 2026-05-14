import { useMemo } from 'react'
import { buildGrid, getTile, getAdjacentTiles, getUnitAt, isTileBlocked } from '../systems/grid.js'

const TERRAIN_COLORS = {
  grass: '#244733',
  road: '#6b5131',
  stone: '#4b5563',
  shrine: '#68512a',
  shallow_water: '#155e75',
  deep_water: '#0f2942',
  ice: '#8ecae6',
  burning: '#7f1d1d',
  wall: '#111827',
  high_ground: '#374151',
}

function getTileStyle(tile, selected, highlighted, targetable, abilityTargetable) {
  return {
    position: 'relative',
    minHeight: 58,
    border: selected
      ? '2px solid #facc15'
      : targetable
        ? '2px solid #f97316'
        : abilityTargetable
          ? '2px solid #a78bfa'
          : highlighted
            ? '2px solid #67e8f9'
            : '1px solid rgba(255,255,255,.12)',
    background: TERRAIN_COLORS[tile.terrain] || '#243447',
    borderRadius: 10,
    boxShadow: `inset 0 ${Math.max(1, tile.height + 1) * -2}px 0 rgba(0,0,0,.3)`,
    color: '#fff',
    overflow: 'hidden',
  }
}

export default function TacticalGrid({
  map,
  units,
  selectedUnitId,
  activeCommand,
  selectedAbility,
  onSelectUnit,
  onSelectMoveTile,
  onSelectAttackTarget,
  onSelectAbilityTarget,
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

  const moveKeys = new Set(
    activeCommand === 'move'
      ? adjacentTiles
          .filter((tile) => !isTileBlocked(tile, units, selectedUnitId))
          .map((tile) => `${tile.x},${tile.y}`)
      : []
  )

  const attackTargetIds = new Set(
    activeCommand === 'attack'
      ? adjacentTiles
          .map((tile) => getUnitAt(units, tile.x, tile.y))
          .filter((unit) => unit && unit.team === 'enemy')
          .map((unit) => unit.id)
      : []
  )

  const abilityTargetIds = useMemo(() => {
    if (activeCommand !== 'ability-target' || !selectedUnit || !selectedAbility) return new Set()
    const maxRange = selectedAbility.range?.max ?? selectedAbility.range ?? 1
    const minRange = selectedAbility.range?.min ?? 0
    const targetType = selectedAbility.target
    return new Set(
      units
        .filter((u) => {
          if (u.hp <= 0) return false
          const dist = Math.abs(u.x - selectedUnit.x) + Math.abs(u.y - selectedUnit.y)
          if (dist > maxRange || dist < minRange) return false
          if (targetType === 'ally') return u.team === 'player'
          return u.team === 'enemy'
        })
        .map((u) => u.id)
    )
  }, [activeCommand, selectedUnit, selectedAbility, units])

  function handleTileClick(tile) {
    const unit = getUnitAt(units, tile.x, tile.y)
    if (unit) {
      if (attackTargetIds.has(unit.id)) { onSelectAttackTarget?.(unit.id); return }
      if (abilityTargetIds.has(unit.id)) { onSelectAbilityTarget?.(unit.id); return }
      onSelectUnit?.(unit.id)
      return
    }
    if (moveKeys.has(`${tile.x},${tile.y}`)) onSelectMoveTile?.(tile)
  }

  return (
    <div>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${map.size.width}, minmax(44px, 1fr))`,
          gap: 6,
        }}
      >
        {grid.map((tile) => {
          const unit = getUnitAt(units, tile.x, tile.y)
          const key = `${tile.x},${tile.y}`
          const selected = unit?.id === selectedUnitId
          const highlighted = moveKeys.has(key)
          const targetable = unit && attackTargetIds.has(unit.id)
          const abilityTargetable = unit && abilityTargetIds.has(unit.id)

          return (
            <button
              key={key}
              onClick={() => handleTileClick(tile)}
              style={getTileStyle(tile, selected, highlighted, targetable, abilityTargetable)}
              title={`${tile.terrainDef.name} h${tile.height}`}
            >
              {showCoordinates && (
                <span style={{ position: 'absolute', top: 4, left: 6, fontSize: 10, opacity: .65 }}>{tile.x},{tile.y}</span>
              )}
              <span style={{ position: 'absolute', right: 6, top: 4, fontSize: 10, opacity: .75 }}>h{tile.height}</span>
              {unit && (
                <span style={{ display: 'grid', placeItems: 'center', height: '100%', fontWeight: 800 }}>
                  <span>{unit.team === 'player' ? '◆' : '◇'}</span>
                  <small>{unit.name.split(' ')[0]}</small>
                </span>
              )}
              {!unit && highlighted && <span style={{ fontSize: 22 }}>·</span>}
            </button>
          )
        })}
      </div>
      <p style={{ opacity: .72, fontSize: 13 }}>
        Select a player unit, choose Move or Attack, then click a highlighted tile or enemy target.
      </p>
    </div>
  )
}
