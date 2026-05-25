import { useMemo } from 'react'
import { buildGrid, getUnitAt } from '../systems/grid.js'
import { TERRAIN_OVERLAY_COLORS } from '../systems/elementalSystem.js'
import { FACING_LABELS, getRelativeFacing } from '../systems/damageFormula.js'

// Job color system: maps job IDs to thematic colors and silhouette icons
const JOB_COLORS = {
  // Tank/Defender jobs
  warder: { bg: '#dc2626', border: '#991b1b', text: '#fecaca', icon: '⚔️' },
  null_breaker: { bg: '#b91c1c', border: '#7f1d1d', text: '#fecaca', icon: '🗡️' },
  // Healer jobs
  luminary: { bg: '#059669', border: '#065f46', text: '#d1fae5', icon: '✨' },
  seraph: { bg: '#0891b2', border: '#164e63', text: '#cffafe', icon: '☆' },
  // Caster jobs
  arcanist: { bg: '#7c3aed', border: '#4c1d95', text: '#e9d5ff', icon: '⚡' },
  etherweaver: { bg: '#6366f1', border: '#312e81', text: '#e0e7ff', icon: '◆' },
  // Summoner/Guardian jobs
  resonant: { bg: '#d97706', border: '#92400e', text: '#fef3c7', icon: '◎' },
  primal_binder: { bg: '#ca8a04', border: '#713f12', text: '#fef08a', icon: '⊕' },
  // Jump attacker
  skywarden: { bg: '#0ea5e9', border: '#0c4a6e', text: '#cffafe', icon: '△' }
}

const getJobColor = (jobId) => JOB_COLORS[jobId] || { bg: '#4b5563', border: '#1e293b', text: '#cbd5e1', icon: '◇' }

const TC = { grass: '#244733', road: '#6b5131', stone: '#4b5563', shrine: '#68512a', shallow_water: '#155e75', deep_water: '#0f2942', ice: '#2a6a8a', burning: '#7f1d1d', electrified_water: '#1a3a1a', wall: '#111827', high_ground: '#374151', void_anchor: '#2d1a4f' }
const TI = { ice: 'ICE', burning: 'FIRE', electrified_water: 'ELEC', void_anchor: 'VOID', shrine: '*', shallow_water: '~', deep_water: '~~' }
const PC = { damage: '#f8f5ff', crit: '#fde047', heal: '#4ade80', temper: '#f97316', ether: '#a78bfa' }
const FA = { N: '^', E: '>', S: 'v', W: '<' }
const ANGLE_STYLE = {
  front: { border: '#86efac', background: 'rgba(134,239,172,.12)', text: '#bbf7d0' },
  side: { border: '#fbbf24', background: 'rgba(251,191,36,.16)', text: '#fde68a' },
  back: { border: '#f87171', background: 'rgba(248,113,113,.2)', text: '#fecaca' }
}

function UnitPortrait({ unit, isSelected }) {
  const jobColor = getJobColor(unit.baseJobId || unit.currentJobId)
  const initials = unit.name.split(' ').map(n => n[0]).join('')

  return (
    <div style={{
      ...s.unitPortrait,
      background: jobColor.bg,
      borderColor: jobColor.border,
      filter: isSelected ? `drop-shadow(0 0 6px ${jobColor.border})` : 'none',
      animation: 'unitBob 2.2s ease-in-out infinite'
    }}>
      <div style={s.portraitIcon}>{jobColor.icon}</div>
      <div style={{ ...s.portraitInitials, color: jobColor.text }}>{initials}</div>
      {unit.team === 'enemy' && <div style={s.enemyBadge}>E</div>}
    </div>
  )
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
                    <UnitPortrait unit={unit} isSelected={isSelected} />
                    <div style={s.unitName}>{unit.name.split(' ')[0]}</div>
                    {unit.statuses?.length > 0 && <div style={s.statuses}>{unit.statuses.map((status) => status.id[0].toUpperCase()).join('')}</div>}
                    {unit.hp <= 0 && <div style={s.defeated}>✕</div>}
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
      <style>{`
        @keyframes floatUp {
          0% { opacity: 1; transform: translateX(-50%) translateY(0) }
          70% { opacity: 1 }
          100% { opacity: 0; transform: translateX(-50%) translateY(-28px) }
        }
        @keyframes unitBob {
          0%, 100% { transform: translateY(0px) }
          50% { transform: translateY(-2px) }
        }
      `}</style>
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
  unitPortrait: {
    width: 24,
    height: 24,
    borderRadius: '50%',
    border: '2px solid',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    fontSize: 12,
    fontWeight: 900,
    color: '#fff',
    marginBottom: 2,
    transition: 'all .2s ease'
  },
  portraitIcon: {
    position: 'absolute',
    fontSize: 10,
    top: 1,
    right: 1,
    opacity: 0.9,
    lineHeight: 1
  },
  portraitInitials: {
    fontSize: 8,
    fontWeight: 900,
    letterSpacing: '.02em',
    textShadow: '0 1px 2px rgba(0,0,0,.5)',
    position: 'relative',
    zIndex: 2
  },
  enemyBadge: {
    position: 'absolute',
    top: -3,
    right: -3,
    width: 12,
    height: 12,
    background: '#dc2626',
    border: '1px solid #991b1b',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: 7,
    fontWeight: 900,
    color: '#fff',
    zIndex: 3
  },
  unitName: { fontSize: 9, lineHeight: 1.2, fontWeight: 800 },
  statuses: { fontSize: 8, color: '#fbbf24', lineHeight: 1 },
  defeated: { fontSize: 11, color: '#f87171', fontWeight: 900 },
  bars: { position: 'absolute', bottom: 0, left: 2, right: 2, display: 'grid', gap: 1, padding: '0 1px 2px', zIndex: 3 },
  barTrack: { height: 3, borderRadius: 2, background: 'rgba(0,0,0,.5)', overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 2, transition: 'width .2s' },
  popup: { position: 'absolute', top: -8, left: '50%', transform: 'translateX(-50%)', fontWeight: 900, textShadow: '0 1px 4px rgba(0,0,0,.9)', pointerEvents: 'none', zIndex: 10, animation: 'floatUp 1.1s ease-out forwards', whiteSpace: 'nowrap' },
  legend: { marginTop: 8, display: 'flex', flexWrap: 'wrap', gap: 10, fontSize: 11, color: 'rgba(247,240,223,.45)' }
}
