import { useMemo } from 'react'
import { buildGrid, getUnitAt } from '../systems/grid.js'
import { TERRAIN_OVERLAY_COLORS } from '../systems/elementalSystem.js'
import { FACING_LABELS, getRelativeFacing } from '../systems/damageFormula.js'

const TC = { grass: '#244733', road: '#6b5131', stone: '#4b5563', shrine: '#68512a', shallow_water: '#155e75', deep_water: '#0f2942', ice: '#2a6a8a', burning: '#7f1d1d', electrified_water: '#1a3a1a', wall: '#111827', high_ground: '#374151', void_anchor: '#2d1a4f' }
const TI = { ice: 'ICE', burning: 'FIRE', electrified_water: 'ELEC', void_anchor: 'VOID', shrine: '*', shallow_water: '~', deep_water: '~~' }
const PC = { damage: '#f8f5ff', crit: '#fde047', heal: '#4ade80', temper: '#f97316', ether: '#a78bfa' }
const FA = { N: '^', E: '>', S: 'v', W: '<' }
const ANGLE_STYLE = {
  front: { border: '#86efac', background: 'rgba(134,239,172,.12)', text: '#bbf7d0' },
  side: { border: '#fbbf24', background: 'rgba(251,191,36,.16)', text: '#fde68a' },
  back: { border: '#f87171', background: 'rgba(248,113,113,.2)', text: '#fecaca' }
}

function HpBars({ unit }) {
  const maxHp = unit.stats?.hp ?? unit.hp ?? 1
  const maxTemper = unit.stats?.temper ?? unit.temper ?? 1
  const maxEther = unit.stats?.ether ?? unit.ether ?? 1

  return (
    <div style={s.bars}>
      {[
        [unit.hp, maxHp, '#4ade80'],
        [unit.temper, maxTemper, '#f97316'],
        [unit.ether, maxEther, '#a78bfa']
      ].map(([current, max, color], index) => (
        <div key={index} style={s.barTrack}>
          <div style={{ ...s.barFill, width: `${Math.max(0, (current / max) * 100)}%`, background: color }} />
        </div>
      ))}
    </div>
  )
}

export default function TacticalGrid({
  map,
  units,
  selectedUnitId,
  activeUnitId,
  activeCommand,
  moveTileKeys,
  attackTileKeys,
  intentTileKeys,
  reactionFlashKeys,
  pendingTargetKey,
  popups = {},
  onSelectUnit,
  onSelectMoveTile,
  onSelectAttackTarget,
  onHoverUnit,
  onHoverTile,
  onLeave,
  showCoordinates = true
}) {
  const grid = useMemo(() => buildGrid(map), [map])
  const activeUnit = units.find((unit) => unit.id === activeUnitId)

  function handleClick(tile) {
    const unit = getUnitAt(units, tile.x, tile.y)
    const key = `${tile.x},${tile.y}`

    if (unit) {
      if (attackTileKeys?.has(key)) {
        onSelectAttackTarget?.(unit.id)
        return
      }
      onSelectUnit?.(unit.id)
      return
    }

    if (moveTileKeys?.has(key)) onSelectMoveTile?.(tile)
  }

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: `repeat(${map.size.width},minmax(44px,1fr))`, gap: 5, overflowX: 'auto' }}>
        {grid.map((tile) => {
          const unit = getUnitAt(units, tile.x, tile.y)
          const key = `${tile.x},${tile.y}`
          const isSelected = unit?.id === selectedUnitId
          const isMove = moveTileKeys?.has(key) && !unit
          const isAttack = unit && attackTileKeys?.has(key)
          const isFlash = reactionFlashKeys?.has(key)
          const isIntent = intentTileKeys?.has(key)
          const isPending = key === pendingTargetKey
          const overlay = TERRAIN_OVERLAY_COLORS[tile.terrain]
          const terrainIcon = TI[tile.terrain]
          const popupsForTile = popups[key] ?? []
          const attackAngle = isAttack && activeUnit ? getRelativeFacing({ attacker: activeUnit, defender: unit }) : null
          const angleStyle = attackAngle ? ANGLE_STYLE[attackAngle] : null
          const tileBackground = angleStyle
            ? `linear-gradient(0deg,${angleStyle.background},${angleStyle.background}),${TC[tile.terrain] || '#243447'}`
            : TC[tile.terrain] || '#243447'
          const border = isPending
            ? '2px solid #86efac'
            : isSelected
              ? '2px solid #facc15'
              : isAttack
                ? `2px solid ${angleStyle?.border ?? '#f97316'}`
                : isFlash
                  ? '2px solid #fff'
                  : isMove
                    ? '2px solid #67e8f9'
                    : '1px solid rgba(255,255,255,.12)'

          return (
            <button
              key={key}
              onClick={() => handleClick(tile)}
              onMouseEnter={() => { unit ? onHoverUnit?.(unit.id) : onHoverTile?.(tile) }}
              onMouseLeave={() => onLeave?.()}
              style={{ ...s.tile, minHeight: 58, border, background: tileBackground, boxShadow: `inset 0 ${Math.max(1, tile.height + 1) * -2}px 0 rgba(0,0,0,.3)` }}
              title={`${tile.terrainDef.name} h${tile.height}`}
            >
              {overlay && <span style={{ ...s.overlay, background: overlay }} />}
              {isFlash && <span style={s.flash} />}
              {isIntent && !unit && <span style={s.intent} />}
              {showCoordinates && <span style={s.coord}>{key}</span>}
              <span style={s.height}>h{tile.height}</span>
              {terrainIcon && !unit && <span style={s.terrainIcon}>{terrainIcon}</span>}
              {isMove && <span style={s.moveDot}>.</span>}
              {unit && (
                <div style={s.unitShell}>
                  <span style={s.facing} title={`Facing ${unit.facing ?? 'S'}`}>{FA[unit.facing] ?? 'v'}</span>
                  {attackAngle && (
                    <span style={{ ...s.angleBadge, background: angleStyle.background, borderColor: angleStyle.border, color: angleStyle.text }}>
                      {FACING_LABELS[attackAngle]}
                    </span>
                  )}
                  <div style={s.unitBody}>
                    <div style={{ ...s.unitGem, filter: isSelected ? 'drop-shadow(0 0 5px #facc15)' : 'none' }}>
                      {unit.team === 'player' ? 'P' : 'E'}
                    </div>
                    <div style={s.unitName}>{unit.name.split(' ')[0]}</div>
                    {unit.statuses?.length > 0 && <div style={s.statuses}>{unit.statuses.map((status) => status.id[0].toUpperCase()).join('')}</div>}
                    {unit.hp <= 0 && <div style={s.defeated}>X</div>}
                  </div>
                  <HpBars unit={unit} />
                </div>
              )}
              {popupsForTile.map((popup) => (
                <div key={popup.id} style={{ ...s.popup, fontSize: popup.type === 'crit' ? 16 : 13, color: PC[popup.type] || '#fff' }}>
                  {popup.type === 'heal' ? '+' : ''}{popup.value}{popup.type === 'crit' ? ' CRIT!' : ''}
                </div>
              ))}
            </button>
          )
        })}
      </div>
      <style>{'@keyframes floatUp{0%{opacity:1;transform:translateX(-50%) translateY(0)}70%{opacity:1}100%{opacity:0;transform:translateX(-50%) translateY(-28px)}}'}</style>
      <div style={s.legend}>
        <span>P Player</span><span>E Enemy</span>
        <span style={{ color: '#67e8f9' }}>Move</span><span style={{ color: '#f97316' }}>Attack</span>
        <span style={{ color: '#facc15' }}>Selected</span><span style={{ color: '#86efac' }}>Confirm</span>
        <span style={{ color: '#bbf7d0' }}>Front</span><span style={{ color: '#fde68a' }}>Side</span><span style={{ color: '#fecaca' }}>Back</span>
      </div>
    </div>
  )
}

