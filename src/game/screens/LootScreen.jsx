import { getRarityDef } from '../systems/lootSystem.js'

export default function LootScreen({ gameState, onClaimLoot, setScreen }) {
  const loot = gameState.pendingLoot
  const items = loot?.items ?? []

  return (
    <main style={s.panel}>
      <div style={s.header}>
        <div>
          <p style={s.eyebrow}>Post-battle loot</p>
          <h2 style={s.title}>{loot?.missionName ?? 'Spoils Collected'}</h2>
          <p style={s.copy}>Claim your drops, update the run route, and keep moving.</p>
        </div>
        <div style={s.actions}>
          <button style={s.secondaryBtn} onClick={() => setScreen('runMap')}>Map</button>
          <button style={s.primaryBtn} onClick={onClaimLoot}>Claim and Continue</button>
        </div>
      </div>

      <section style={s.summary}>
        <article style={s.statCard}>
          <span style={s.statLabel}>Mission gold</span>
          <strong>{loot?.gold ?? 0}</strong>
        </article>
        <article style={s.statCard}>
          <span style={s.statLabel}>Equipment drops</span>
          <strong>{items.length}</strong>
        </article>
      </section>

      {items.length === 0 && (
        <section style={s.empty}>
          <h3>No equipment dropped</h3>
          <p style={s.copy}>Mission rewards were still collected. The next route node is ready.</p>
        </section>
      )}

      <section style={s.grid}>
        {items.map((item) => {
          const rarity = getRarityDef(item.rarity)
          return (
            <article key={item.id} style={{ ...s.card, borderColor: rarity.border }}>
              <div style={s.cardTop}>
                <span style={s.icon}>{item.icon ?? '*'}</span>
                <span style={{ ...s.rarity, color: rarity.color }}>{rarity.label}</span>
              </div>
              <h3 style={s.cardTitle}>{item.name}</h3>
              <p style={s.copy}>{item.slot}</p>
              <ul style={s.affixes}>
                {item.affixes.map((affix) => <li key={`${item.id}-${affix.id}`}>{affix.label}</li>)}
              </ul>
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
  copy: { margin: 0, color: 'rgba(247,240,223,.68)', fontSize: 14, lineHeight: 1.6, textTransform: 'capitalize' },
  actions: { display: 'flex', gap: 8, flexWrap: 'wrap' },
  primaryBtn: { padding: '10px 16px', borderRadius: 10, border: '1px solid rgba(201,167,86,.58)', background: 'rgba(201,167,86,.2)', color: '#f7f0df', fontWeight: 900, cursor: 'pointer', fontFamily: 'inherit' },
  secondaryBtn: { padding: '10px 14px', borderRadius: 10, border: '1px solid rgba(255,255,255,.14)', background: 'rgba(255,255,255,.06)', color: '#f7f0df', fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit' },
  summary: { display: 'grid', gridTemplateColumns: 'repeat(2,minmax(0,1fr))', gap: 10, marginBottom: 16 },
  statCard: { border: '1px solid rgba(255,255,255,.1)', background: 'rgba(255,255,255,.045)', borderRadius: 12, padding: 12 },
  statLabel: { display: 'block', color: 'rgba(247,240,223,.48)', fontSize: 11, textTransform: 'uppercase', letterSpacing: '.08em', marginBottom: 4 },
  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(220px,1fr))', gap: 14 },
  card: { border: '1px solid rgba(255,255,255,.14)', background: 'rgba(255,255,255,.045)', borderRadius: 16, padding: 16 },
  cardTop: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  icon: { fontSize: 30 },
  rarity: { fontSize: 11, fontWeight: 900, textTransform: 'uppercase', letterSpacing: '.12em' },
  cardTitle: { margin: '10px 0 4px', fontSize: 19 },
  affixes: { margin: '10px 0 0', paddingLeft: 18, color: 'rgba(247,240,223,.74)', fontSize: 13, lineHeight: 1.7 },
  empty: { border: '1px solid rgba(255,255,255,.1)', borderRadius: 14, padding: 16, background: 'rgba(255,255,255,.04)', marginBottom: 14 },
}
