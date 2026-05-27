import { getBoonLane, getBoonsInLane, BOON_LANE_LIMITS } from '../data/boons.js'
import { getCurrentNode } from '../systems/floorGenerator.js'
import BoonCard from '../components/BoonCard.jsx'

export default function BoonPickScreen({ gameState, onChooseBoon, setScreen }) {
  const run = gameState.activeRun
  const node = run ? getCurrentNode(run) : null
  const options = node?.options ?? []
  const activeBoons = run?.boons ?? []

  // Generate selection context for each boon option
  const getSelectionContext = (boon) => {
    const lane = getBoonLane(boon)
    if (!lane) {
      return 'Synergy with your current build'
    }

    const boonsInLane = getBoonsInLane(activeBoons, boon)
    const limit = BOON_LANE_LIMITS[lane] ?? 999
    const slots = limit - boonsInLane.length

    if (slots <= 0) {
      return `${lane.charAt(0).toUpperCase() + lane.slice(1)} lane is full`
    } else if (slots === 1) {
      return `${slots} slot left in ${lane} lane`
    } else {
      return `${slots} slots available in ${lane} lane`
    }
  }

  return (
    <main style={s.panel}>
      <div style={s.header}>
        <div>
          <p style={s.eyebrow}>Guardian boon</p>
          <h2 style={s.title}>Choose a blessing</h2>
          <p style={s.copy}>Pick one to carry through the rest of this run. Hover for details and lane status.</p>
        </div>
        <button style={s.secondaryBtn} onClick={() => setScreen('runMap')}>Back to Map</button>
      </div>

      {activeBoons.length > 0 && (
        <section style={s.activeBoons}>
          <h3 style={s.activeBoonTitle}>Your Blessings</h3>
          <div style={s.boonDisplay}>
            {activeBoons.map((b) => (
              <div key={b.id} style={s.activeBoonItem}>
                <span style={s.activeBoonIcon}>{b.icon ?? '*'}</span>
                <span style={s.activeBoonName}>{b.name}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      {options.length === 0 && (
        <section style={s.empty}>
          <h3>No boon choices found</h3>
          <p style={s.copy}>Return to the run map and continue the route.</p>
        </section>
      )}

      <section style={s.grid}>
        {options.map((boon) => (
          <BoonCard
            key={boon.id}
            boon={boon}
            onSelect={onChooseBoon}
            activeBoons={activeBoons}
            selectionReason={getSelectionContext(boon)}
            variant="full"
            showLaneInfo={true}
          />
        ))}
      </section>
    </main>
  )
}

const s = {
  panel: { border: '1px solid rgba(255,255,255,.12)', background: 'rgba(10,14,24,.84)', borderRadius: 24, padding: 24 },
  header: { display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 18, marginBottom: 24, flexWrap: 'wrap' },
  eyebrow: { color: '#c9a756', fontSize: 12, fontWeight: 900, letterSpacing: '.18em', textTransform: 'uppercase', margin: 0 },
  title: { fontSize: 26, margin: '4px 0' },
  copy: { margin: 0, color: 'rgba(247,240,223,.68)', fontSize: 14, lineHeight: 1.6 },

  activeBoons: { marginBottom: 24, paddingBottom: 16, borderBottom: '1px solid rgba(255,255,255,.1)' },
  activeBoonTitle: { margin: '0 0 12px', fontSize: 12, fontWeight: 900, color: '#c9a756', textTransform: 'uppercase', letterSpacing: '.12em' },
  boonDisplay: { display: 'flex', gap: 12, flexWrap: 'wrap' },
  activeBoonItem: { display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', background: 'rgba(201,167,86,.12)', border: '1px solid rgba(201,167,86,.25)', borderRadius: 8 },
  activeBoonIcon: { fontSize: 18 },
  activeBoonName: { fontSize: 12, fontWeight: 700, color: '#f7f0df' },

  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(260px,1fr))', gap: 14 },

  secondaryBtn: { padding: '9px 13px', borderRadius: 10, border: '1px solid rgba(255,255,255,.14)', background: 'rgba(255,255,255,.06)', color: '#f7f0df', fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit' },
  empty: { border: '1px solid rgba(255,255,255,.1)', borderRadius: 14, padding: 16, background: 'rgba(255,255,255,.04)' },
}
