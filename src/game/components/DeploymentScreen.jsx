import { useMemo, useState } from 'react'
import { PLAYER_UNITS } from '../data/units.js'
import { buildGrid, keyOf } from '../systems/grid.js'
import {
  assignUnitToDeploymentTile,
  createBattleStateFromDeployment,
  getDefaultDeployment,
  getDeploymentTileKeys,
  rotateDeploymentFacing,
  validateDeployment
} from '../systems/deployment.js'

const facingArrows = { N: '↑', E: '→', S: '↓', W: '←' }

export default function DeploymentScreen({ map, roster = Object.keys(PLAYER_UNITS), onStartBattle, onCancel }) {
  const grid = useMemo(() => buildGrid(map), [map])
  const deploymentTileKeys = useMemo(() => getDeploymentTileKeys(map), [map])
  const [deployment, setDeployment] = useState(() => getDefaultDeployment(map))
  const [selectedUnitId, setSelectedUnitId] = useState(() => deployment[0]?.unitId || roster[0])

  const validation = validateDeployment(map, deployment)
  const deployedUnitIds = new Set(deployment.map((slot) => slot.unitId))
  const selectedSlot = deployment.find((slot) => slot.unitId === selectedUnitId)

  function handleTileClick(tile) {
    if (!selectedUnitId) return
    if (!deploymentTileKeys.has(keyOf(tile.x, tile.y))) return
    setDeployment((current) => assignUnitToDeploymentTile({ map, deployment: current, unitId: selectedUnitId, tile }))
  }

  function handleRotate() {
    if (!selectedUnitId) return
    setDeployment((current) => rotateDeploymentFacing(current, selectedUnitId))
  }

  function handleRemove() {
    if ((map.requiredUnitIds || []).includes(selectedUnitId)) return
    setDeployment((current) => current.filter((slot) => slot.unitId !== selectedUnitId))
  }

  function handleStart() {
    const battleState = createBattleStateFromDeployment(map.id, deployment)
    onStartBattle?.(battleState)
  }

  return (
    <main style={styles.shell}>
      <header style={styles.header}>
        <div>
          <p style={styles.eyebrow}>Pre-Battle Deployment</p>
          <h1 style={styles.title}>{map.name}</h1>
          <p style={styles.copy}>{map.deployment?.briefing || 'Place your units before the battle begins.'}</p>
        </div>
        <div style={styles.headerActions}>
          {onCancel && <button style={styles.secondaryButton} onClick={onCancel}>Back</button>}
          <button style={styles.primaryButton} disabled={!validation.valid} onClick={handleStart}>Start Battle</button>
        </div>
      </header>

      <section style={styles.layout}>
        <aside style={styles.rosterPanel}>
          <p style={styles.panelTitle}>Roster</p>
          <p style={styles.small}>Max party size: {map.maxPartySize || roster.length}</p>
          <div style={styles.rosterList}>
            {roster.map((unitId) => {
              const unit = PLAYER_UNITS[unitId]
              if (!unit) return null
              const deployed = deployedUnitIds.has(unitId)
              const required = (map.requiredUnitIds || []).includes(unitId)
              return (
                <button
                  key={unitId}
                  style={{ ...styles.rosterButton, borderColor: selectedUnitId === unitId ? '#ffd86b' : deployed ? '#7bdcff' : 'rgba(255,255,255,0.14)' }}
                  onClick={() => setSelectedUnitId(unitId)}
                >
                  <span style={styles.rosterName}>{unit.name}</span>
                  <span style={styles.rosterMeta}>{required ? 'Required' : deployed ? 'Placed' : 'Reserve'}</span>
                </button>
              )
            })}
          </div>

          <div style={styles.controls}>
            <button style={styles.secondaryButton} onClick={handleRotate} disabled={!selectedSlot}>Rotate {selectedSlot ? facingArrows[selectedSlot.facing] : ''}</button>
            <button style={styles.secondaryButton} onClick={handleRemove} disabled={!selectedSlot || (map.requiredUnitIds || []).includes(selectedUnitId)}>Remove</button>
          </div>

          {!validation.valid && (
            <div style={styles.errorBox}>
              {validation.errors.map((error) => <p key={error} style={styles.error}>{error}</p>)}
            </div>
          )}
        </aside>

        <section style={{ ...styles.grid, gridTemplateColumns: `repeat(${map.size.width}, 52px)` }}>
          {grid.map((tile) => {
            const tileKey = keyOf(tile.x, tile.y)
            const deploymentSlot = deployment.find((slot) => keyOf(slot.x, slot.y) === tileKey)
            const unit = deploymentSlot ? PLAYER_UNITS[deploymentSlot.unitId] : null
            const deployable = deploymentTileKeys.has(tileKey)
            return (
              <button
                key={tileKey}
                style={{
                  ...styles.tile,
                  ...terrainStyle(tile.terrain),
                  outline: deployable ? '2px solid rgba(123,220,255,0.8)' : '1px solid rgba(255,255,255,0.1)',
                  opacity: deployable || unit ? 1 : 0.72
                }}
                onClick={() => handleTileClick(tile)}
                title={`${tile.x},${tile.y}`}
              >
                <span style={styles.coord}>{tile.x},{tile.y}</span>
                {deployable && !unit && <span style={styles.deployMarker}>◇</span>}
                {unit && (
                  <span style={{ ...styles.unitToken, borderColor: deploymentSlot.unitId === selectedUnitId ? '#ffd86b' : '#7bdcff' }}>
                    {unit.name.slice(0, 1)}{facingArrows[deploymentSlot.facing]}
                  </span>
                )}
              </button>
            )
          })}
        </section>
      </section>
    </main>
  )
}

