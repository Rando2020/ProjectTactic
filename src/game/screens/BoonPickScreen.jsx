import { BOON_RARITIES } from '../data/boons.js'
import { getCurrentNode } from '../systems/floorGenerator.js'

export default function BoonPickScreen({ gameState, onChooseBoon, setScreen }) {
  const run = gameState.activeRun
  const node = run ? getCurrentNode(run) : null
  const options = node?.options ?? []

  return (
    <main style={s.panel}>
      <div style={s.header}>
        <div>
          <p style={s.eyebrow}>Guardian boon</p>
          <h2 style={s.title}>Choose a blessing</h2>
          <p style={s.copy}>Pick one boon to carry through the rest of this run.</p>
        </div>
        <button style={s.secondaryBtn} onClick={() => setScreen('runMap')}>Back to Map</button>
      </div>

      {options.length === 0 && (
        <section style={s.empty}>
          <h3>No boon choices found</h3>
          <p style={s.copy}>Return to the run map and continue the route.</p>
        </section>
      )}

      <section style={s.grid}>
        {options.map((boon) => {
          const rarity = BOON_RARITIES[boon.rarity] ?? BOON_RARITIES.common
          return (
            <article key={boon.id} style={{ ...s.card, borderColor: rarity.border, background: rarity.glow }}>
              <div style={s.cardTop}>
                <span style={s.icon}>{boon.icon ?? '*'}</span>
                <span style={{ ...s.rarity, color: rarity.color }}>{rarity.label}</span>
              </div>
              <h3 style={s.cardTitle}>{boon.name}</h3>
              <p style={s.copy}>{boon.description}</p>
              {boon.flavour && <p style={s.flavour}>{boon.flavour}</p>}
              <button style={{ ...s.pickBtn, borderColor: rarity.border }} onClick={() => onChooseBoon(boon)}>
                Choose Boon
              </button>
            </article>
          )
        })}
      </section>
    </main>
  )
}

const s = {
  panel: { border: '1px solid rgba(255,255,255,.12)', background: 'rgba(10,14,24,.84)', borderRadius: 24, padding: 24 },
  header: { display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 18, marginBottom: 18, flexWrap: 'wrap' },
  eyebrow: { color: '#c9a756', fontSize: 12, fontWeight: 900, letterSpacing: '.18em', textTransform: 'uppercase', margin: 0 },
  title: { fontSize: 26, margin: '4px 0' },
  copy: { margin: 0, color: 'rgba(247,240,223,.68)', fontSize: 14, lineHeight: 1.6 },
  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(240px,1fr))', gap: 14 },
  card: { border: '1px solid rgba(255,255,255,.14)', borderRadius: 16, padding: 16, minHeight: 260, display: 'flex', flexDirection: 'column', gap: 10 },
  cardTop: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  icon: { fontSize: 30 },
  rarity: { fontSize: 11, fontWeight: 900, textTransform: 'uppercase', letterSpacing: '.12em' },
  cardTitle: { margin: 0, fontSize: 20 },
  flavour: { margin: 'auto 0 0', color: 'rgba(247,240,223,.46)', fontSize: 12, lineHeight: 1.55, fontStyle: 'italic' },
  pickBtn: { marginTop: 6, padding: '10px 14px', borderRadius: 10, border: '1px solid rgba(201,167,86,.45)', background: 'rgba(255,255,255,.07)', color: '#f7f0df', fontWeight: 900, cursor: 'pointer', fontFamily: 'inherit' },
  secondaryBtn: { padding: '9px 13px', borderRadius: 10, border: '1px solid rgba(255,255,255,.14)', background: 'rgba(255,255,255,.06)', color: '#f7f0df', fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit' },
  empty: { border: '1px solid rgba(255,255,255,.1)', borderRadius: 14, padding: 16, background: 'rgba(255,255,255,.04)' },
}
