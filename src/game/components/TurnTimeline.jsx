export default function TurnTimeline({ units = [] }) {
  const ordered = [...units]
    .filter((unit) => unit.hp > 0)
    .sort((a, b) => (b.ct ?? 0) - (a.ct ?? 0) || (b.stats?.speed ?? 0) - (a.stats?.speed ?? 0))
    .slice(0, 8)

  return (
    <aside style={styles.panel}>
      <p style={styles.eyebrow}>Timeline</p>
      <div style={styles.list}>
        {ordered.map((unit) => (
          <div key={unit.id} style={styles.row}>
            <span style={{ ...styles.dot, background: unit.team === 'player' ? '#7bdcff' : '#ff6b6b' }} />
            <span style={styles.name}>{unit.name}</span>
            <span style={styles.ct}>{Math.round(unit.ct ?? 0)}</span>
          </div>
        ))}
      </div>
    </aside>
  )
}

const styles = {
  panel: {
    padding: 16,
    borderRadius: 18,
    background: 'rgba(5, 7, 20, 0.84)',
    border: '1px solid rgba(255,255,255,0.12)',
    color: '#f8f5ff',
    minWidth: 220
  },
  eyebrow: {
    margin: '0 0 12px',
    color: '#b8b3ff',
    fontSize: 11,
    fontWeight: 900,
    letterSpacing: '0.16em',
    textTransform: 'uppercase'
  },
  list: { display: 'grid', gap: 8 },
  row: { display: 'grid', gridTemplateColumns: '12px 1fr auto', alignItems: 'center', gap: 8 },
  dot: { width: 10, height: 10, borderRadius: 999 },
  name: { fontWeight: 800, fontSize: 13 },
  ct: { color: 'rgba(248,245,255,0.66)', fontVariantNumeric: 'tabular-nums' }
}
