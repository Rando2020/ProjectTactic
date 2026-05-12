export default function DamageForecast({ preview, attacker, target, ability }) {
  if (!preview || !attacker || !ability) {
    return (
      <section style={styles.panel}>
        <p style={styles.muted}>Choose an action and target to preview the outcome.</p>
      </section>
    )
  }

  return (
    <section style={styles.panel}>
      <p style={styles.eyebrow}>Forecast</p>
      <h3 style={styles.title}>{attacker.name} uses {ability.name}</h3>
      {target && <p style={styles.target}>Target: {target.name}</p>}
      <div style={styles.metricGrid}>
        <Metric label={preview.type === 'heal' ? 'Heal' : 'Damage'} value={preview.amount} />
        <Metric label="Hit" value={`${Math.round((preview.hitChance || 0) * 100)}%`} />
        <Metric label="Crit" value={`${Math.round((preview.critChance || 0) * 100)}%`} />
        <Metric label="Angle" value={preview.facing || 'front'} />
      </div>
      {preview.armorType && <p style={styles.note}>{preview.armorDamage} {preview.armorType} pressure expected.</p>}
    </section>
  )
}

function Metric({ label, value }) {
  return (
    <div style={styles.metric}>
      <span style={styles.metricLabel}>{label}</span>
      <strong style={styles.metricValue}>{value}</strong>
    </div>
  )
}

const styles = {
  panel: { padding: 16, borderRadius: 18, background: 'rgba(5, 7, 20, 0.84)', border: '1px solid rgba(255,255,255,0.12)', color: '#f8f5ff' },
  eyebrow: { margin: 0, color: '#b8b3ff', fontSize: 11, fontWeight: 900, letterSpacing: '0.16em', textTransform: 'uppercase' },
  title: { margin: '8px 0', fontSize: 18 },
  target: { margin: '0 0 12px', color: 'rgba(248,245,255,0.74)' },
  muted: { color: 'rgba(248,245,255,0.66)' },
  metricGrid: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 },
  metric: { padding: 10, borderRadius: 12, background: 'rgba(255,255,255,0.07)' },
  metricLabel: { display: 'block', color: 'rgba(248,245,255,0.62)', fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.08em' },
  metricValue: { display: 'block', marginTop: 4, fontSize: 18 },
  note: { margin: '12px 0 0', color: '#ffd86b', fontWeight: 800 }
}