const s = {
  tile: { position: 'relative', borderRadius: 10, color: '#fff', overflow: 'visible', cursor: 'pointer', padding: 0 },
  overlay: { position: 'absolute', inset: 0, borderRadius: 9, pointerEvents: 'none', zIndex: 1 },
  flash: { position: 'absolute', inset: 0, background: 'rgba(255,255,255,.35)', borderRadius: 9, pointerEvents: 'none', zIndex: 2 },
  intent: { position: 'absolute', inset: 0, background: 'rgba(248,113,113,.2)', borderRadius: 9, pointerEvents: 'none', zIndex: 1 },
  coord: { position: 'absolute', top: 3, left: 5, fontSize: 9, opacity: .5, zIndex: 4 },
  height: { position: 'absolute', right: 5, top: 3, fontSize: 9, opacity: .6, zIndex: 4 },
  terrainIcon: { position: 'absolute', bottom: 5, right: 5, fontSize: 9, opacity: .75, zIndex: 4, fontWeight: 800 },
  moveDot: { position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', fontSize: 18, opacity: .45, zIndex: 4 },
  unitShell: { position: 'relative', height: '100%', display: 'grid', placeItems: 'center', zIndex: 4 },
  facing: { position: 'absolute', top: 3, right: 5, width: 16, height: 16, borderRadius: 999, display: 'grid', placeItems: 'center', fontSize: 10, fontWeight: 900, background: 'rgba(0,0,0,.52)', border: '1px solid rgba(255,255,255,.22)', color: '#f8f5ff', zIndex: 5 },
  angleBadge: { position: 'absolute', left: 4, bottom: 13, padding: '1px 5px', borderRadius: 6, fontSize: 8, fontWeight: 900, letterSpacing: '.04em', textTransform: 'uppercase', border: '1px solid', zIndex: 5 },
  unitBody: { textAlign: 'center' },
  unitGem: { fontSize: 15, fontWeight: 900 },
  unitName: { fontSize: 9, lineHeight: 1.2, fontWeight: 800 },
  statuses: { fontSize: 8, color: '#fbbf24', lineHeight: 1 },
  defeated: { fontSize: 9, color: '#f87171' },
  bars: { position: 'absolute', bottom: 0, left: 2, right: 2, display: 'grid', gap: 1, padding: '0 1px 2px', zIndex: 3 },
  barTrack: { height: 3, borderRadius: 2, background: 'rgba(0,0,0,.5)', overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 2, transition: 'width .2s' },
  popup: { position: 'absolute', top: -8, left: '50%', transform: 'translateX(-50%)', fontWeight: 900, textShadow: '0 1px 4px rgba(0,0,0,.9)', pointerEvents: 'none', zIndex: 10, animation: 'floatUp 1.1s ease-out forwards', whiteSpace: 'nowrap' },
  legend: { marginTop: 8, display: 'flex', flexWrap: 'wrap', gap: 10, fontSize: 11, color: 'rgba(247,240,223,.45)' }
}
