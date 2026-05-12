import { useMemo } from 'react'
import { buildGrid, getUnitAt, manhattan } from '../systems/grid.js'

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

function getTileStyle(tile, selected, highlighted, targetable, active) {
  return {
    position: 'relative',
    minHeight: 58,
    border: active
      ? '2px solid #fef08a'
      : selected
        ? '2px solid #facc15'
        : targetable
          ? '2px solid #f97316'
          : highlighted
            ? '2px solid #67e8f9'
            : '1px solid rgba(255,255,255,.12)',
    background: TERRAIN_COLORS[tile.terrain] || '#243447',
    borderRadius: 10,
    boxShadow: highlighted
      ? `0 0 0 2px rgba(103,232,249,.15), inset 0 ${Math.max(1, tile.height + 1) * -2}px 0 rgba(0,0,0,.3)`
      : `inset 0 ${Math.max(1, tile.height + 1) * -2}px 0 rgba(0,0,0,.3)`,
    color: '#fff',
    overflow: 'hidden',
  }
}

export default function TacticalGrid({
  map,
  units,
  selectedUnitId,
  activeUnitId,
  activeCommand,
  movementRange = [],
  damagePreview,
  onSelectUnit,
  onSelectMoveTile,
  onSelectAttackTarget,
  showCoordinates = true,
}) {
  const grid = useMemo(() => buildGrid(map), [map])
  const activeUnit = units.find((unit) => unit.id === activeUnitId)

  const moveKeys = new Set(
    activeCommand === 'move'
      ? movementRange.map((tile) => `${tile.x},${tile.y}`)
      : []
  )

  const attackTargetIds = new Set(
    activeCommand === 'attack' && activeUnit
      ? units
          .filter((unit) => unit.team !== activeUnit.team && unit.hp > 0)
          .filter((unit) => manhattan(activeUnit, unit) <= 1)
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

    if (moveKeys.has(`${tile.x},${tile.y}`)) {
      onSelectMoveTile?.(tile)
    }
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
          const active = unit?.id === activeUnitId
          const highlighted = moveKeys.has(key)
          const targetable = unit && attackTargetIds.has(unit.id)
          const previewedTarget = damagePreview?.targetId === unit?.id

          return (
            <button
              key={key}
              onClick={() => handleTileClick(tile)}
              style={getTileStyle(tile, selected, highlighted, targetable || previewedTarget, active)}
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
                  <small>CT {Math.round(unit.ct ?? 0)}</small>
                </span>
              )}
              {!unit && highlighted && <span style={{ fontSize: 22 }}>·</span>}
              {targetable && <span style={{ position: 'absolute', bottom: 4, left: 6, fontSize: 10, color: '#fed7aa' }}>TARGET</span>}
            </button>
          )
        })}
      </div>
      <p style={{ opacity: .72, fontSize: 13 }}>
        Active units act when CT reaches 100. Move uses range and Jump rules; Attack previews damage before confirmation.
      </p>
    </div>
  )
}
