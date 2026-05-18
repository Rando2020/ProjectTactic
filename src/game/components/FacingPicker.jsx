const FACINGS = [
  { id: 'N', label: 'North', arrow: '^' },
  { id: 'E', label: 'East', arrow: '>' },
  { id: 'S', label: 'South', arrow: 'v' },
  { id: 'W', label: 'West', arrow: '<' }
]

export default function FacingPicker({ unit, onChoose }) {
  if (!unit) return null

  return (
    <section style={s.panel}>
      <p style={s.eyebrow}>End Turn</p>
      <h3 style={s.heading}>Choose Facing</h3>
      <p style={s.meta}>{unit.name} will guard from this direction.</p>
      <div style={s.grid}>
        {FACINGS.map((facing) => (
          <button
            key={facing.id}
            style={{ ...s.button, ...(unit.facing === facing.id ? s.active : {}) }}
            onClick={() => onChoose?.(facing.id)}
            aria-label={`Face ${facing.label}`}
          >
            <strong style={s.arrow}>{facing.arrow}</strong>
            <span style={s.label}>{facing.label}</span>
          </button>
        ))}
      </div>
      <p style={s.keys}>Arrow keys also choose facing.</p>
    </section>
  )
}

const s = {
  panel: { padding: 16, borderRadius: 18, background: 'rgba(5,7,20,.84)', border: '1px solid rgba(255,255,255,.12)', color: '#f8f5ff' },
  eyebrow: { margin: 0, color: '#c9a756', fontSize: 11, fontWeight: 900, letterSpacing: '.16em', textTransform: 'uppercase' },
  heading: { margin: '6px 0 2px', fontSize: 16 },
  meta: { margin: '0 0 10px', color: 'rgba(248,245,255,.62)', fontSize: 12, lineHeight: 1.4 },
  grid: { display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 8 },
  button: { display: 'grid', gap: 2, justifyItems: 'center', padding: '10px 8px', borderRadius: 12, border: '1px solid rgba(255,255,255,.15)', background: 'rgba(255,255,255,.07)', color: '#f8f5ff', cursor: 'pointer', fontFamily: 'inherit' },
  active: { borderColor: 'rgba(250,204,21,.85)', background: 'rgba(250,204,21,.14)' },
  arrow: { fontSize: 18, lineHeight: 1 },
  label: { color: 'rgba(248,245,255,.7)', fontSize: 11, fontWeight: 800 },
  keys: { margin: '10px 0 0', color: 'rgba(248,245,255,.42)', fontSize: 11 }
}
