import { useEffect, useMemo, useState } from 'react'

const SIZE = 8
const FACE_ORDER = ['N', 'E', 'S', 'W']
const dirs = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
]

const makeMap = () => Array.from({ length: SIZE }, (_, y) =>
  Array.from({ length: SIZE }, (_, x) => ({
    h: (x + y) % 3,
    t: (x + y) % 5 === 0 ? 'water' : (x * y) % 7 === 0 ? 'forest' : 'plain',
  }))
)

function key(x, y) { return `${x},${y}` }

function rangeTiles(origin, move, jump, map) {
  const q = [[origin.x, origin.y, 0]]
  const seen = new Set([key(origin.x, origin.y)])
  const out = new Set([key(origin.x, origin.y)])

  while (q.length) {
    const [x, y, d] = q.shift()
    for (const [dx, dy] of dirs) {
      const nx = x + dx
      const ny = y + dy
      if (nx < 0 || ny < 0 || nx >= SIZE || ny >= SIZE) continue
      if (d + 1 > move) continue
      const heightDelta = Math.abs(map[ny][nx].h - map[y][x].h)
      if (heightDelta > jump) continue
      const k = key(nx, ny)
      if (seen.has(k)) continue
      seen.add(k)
      out.add(k)
      q.push([nx, ny, d + 1])
    }
  }
  return out
}

const clamp = (v, min, max) => Math.max(min, Math.min(max, v))

export default function TacticsBoardPrototype() {
  const map = useMemo(makeMap, [])
  const [phase, setPhase] = useState('move')
  const [unit, setUnit] = useState({ x: 1, y: 1, move: 4, jump: 1, facing: 'E' })
  const [cursor, setCursor] = useState({ x: 1, y: 1 })

  const tiles = useMemo(() => rangeTiles(unit, unit.move, unit.jump, map), [unit, map])
  const cursorTile = map[cursor.y][cursor.x]

  const rotateFacing = (step) => {
    const idx = FACE_ORDER.indexOf(unit.facing)
    const next = FACE_ORDER[(idx + step + FACE_ORDER.length) % FACE_ORDER.length]
    setUnit((u) => ({ ...u, facing: next }))
  }

  const confirmAtCursor = () => {
    const target = key(cursor.x, cursor.y)
    if (phase === 'move' && tiles.has(target)) {
      const dx = cursor.x - unit.x
      const dy = cursor.y - unit.y
      const facing = Math.abs(dx) > Math.abs(dy) ? (dx >= 0 ? 'E' : 'W') : (dy >= 0 ? 'S' : 'N')
      setUnit((u) => ({ ...u, x: cursor.x, y: cursor.y, facing: dx || dy ? facing : u.facing }))
      setPhase('act')
      return
    }
    if (phase === 'act') setPhase('facing')
    else if (phase === 'facing') setPhase('move')
  }

  const cancelAction = () => {
    if (phase === 'facing') setPhase('act')
    else if (phase === 'act') setPhase('move')
  }

  useEffect(() => {
    const onKeyDown = (e) => {
      const k = e.key.toLowerCase()
      if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', 'w', 'a', 's', 'd', ' ', 'enter', 'escape', 'q', 'e', 'tab'].includes(k)) {
        e.preventDefault()
      }

      if (k === 'arrowup' || k === 'w') setCursor((c) => ({ ...c, y: clamp(c.y - 1, 0, SIZE - 1) }))
      if (k === 'arrowdown' || k === 's') setCursor((c) => ({ ...c, y: clamp(c.y + 1, 0, SIZE - 1) }))
      if (k === 'arrowleft' || k === 'a') setCursor((c) => ({ ...c, x: clamp(c.x - 1, 0, SIZE - 1) }))
      if (k === 'arrowright' || k === 'd') setCursor((c) => ({ ...c, x: clamp(c.x + 1, 0, SIZE - 1) }))
      if (k === 'enter' || k === ' ') confirmAtCursor()
      if (k === 'escape') cancelAction()
      if (k === 'q' && phase === 'facing') rotateFacing(-1)
      if (k === 'e' && phase === 'facing') rotateFacing(1)
      if (k === 'tab') setPhase((p) => (p === 'move' ? 'act' : p === 'act' ? 'facing' : 'move'))
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [phase, cursor, tiles, unit])

  const moveUnit = (x, y) => {
    setCursor({ x, y })
    if (phase === 'move' && tiles.has(key(x, y))) confirmAtCursor()
  }

  return (
    <div style={{ color: '#eaf2ff', padding: 16, fontFamily: 'system-ui' }}>
      <h2 style={{ marginBottom: 8 }}>Tactics Board Prototype (FFT/Disgaea-style controls)</h2>
      <p style={{ opacity: .85, marginBottom: 10 }}>Arrow/WASD: cursor • Enter/Space: confirm • Esc: cancel • Q/E: rotate facing • Tab: cycle phase.</p>
      <div style={{ marginBottom: 12, fontSize: 14 }}>Phase: <strong>{phase.toUpperCase()}</strong></div>
      <div style={{ display: 'grid', gridTemplateColumns: `repeat(${SIZE}, 48px)`, gap: 4, width: 'max-content' }}>
        {map.map((row, y) => row.map((tile, x) => {
          const isUnit = unit.x === x && unit.y === y
          const inRange = tiles.has(key(x, y))
          const isCursor = cursor.x === x && cursor.y === y
          const bg = tile.t === 'water' ? '#1b4f72' : tile.t === 'forest' ? '#145a32' : '#273746'
          return (
            <button
              key={key(x, y)}
              onMouseEnter={() => setCursor({ x, y })}
              onClick={() => moveUnit(x, y)}
              style={{
                width: 48,
                height: 48,
                border: isCursor ? '2px solid #ffffff' : inRange ? '2px solid #f1c40f' : '1px solid #5d6d7e',
                background: isUnit ? '#7d3c98' : bg,
                color: '#fff',
                cursor: inRange ? 'pointer' : 'default',
              }}
              title={`(${x},${y}) h:${tile.h} ${tile.t}`}
            >
              {isUnit ? unit.facing : tile.h}
            </button>
          )
        }))}
      </div>
      <div style={{ marginTop: 12, fontSize: 14 }}>
        <div>Unit: ({unit.x},{unit.y}) | Move: {unit.move} | Jump: {unit.jump} | Facing: {unit.facing}</div>
        <div>Cursor: ({cursor.x},{cursor.y}) | Height {cursorTile.h} | Terrain {cursorTile.t}</div>
      </div>
    </div>
  )
}