function terrainStyle(terrain) {
  const stylesByTerrain = {
    grass: { background: 'linear-gradient(135deg, #21482d, #173321)' },
    road: { background: 'linear-gradient(135deg, #5f4c36, #3b2f24)' },
    stone: { background: 'linear-gradient(135deg, #5c6270, #353946)' },
    shrine: { background: 'linear-gradient(135deg, #40315f, #17152a)' },
    shallow_water: { background: 'linear-gradient(135deg, #126c8a, #093f5a)' },
    deep_water: { background: 'linear-gradient(135deg, #06324f, #031a2d)' },
    ice: { background: 'linear-gradient(135deg, #9fdcff, #4f91c1)' },
    burning: { background: 'linear-gradient(135deg, #9f341b, #421107)' },
    wall: { background: 'linear-gradient(135deg, #1f2230, #0a0b13)' },
    high_ground: { background: 'linear-gradient(135deg, #6f6a56, #3d3a2e)' }
  }
  return stylesByTerrain[terrain] || stylesByTerrain.grass
}

const styles = {
  shell: { minHeight: '100vh', padding: 24, color: '#f8f5ff', background: 'radial-gradient(circle at 20% 20%, rgba(123, 73, 255, 0.18), transparent 30%), #050615' },
  header: { maxWidth: 1220, margin: '0 auto 20px', display: 'flex', justifyContent: 'space-between', gap: 24, alignItems: 'flex-end' },
  eyebrow: { margin: 0, color: '#b8b3ff', textTransform: 'uppercase', letterSpacing: '0.18em', fontSize: 12, fontWeight: 900 },
  title: { margin: '8px 0', fontSize: 'clamp(34px, 5vw, 60px)', lineHeight: 1 },
  copy: { margin: 0, color: 'rgba(248,245,255,0.78)', maxWidth: 680 },
  headerActions: { display: 'flex', gap: 10, flexWrap: 'wrap' },
  primaryButton: { padding: '12px 18px', borderRadius: 999, border: '1px solid rgba(255,255,255,0.22)', background: 'linear-gradient(135deg, #8f63ff, #ff6b35)', color: 'white', fontWeight: 900, cursor: 'pointer' },
  secondaryButton: { padding: '10px 14px', borderRadius: 999, border: '1px solid rgba(255,255,255,0.18)', background: 'rgba(255,255,255,0.07)', color: 'white', fontWeight: 800, cursor: 'pointer' },
  layout: { maxWidth: 1220, margin: '0 auto', display: 'grid', gridTemplateColumns: '300px 1fr', gap: 20, alignItems: 'start' },
  rosterPanel: { padding: 16, borderRadius: 20, background: 'rgba(5,7,20,0.86)', border: '1px solid rgba(255,255,255,0.12)' },
  panelTitle: { margin: 0, fontWeight: 900, fontSize: 20 },
  small: { color: 'rgba(248,245,255,0.66)', margin: '6px 0 14px' },
  rosterList: { display: 'grid', gap: 8 },
  rosterButton: { display: 'flex', justifyContent: 'space-between', padding: '10px 12px', borderRadius: 12, border: '1px solid rgba(255,255,255,0.14)', background: 'rgba(255,255,255,0.06)', color: 'white', cursor: 'pointer' },
  rosterName: { fontWeight: 900 },
  rosterMeta: { color: 'rgba(248,245,255,0.6)', fontSize: 12 },
  controls: { display: 'flex', gap: 8, marginTop: 14, flexWrap: 'wrap' },
  errorBox: { marginTop: 14, padding: 10, borderRadius: 12, background: 'rgba(255, 80, 80, 0.12)', border: '1px solid rgba(255, 80, 80, 0.22)' },
  error: { margin: '4px 0', color: '#ff9c9c', fontSize: 13 },
  grid: { display: 'grid', gap: 6, padding: 18, borderRadius: 24, background: 'rgba(0,0,0,0.28)', border: '1px solid rgba(255,255,255,0.12)', overflow: 'auto' },
  tile: { position: 'relative', width: 52, height: 52, border: 0, borderRadius: 10, color: 'white', cursor: 'pointer' },
  coord: { position: 'absolute', left: 5, top: 4, fontSize: 9, color: 'rgba(255,255,255,0.5)' },
  deployMarker: { position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', color: 'rgba(123,220,255,0.9)', fontWeight: 900 },
  unitToken: { position: 'absolute', inset: 8, display: 'grid', placeItems: 'center', borderRadius: 999, border: '2px solid #7bdcff', background: 'rgba(5,7,20,0.92)', fontWeight: 900 }
}
